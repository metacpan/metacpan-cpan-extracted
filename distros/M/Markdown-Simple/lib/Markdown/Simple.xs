#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* ------------------------------------------------------------------ */
/* Unity build: the parser sources live in src/ and are pulled in below
 * so the per-xs Makefile doesn't need extra OBJECT entries. Order
 * matters: headers first, then .c bodies. All symbols here are static
 * to the compilation unit except mds_render_html_to_sv, which the XS
 * glue at the bottom of this file calls.
 */
#define MDS_UNITY_BUILD 1
#include "../../src/mds_arena.c"
#include "../../src/mds_buf.c"
#include "../../src/mds_linkref.c"
#include "../../src/mds_footnote.c"
#include "../../src/mds_block.c"
#include "../../src/mds_inline.c"
#include "../../src/mds_render_html.c"
#include "../../src/mds_gfm.c"
#include "../../src/mds.c"

/* SIMD foundation: always build the scalar + dispatch units. The
 * AVX2/SSE2/NEON files compile only when their feature macro is set. */
#include "../../src/simd/mds_simd_scalar.c"
#ifdef MDS_HAVE_SSE2
#  include "../../src/simd/mds_simd_sse2.c"
#endif
#ifdef MDS_HAVE_AVX2
#  include "../../src/simd/mds_simd_avx2.c"
#endif
#ifdef MDS_HAVE_NEON
#  include "../../src/simd/mds_simd_neon.c"
#endif
#include "../../src/simd/mds_simd_dispatch.c"
#include "../../src/simd/mds_dispatch.c"
/* ------------------------------------------------------------------ */

/* Special-byte table used by strip_markdown_except_lists_tables to skip
 * over runs of ordinary text quickly. Bytes here are the ones that can
 * START a markdown construct in that pass. */
static unsigned char mds_special[256];
static int mds_special_init = 0;
static void mds_build_special(void) {
	if (mds_special_init) return;
	mds_special[(unsigned char)'#']  = 1;
	mds_special[(unsigned char)'`']  = 1;
	mds_special[(unsigned char)'*']  = 1;
	mds_special[(unsigned char)'_']  = 1;
	mds_special[(unsigned char)'~']  = 1;
	mds_special[(unsigned char)'[']  = 1;
	mds_special[(unsigned char)'!']  = 1;
	mds_special[(unsigned char)'|']  = 1;
	mds_special[(unsigned char)'\n'] = 1;
	mds_special[(unsigned char)'\r'] = 1;
	mds_special_init = 1;
}

static SV* strip_markdown_except_lists_tables(const char* input) {
	SV* out = newSVpv("", 0);
	const char* p = input;

	mds_build_special();

	while (*p) {
		// Unordered lists: keep marker, remove space
		if ((p == input || *(p-1) == '\n') && (*p == '-' || *p == '*' || *p == '+') && *(p+1) == ' ') {
			sv_catpvn(out, p, 1);
			sv_catpvn(out, " ", 1); // Keep space after marker
			p += 2;
			// Task list [ ] or [x] immediately after bullet — strip the box.
			if (*p == '[' && (*(p+1) == ' ' || *(p+1) == 'x' || *(p+1) == 'X') && *(p+2) == ']') {
				p += 3;
				if (*p == ' ') p++;
			}
			continue;
		}
		// Tables: just copy everything (including pipes and dashes)
		if (*p == '|') {
			sv_catpvn(out, p, 1);
			p++;
			continue;
		}
		// Table separator row (---): just copy dashes and pipes
		if (*p == '-' && ((p > input && *(p-1) == '|') || (p == input))) {
			sv_catpvn(out, p, 1);
			p++;
			continue;
		}
		// Remove bold (** or __)
		if ((*p == '*' && *(p+1) == '*') || (*p == '_' && *(p+1) == '_')) {
			p += 2;
			continue;
		}
		// Remove italic (* or _)
		if (*p == '*' || *p == '_') {
			p++;
			continue;
		}
		// Remove strikethrough (~~)
		if (*p == '~' && *(p+1) == '~') {
			p += 2;
			continue;
		}
		// Remove inline code (`) and fenced code (```) — keep content, drop fences
		if (*p == '`') {
			if (*(p+1) == '`' && *(p+2) == '`') {
				// Fenced block: drop the opening fence line entirely
				// (but preserve one newline so surrounding text stays
				// on its own line).
				const char* fence;
				const char* body_end;
				p += 3;
				while (*p && *p != '\n') p++;
				// keep the '\n' that terminated the fence line in output
				if (*p == '\n') { sv_catpvn(out, "\n", 1); p++; }
				fence = strstr(p, "```");
				body_end = fence ? fence : p + strlen(p);
				if (body_end > p)
					sv_catpvn(out, p, (STRLEN)(body_end - p));
				if (fence) {
					p = fence + 3;
					// drop the rest of the closing fence line
					while (*p && *p != '\n') p++;
				} else {
					p = body_end;
				}
			} else {
				const char* code_start;
				p++;
				code_start = p;
				while (*p && *p != '`') p++;
				if (p > code_start)
					sv_catpvn(out, code_start, (STRLEN)(p - code_start));
				if (*p == '`') p++;
			}
			continue;
		}
		// Remove images ![alt](url)
		if (*p == '!' && *(p+1) == '[') {
			p += 2;
			while (*p && *p != ']') p++;
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				while (*p && *p != ')') p++;
				if (*p == ')') p++;
			}
			continue;
		}
		// Remove links [text](url), keep text
		if (*p == '[') {
			const char* text_start;
			int text_len;
			p++;
			text_start = p;
			while (*p && *p != ']') p++;
			text_len = (int)(p - text_start);
			if (text_len > 0)
				sv_catpvn(out, text_start, text_len);
			if (*p == ']') p++;
			if (*p == '(') {
				p++;
				while (*p && *p != ')') p++;
				if (*p == ')') p++;
			}
			continue;
		}
		// Remove headers (#)
		if (*p == '#') {
			while (*p == '#') p++;
			if (*p == ' ') p++;
			continue;
		}
		// Remove task list [ ] or [x]
		if (*p == '[' && (*(p+1) == ' ' || *(p+1) == 'x' || *(p+1) == 'X') && *(p+2) == ']') {
			p += 3;
			if (*p == ' ') p++;
			continue;
		}
		// Default: emit a single special byte, OR batch a run of non-special.
		/* Special set for strip is the markdown special set PLUS '|', '-', '+',
		 * and ASCII digits (all line-start-conditional in this function). */
		if (mds_special[(unsigned char)*p]
		    || *p == '|' || *p == '-' || *p == '+'
		    || (*p >= '1' && *p <= '9')) {
			sv_catpvn(out, p, 1);
			p++;
		} else {
			const char* run = p;
			do { p++; } while (*p && !mds_special[(unsigned char)*p]
			                       && *p != '|' && *p != '-' && *p != '+'
			                       && !(*p >= '1' && *p <= '9'));
			sv_catpvn(out, run, (STRLEN)(p - run));
		}
	}
	return out;
}

/* Shared options-hash decoder used by both the procedural
 * markdown_to_html entry point and the persistent session render path.
 * GFM is the default; an `hv` of NULL returns the GFM preset unchanged. */
static unsigned mds_flags_from_hv(pTHX_ HV* h) {
	unsigned flags = MDS_FLAGS_GFM;
	SV** v;
	if (!h) return flags;
	if ((v = hv_fetch(h, "gfm", 3, 0)) && !SvTRUE(*v)) flags = MDS_FLAGS_COMMONMARK;
	if ((v = hv_fetch(h, "tables", 6, 0)))            flags = SvTRUE(*v) ? (flags | MDS_FLAG_TABLES)            : (flags & ~MDS_FLAG_TABLES);
	if ((v = hv_fetch(h, "strikethrough", 13, 0)))     flags = SvTRUE(*v) ? (flags | MDS_FLAG_STRIKE)            : (flags & ~MDS_FLAG_STRIKE);
	if ((v = hv_fetch(h, "tasklist", 8, 0)))           flags = SvTRUE(*v) ? (flags | MDS_FLAG_TASKLIST)          : (flags & ~MDS_FLAG_TASKLIST);
	if ((v = hv_fetch(h, "autolink", 8, 0)))           flags = SvTRUE(*v) ? (flags | MDS_FLAG_AUTOLINK)          : (flags & ~MDS_FLAG_AUTOLINK);
	if ((v = hv_fetch(h, "disallow_raw_html", 17, 0))) flags = SvTRUE(*v) ? (flags | MDS_FLAG_DISALLOW_RAW_HTML) : (flags & ~MDS_FLAG_DISALLOW_RAW_HTML);
	if ((v = hv_fetch(h, "hard_breaks", 11, 0)) && SvTRUE(*v))     flags |= MDS_FLAG_HARD_BREAKS;
	if ((v = hv_fetch(h, "unsafe", 6, 0))      && SvTRUE(*v))      flags |= MDS_FLAG_UNSAFE;
	if ((v = hv_fetch(h, "no_simd", 7, 0))     && SvTRUE(*v))      flags |= MDS_FLAG_NO_SIMD;
	if ((v = hv_fetch(h, "strict_utf8", 11, 0)) && SvTRUE(*v))     flags |= MDS_FLAG_STRICT_UTF8;
	if ((v = hv_fetch(h, "headers",         7,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_HEADINGS;
	if ((v = hv_fetch(h, "italic",          6,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_EMPH;
	if ((v = hv_fetch(h, "bold",            4,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_STRONG;
	if ((v = hv_fetch(h, "code",            4,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_CODE;
	if ((v = hv_fetch(h, "links",           5,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_LINKS;
	if ((v = hv_fetch(h, "images",          6,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_IMAGES;
	if ((v = hv_fetch(h, "ordered_lists",   13, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_ORDERED_LISTS;
	if ((v = hv_fetch(h, "unordered_lists", 15, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_UNORDERED_LISTS;
	if ((v = hv_fetch(h, "blockquote",      10, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_QUOTES;
	if ((v = hv_fetch(h, "thematic_break",  14, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_THEMATIC_BREAK;
	if ((v = hv_fetch(h, "fenced_code",     11, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_FENCED_CODE;
	if ((v = hv_fetch(h, "indented_code",   13, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_INDENTED_CODE;
	if ((v = hv_fetch(h, "html",            4,  0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_HTML;
	if ((v = hv_fetch(h, "references",      10, 0)) && !SvTRUE(*v)) flags |= MDS_FLAG_NO_REFERENCES;
	return flags;
}

/* Persistent session struct. The arena's head page is kept warm between
 * render() calls by mds_arena_reset, eliminating the per-parse malloc
 * for sub-page workloads, and the block-scanner scratch buffers are
 * persisted alongside so realloc traffic is amortised. */
typedef struct mds_session {
	mds_arena         arena;
	mds_block_scratch scratch;
	unsigned          flags;
} mds_session;

/* Magic glue: a Markdown::Simple object is a blessed SVRV whose IV slot
 * holds an mds_session* pointer. The pointer is owned by an
 * ext-magic record attached to that IV, so the session is released
 * automatically when the SV is destroyed (covering scope exit, undef,
 * and global destruction without a Perl-level DESTROY method).
 */
static int mds_session_mg_free(pTHX_ SV* sv, MAGIC* mg) {
	mds_session* s;
	PERL_UNUSED_ARG(sv);
	s = (mds_session*)mg->mg_ptr;
	if (s) {
		mds_arena_free(&s->arena);
		mds_block_scratch_free(&s->scratch);
		free(s);
		mg->mg_ptr = NULL;
	}
	return 0;
}

static MGVTBL mds_session_mg_vtbl = {
	NULL,                  /* get   */
	NULL,                  /* set   */
	NULL,                  /* len   */
	NULL,                  /* clear */
	mds_session_mg_free,   /* free  */
	NULL,                  /* copy  */
	NULL,                  /* dup   */
	NULL                   /* local */
};

/* Look up the session pointer from a blessed SVRV ($self). Croaks on
 * mismatch so misuse fails loudly rather than dereferencing garbage. */
static mds_session* mds_session_from_self(pTHX_ SV* self, const char* who) {
	SV* iv;
	MAGIC* mg;
	if (!self || !SvROK(self))
		croak("%s: invalid invocant (expected a Markdown::Simple object)", who);
	iv = SvRV(self);
	for (mg = SvMAGIC(iv); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &mds_session_mg_vtbl)
			return (mds_session*)mg->mg_ptr;
	}
	croak("%s: invocant has no Markdown::Simple session attached", who);
	return NULL; /* not reached */
}

MODULE = Markdown::Simple    PACKAGE = Markdown::Simple

SV*
strip_markdown(input)
	const char* input
CODE:
	RETVAL = strip_markdown_except_lists_tables(input);
OUTPUT:
	RETVAL

SV*
markdown_to_html(input, ...)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s = SvPV(input, n);
	SV* out = newSVpv("", 0);
	HV* h = (items > 1 && SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV)
		? (HV*)SvRV(ST(1)) : NULL;
	unsigned flags = mds_flags_from_hv(aTHX_ h);
	mds_render_html_to_sv(aTHX_ s, n, flags, out);
	if (SvCUR(out) == 0 && (flags & MDS_FLAG_STRICT_UTF8) && n) {
		/* Distinguish "empty input" from "rejected as malformed UTF-8". */
		const mds_simd_ops* ops = (flags & MDS_FLAG_NO_SIMD)
			? mds_simd_ops_scalar() : mds_simd_get();
		if (!ops->validate_utf8(s, n))
			croak("markdown_to_html: input is not valid UTF-8");
	}
	RETVAL = out;
	if (SvUTF8(input)) SvUTF8_on(RETVAL);
}
OUTPUT:
	RETVAL

# ---- Persistent session (reusable arena) -------------------------------
# Markdown::Simple->new(\%opts) -> blessed object owning a warm parser
# $self->render($markdown)       -> SV with rendered HTML
# $self->flags                   -> integer flag mask (read-only)
#
# The session is released by SV magic when the object goes out of scope;
# no explicit DESTROY method is required.

SV*
new(class, opts = NULL)
	SV* class;
	SV* opts;
PREINIT:
	HV* h = NULL;
	HV* stash;
	mds_session* s;
	SV* iv;
	SV* rv;
	const char* klass;
CODE:
{
	if (opts && SvOK(opts)) {
		if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV)
			croak("Markdown::Simple::new: options must be a HASH reference");
		h = (HV*)SvRV(opts);
	}
	if (!SvOK(class))
		croak("Markdown::Simple::new: missing class name");
	klass = SvROK(class) ? sv_reftype(SvRV(class), 1) : SvPV_nolen(class);
	stash = gv_stashpv(klass, GV_ADD);

	s = (mds_session*)malloc(sizeof(mds_session));
	if (!s) croak("Markdown::Simple::new: out of memory");
	mds_arena_init(&s->arena);
	memset(&s->scratch, 0, sizeof s->scratch);
	s->flags = mds_flags_from_hv(aTHX_ h);

	iv = newSViv(0);
	sv_magicext(iv, NULL, PERL_MAGIC_ext, &mds_session_mg_vtbl, (const char*)s, 0);
	rv = newRV_noinc(iv);
	sv_bless(rv, stash);
	RETVAL = rv;
}
OUTPUT:
	RETVAL

SV*
render(self, input)
	SV* self;
	SV* input;
PREINIT:
	mds_session* s;
	STRLEN n;
	const char* in;
	SV* out;
CODE:
{
	s = mds_session_from_self(aTHX_ self, "Markdown::Simple::render");
	in = SvOK(input) ? SvPV(input, n) : (n = 0, "");
	out = newSVpv("", 0);
	mds_render_html_to_sv_ex(aTHX_ in, n, s->flags, out, &s->arena, &s->scratch);
	if (SvCUR(out) == 0 && (s->flags & MDS_FLAG_STRICT_UTF8) && n) {
		const mds_simd_ops* ops = (s->flags & MDS_FLAG_NO_SIMD)
			? mds_simd_ops_scalar() : mds_simd_get();
		if (!ops->validate_utf8(in, n))
			croak("render: input is not valid UTF-8");
	}
	RETVAL = out;
	if (SvUTF8(input)) SvUTF8_on(RETVAL);
}
OUTPUT:
	RETVAL

UV
flags(self)
	SV* self;
CODE:
{
	mds_session* s = mds_session_from_self(aTHX_ self, "Markdown::Simple::flags");
	RETVAL = (UV)s->flags;
}
OUTPUT:
	RETVAL

# ---- SIMD backend introspection ----------------------------------------

SV*
_simd_backend()
CODE:
{
	RETVAL = newSVpv(mds_simd_backend(), 0);
}
OUTPUT:
	RETVAL

void
_simd_force_scalar(on)
	int on;
CODE:
{
	mds_simd_force_scalar(on);
}

# ---- Classifier introspection (test-only) ------------------------------
# _classify_structural($bytes)        -- runs the *active* backend
# _classify_structural_scalar($bytes) -- runs the scalar reference
# Both return a byte string of ceil(len/8) bytes; bit i (LSB-first within
# each byte) is set iff input byte i is structural.

SV*
_classify_structural(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	size_t words;
	uint64_t* bm;
	size_t out_bytes;
	s = SvPV(input, n);
	words = (n + 63) >> 6;
	if (!words) words = 1;
	bm = (uint64_t*)calloc(words, sizeof(uint64_t));
	if (!bm) croak("oom");
	mds_simd_get()->classify_structural(s, n, bm);
	out_bytes = (n + 7) >> 3;
	RETVAL = newSVpvn((const char*)bm, out_bytes);
	free(bm);
}
OUTPUT:
	RETVAL

SV*
_classify_structural_scalar(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	size_t words;
	uint64_t* bm;
	size_t out_bytes;
	s = SvPV(input, n);
	words = (n + 63) >> 6;
	if (!words) words = 1;
	bm = (uint64_t*)calloc(words, sizeof(uint64_t));
	if (!bm) croak("oom");
	mds_simd_ops_scalar()->classify_structural(s, n, bm);
	out_bytes = (n + 7) >> 3;
	RETVAL = newSVpvn((const char*)bm, out_bytes);
	free(bm);
}
OUTPUT:
	RETVAL

# ---- UTF-8 validator + line scanner (test-only) ------------------------

int
_validate_utf8(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	s = SvPV(input, n);
	RETVAL = mds_simd_get()->validate_utf8(s, n);
}
OUTPUT:
	RETVAL

int
_validate_utf8_scalar(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	s = SvPV(input, n);
	RETVAL = mds_simd_ops_scalar()->validate_utf8(s, n);
}
OUTPUT:
	RETVAL

# Both _find_newlines variants return:
#   - undef when the offset table overflows the provided cap, or
#   - a packed string of native-endian uint32_t values (one per '\n').
SV*
_find_newlines(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	size_t cap;
	uint32_t* offs;
	size_t k;
	s = SvPV(input, n);
	cap = n ? n : 1;
	offs = (uint32_t*)malloc(cap * sizeof(uint32_t));
	if (!offs) croak("oom");
	k = mds_simd_get()->find_newlines(s, n, offs, cap);
	if (k == (size_t)-1) { free(offs); XSRETURN_UNDEF; }
	RETVAL = newSVpvn((const char*)offs, k * sizeof(uint32_t));
	free(offs);
}
OUTPUT:
	RETVAL

SV*
_find_newlines_scalar(input)
	SV* input;
CODE:
{
	STRLEN n;
	const char* s;
	size_t cap;
	uint32_t* offs;
	size_t k;
	s = SvPV(input, n);
	cap = n ? n : 1;
	offs = (uint32_t*)malloc(cap * sizeof(uint32_t));
	if (!offs) croak("oom");
	k = mds_simd_ops_scalar()->find_newlines(s, n, offs, cap);
	if (k == (size_t)-1) { free(offs); XSRETURN_UNDEF; }
	RETVAL = newSVpvn((const char*)offs, k * sizeof(uint32_t));
	free(offs);
}
OUTPUT:
	RETVAL

# Bounded-cap variant for testing the overflow sentinel path.
SV*
_find_newlines_capped(input, cap)
	SV* input;
	int cap;
CODE:
{
	STRLEN n; const char* s = SvPV(input, n);
	size_t cc = cap < 0 ? 0 : (size_t)cap;
	uint32_t* offs = cc ? (uint32_t*)malloc(cc * sizeof(uint32_t)) : NULL;
	size_t k = mds_simd_get()->find_newlines(s, n, offs, cc);
	if (k == (size_t)-1) { free(offs); XSRETURN_UNDEF; }
	RETVAL = newSVpvn(offs ? (const char*)offs : "", k * sizeof(uint32_t));
	free(offs);
}
OUTPUT:
	RETVAL

# ---- Arena profile from the last parse ---------------------------------
# Returns a hashref describing arena usage from the most recent call to
# mds_render_html_to_sv. Intended for bench/profile_arena.pl; not
# thread-safe (the underlying snapshot is a single static).

SV*
_last_arena_profile()
CODE:
{
	HV* h = newHV();
	hv_stores(h, "total_alloc",    newSVuv((UV)mds_last_arena_profile.total_alloc));
	hv_stores(h, "page_count",     newSVuv((UV)mds_last_arena_profile.page_count));
	hv_stores(h, "big_count",      newSVuv((UV)mds_last_arena_profile.big_count));
	hv_stores(h, "big_bytes",      newSVuv((UV)mds_last_arena_profile.big_bytes));
	hv_stores(h, "head_used_last", newSVuv((UV)mds_last_arena_profile.head_used_last));
	hv_stores(h, "head_cap_last",  newSVuv((UV)mds_last_arena_profile.head_cap_last));
	hv_stores(h, "page_size",      newSVuv((UV)MDS_ARENA_PAGE));
	hv_stores(h, "big_threshold",  newSVuv((UV)MDS_ARENA_BIG));
	RETVAL = newRV_noinc((SV*)h);
}
OUTPUT:
	RETVAL

# ---- Arena + buffer self-tests -----------------------------------------

SV*
_arena_test()
CODE:
{
	/* Exercise alignment, page chaining, and the big-alloc path. */
	mds_arena a;
	int aligned_ok = 1;
	int chained_ok;
	void* big;
	int big_ok;
	int reset_ok;
	HV* h_a;
	int i_a;
	size_t si_a;
	mds_arena_init(&a);

	/* 1. Alignment: every returned pointer is MDS_ARENA_ALIGN-aligned. */
	for (i_a = 0; i_a < 64; i_a++) {
		{ void* p = mds_arena_alloc(&a, 1 + (i_a * 7));
		if (((uintptr_t)p) & (MDS_ARENA_ALIGN - 1)) { aligned_ok = 0; break; } }
	}

	/* 2. Page chaining: allocate enough to force a second page. */
	for (si_a = 0; si_a < 200; si_a++) mds_arena_alloc(&a, 1024);
	chained_ok = (a.head && a.head->next != NULL);

	/* 3. Big-alloc: > MDS_ARENA_BIG goes to dedicated page. */
	big = mds_arena_alloc(&a, MDS_ARENA_BIG * 2);
	big_ok = (big != NULL && a.big != NULL);

	/* 4. Reset: walks back to single warm page, no big pages. */
	mds_arena_reset(&a);
	reset_ok = (a.head && a.head->next == NULL && a.big == NULL);

	mds_arena_free(&a);

	h_a = newHV();
	hv_stores(h_a, "aligned",  newSViv(aligned_ok));
	hv_stores(h_a, "chained",  newSViv(chained_ok));
	hv_stores(h_a, "big",      newSViv(big_ok));
	hv_stores(h_a, "reset",    newSViv(reset_ok));
	RETVAL = newRV_noinc((SV*)h_a);
}
OUTPUT:
	RETVAL

SV*
_buf_test()
CODE:
{
	/* Exercise mds_buf: grows, preserves contents, finalises SvCUR. */
	SV* out;
	mds_buf b;
	int i_b;
	int len_ok;
	const char* p_b;
	int data_ok;
	HV* h_b;
	out = newSVpv("", 0);
	mds_buf_init(aTHX_ &b, out, 8);   /* tiny hint to force growth */
	for (i_b = 0; i_b < 1000; i_b++) mds_buf_write(aTHX_ &b, "abcdef", 6);
	mds_buf_finalize(aTHX_ &b);

	len_ok = (SvCUR(out) == 6000);
	p_b = SvPVX(out);
	data_ok = (memcmp(p_b, "abcdef", 6) == 0 &&
	               memcmp(p_b + 5994, "abcdef", 6) == 0);

	h_b = newHV();
	hv_stores(h_b, "len",  newSViv(len_ok));
	hv_stores(h_b, "data", newSViv(data_ok));
	SvREFCNT_dec(out);
	RETVAL = newRV_noinc((SV*)h_b);
}
OUTPUT:
	RETVAL

