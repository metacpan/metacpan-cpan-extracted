#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <jq.h>
#include <jv.h>

/* Built against the jq vendored in this distribution rather than the one the
 * OS packages (the default; "perl Makefile.PL JQ_SYSTEM=1" picks the other).
 * jq's public headers carry no version, so the build stages a copy of the
 * version.h of the jq it actually compiled. */
#ifdef JQ_XS_EMBEDDED
#  include <jq_version.h>
#endif

/* Error callback context to capture compilation errors */
typedef struct {
  SV *buffer;
} ErrorContext;

/* The C struct wrapped as the JQ::XS object via T_PTROBJ.
 *
 * Everything a caller can configure lives here rather than in a Perl hash,
 * because the object is a blessed pointer, not a hashref.  output_opts is the
 * option hash process_json() formats with, kept alongside the jv_dump_string
 * flags it compiles down to so that a per-call override can be merged over it
 * without recomputing anything the caller did not ask to change. */
typedef struct {
  jq_state *state;
  SV       *program;

  /* Output formatting for process_json() */
  SV       *output_opts;       /* hashref: what set_output() was given */
  int       dump_flags;        /* JV_PRINT_* flags compiled from output_opts */
  int       raw_output;        /* emit strings unquoted, like jq -r */

  int       start_flags;       /* jq_start() flags: JQ_DEBUG_TRACE and friends */
  int       die_on_halt_error; /* croak when halt_error left a message */

  /* Perl code refs behind the debug, stderr and input/inputs builtins */
  SV       *debug_cb;
  SV       *stderr_cb;
  SV       *input_cb;

  /* Set by the last run: what halt/halt_error left behind */
  int       halted;
  SV       *exit_code;
  SV       *error_message;

  /* An exception thrown by the debug or stderr callback.  It cannot be
   * croaked from inside libjq -- that would longjmp out through jq's own C
   * frames, abandoning the jq_state mid-run -- so it is parked here and
   * rethrown once jq_next() has stopped producing. */
  SV       *cb_error;

  /* libjq's state machine is not reentrant, so a callback that reenters
   * process() on the same object has to be turned away. */
  int       running;
} jq_xs_t;
typedef jq_xs_t *JQ__XS;   /* XS type "JQ::XS" -> C type "JQ__XS", blessed class "JQ::XS" */

/* Forward declaration of conversion functions - need pTHX for Perl context */
static SV *jv_to_sv(pTHX_ jv);
static jv sv_to_jv(pTHX_ SV *);

/* Error callback for jq_set_error_cb */
static void error_callback(void *user_data, jv msg) {
  dTHX;
  ErrorContext *ctx = (ErrorContext *)user_data;
  if (ctx && ctx->buffer && jv_is_valid(msg)) {
    jv err_text = jq_format_error(msg);
    if (jv_is_valid(err_text)) {
      const char *text = jv_string_value(err_text);
      if (text) {
        sv_catpv(ctx->buffer, text);
        sv_catpv(ctx->buffer, "\n");
      }
      jv_free(err_text);
    }
  } else {
    jv_free(msg);
  }
}

/* Convert jv to SV - handles all jv types */
static SV *jv_to_sv(pTHX_ jv v) {
  jv_kind kind = jv_get_kind(v);
  SV *result = NULL;

  switch (kind) {
    case JV_KIND_NULL:
      result = newSV(0);
      break;

    case JV_KIND_FALSE:
      result = newSV(0);
      sv_setref_iv(result, "JSON::PP::Boolean", 0);
      break;

    case JV_KIND_TRUE:
      result = newSV(0);
      sv_setref_iv(result, "JSON::PP::Boolean", 1);
      break;

    case JV_KIND_NUMBER:
      if (jv_is_integer(v)) {
        double d = jv_number_value(v);
        if (d >= IV_MIN && d <= IV_MAX) {
          result = newSViv((IV)d);
        } else {
          result = newSVnv(d);
        }
      } else {
        result = newSVnv(jv_number_value(v));
      }
      break;

    case JV_KIND_STRING: {
      jv copy = jv_copy(v);
      int len = jv_string_length_bytes(copy);
      const char *str = jv_string_value(v);
      result = newSVpvn(str, len);
      SvUTF8_on(result);
      break;
    }

    case JV_KIND_ARRAY: {
      AV *av = newAV();
      jv_array_foreach(v, i, item) {
        SV *item_sv = jv_to_sv(aTHX_ item);
        av_push(av, item_sv);
      }
      result = newRV_noinc((SV *)av);
      break;
    }

    case JV_KIND_OBJECT: {
      HV *hv = newHV();
      jv_object_foreach(v, key, val) {
        SV *key_sv = jv_to_sv(aTHX_ key);
        SV *val_sv = jv_to_sv(aTHX_ val);
        hv_store_ent(hv, key_sv, val_sv, 0);
        SvREFCNT_dec(key_sv);
      }
      result = newRV_noinc((SV *)hv);
      break;
    }

    case JV_KIND_INVALID:
    default:
      result = newSV(0);
      break;
  }

  jv_free(v);
  return result;
}

/* Convert SV to jv - handles all Perl types */
static jv sv_to_jv(pTHX_ SV *sv) {
  /* Perl's native boolean SVs: the immortals returned by comparison and
   * logical operators. On perl < 5.36 a copy of one is indistinguishable
   * from an ordinary dualvar, so only identity can be checked. */
  if (sv == &PL_sv_yes) return jv_true();
  if (sv == &PL_sv_no)  return jv_false();
#ifdef SvIsBOOL
  /* perl >= 5.36: copies keep their boolean flag (builtin::true/false) */
  if (SvIsBOOL(sv)) return SvTRUE(sv) ? jv_true() : jv_false();
#endif

  if (!SvOK(sv)) {
    return jv_null();
  }

  if (SvROK(sv)) {
    SV *ref = SvRV(sv);

    /* Blessed booleans: JSON::PP::Boolean and friends */
    if (SvOBJECT(ref)) {
      if (sv_derived_from(sv, "JSON::PP::Boolean")
          || sv_derived_from(sv, "Types::Serialiser::Boolean")
          || sv_derived_from(sv, "boolean")) {
        return SvTRUE(ref) ? jv_true() : jv_false();
      }
    }

    /* Array reference */
    if (SvTYPE(ref) == SVt_PVAV) {
      AV *av = (AV *)ref;
      jv arr = jv_array();
      I32 len = av_len(av) + 1;
      for (I32 i = 0; i < len; i++) {
        SV **item = av_fetch(av, i, 0);
        if (item) {
          arr = jv_array_append(arr, sv_to_jv(aTHX_ *item));
        } else {
          arr = jv_array_append(arr, jv_null());
        }
      }
      return arr;
    }

    /* Hash reference */
    if (SvTYPE(ref) == SVt_PVHV) {
      HV *hv = (HV *)ref;
      jv obj = jv_object();
      HE *he;
      hv_iterinit(hv);
      while ((he = hv_iternext(hv)) != NULL) {
        SV *key_sv = HeSVKEY(he);
        if (!key_sv) {
          key_sv = hv_iterkeysv(he);
        }
        SV *val_sv = HeVAL(he);
        char *key_str = SvPVutf8_nolen(key_sv);
        jv key = jv_string(key_str);
        jv val = sv_to_jv(aTHX_ val_sv);
        obj = jv_object_set(obj, key, val);
      }
      return obj;
    }

    /* Unblessed reference to a plain scalar: \1 is true, \0 is false */
    if (SvTYPE(ref) < SVt_PVAV) {
      return SvTRUE(ref) ? jv_true() : jv_false();
    }
  }

  /* Check numeric type first */
  if (SvIOK(sv) && !SvPOK(sv)) {
    return jv_number((double)SvIV(sv));
  }
  if (SvNOK(sv) && !SvPOK(sv)) {
    return jv_number(SvNV(sv));
  }

  /* Everything else is a string */
  STRLEN len;
  char *str = SvPVutf8(sv, len);
  return jv_string_sized(str, len);
}

/* ------------------------------------------------------------------------ *
 * Does this program pull in a module?
 *
 * jq resolves "include"/"import" through the JQ_LIBRARY_PATH attribute, but
 * emptying that attribute is not enough to stop it: linker.c's
 * default_search() prepends "." to the search list whenever a dependency
 * names no search path of its own, so 'include "foo";' still finds ./foo.jq,
 * and 'include "foo" {search:"/x"};' bypasses the attribute altogether.
 * Refusing modules therefore has to be decided from the program text.
 *
 * That is exact rather than a heuristic, because jq's grammar (parser.y,
 * TopLevel) only accepts imports in the program prologue:
 *
 *     TopLevel: Module Imports Query | Module Imports FuncDefs
 *     Module:   <empty> | "module" Query ';'
 *
 * so if the first token after an optional module header is neither "import"
 * nor "include", the program has no imports at all.  Looking only at the
 * prologue is also what keeps legal programs working: "include" is one of
 * parser.y's Keywords, accepted as an object key and after '.', so
 * {include: 1} and .foo.include are valid jq that a scan of the whole text
 * would reject.
 *
 * The tokenizing mirrors lexer.l: whitespace is [ \r\n\t], '#' opens a
 * comment that ends at the next newline except that a backslash before a
 * backslash or a newline continues it, and "import"/"include" lose to the
 * longer IDENT rule when an identifier character or a "::" follows.
 * ------------------------------------------------------------------------ */

static int jqxs_is_ident_char(char c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
      || (c >= '0' && c <= '9') || c == '_';
}

/* Advance past whitespace and comments.  With continuations set, a backslash
 * before a backslash or a newline carries a comment onto the next line, which
 * is what jq 1.7 added to its lexer; clear it for the jq 1.6 rule, where a
 * comment simply ends at the newline. */
static const char *jqxs_skip_blank(const char *p, const char *end,
                                   int continuations) {
  while (p < end) {
    char c = *p;
    if (c == ' ' || c == '\t' || c == '\r' || c == '\n') { p++; continue; }
    if (c != '#') break;

    p++;                                     /* inside a comment */
    while (p < end) {
      if (continuations && *p == '\\') {
        if (p + 1 < end && (p[1] == '\\' || p[1] == '\n')) { p += 2; continue; }
        if (p + 2 < end && p[1] == '\r' && p[2] == '\n')   { p += 3; continue; }
        p++;                                 /* a lone backslash is just text */
        continue;
      }
      if (*p == '\n') { p++; break; }
      if (*p == '\r' && p + 1 < end && p[1] == '\n') { p += 2; break; }
      p++;
    }
  }
  return p;
}

/* Is the token at p exactly this keyword? */
static int jqxs_word_is(const char *p, const char *end, const char *word) {
  STRLEN n = strlen(word);
  const char *q;

  if ((STRLEN)(end - p) < n || memcmp(p, word, n) != 0) return 0;

  q = p + n;
  /* "includes" and "include::x" both lex as one longer IDENT, not a keyword. */
  if (q < end && jqxs_is_ident_char(*q)) return 0;
  if (q + 1 < end && q[0] == ':' && q[1] == ':') return 0;
  return 1;
}

/* Advance past the ';' closing a "module <metadata>;" header, or return NULL
 * if it cannot be found.  Only enough of the metadata expression is understood
 * to locate that ';': nesting and string literals.  String interpolation makes
 * the metadata non-constant, which jq rejects, so meeting one is treated as
 * "cannot tell" rather than parsed. */
static const char *jqxs_skip_module_header(const char *p, const char *end,
                                           int continuations) {
  int depth = 0;

  for (;;) {
    p = jqxs_skip_blank(p, end, continuations);
    if (p >= end) return NULL;

    if (*p == '"') {
      p++;
      while (p < end && *p != '"') {
        if (*p == '\\') {
          if (p + 1 < end && p[1] == '(') return NULL;   /* interpolation */
          p += 2;
          continue;
        }
        p++;
      }
      if (p >= end) return NULL;                         /* unterminated */
      p++;
      continue;
    }

    if (*p == '(' || *p == '[' || *p == '{') { depth++; p++; continue; }
    if (*p == ')' || *p == ']' || *p == '}') { if (depth) depth--; p++; continue; }
    if (*p == ';' && depth == 0) return p + 1;
    p++;
  }
}

static int jqxs_prologue_imports(const char *src, STRLEN len,
                                 int continuations) {
  const char *end = src + len;
  const char *p = jqxs_skip_blank(src, end, continuations);

  if (jqxs_word_is(p, end, "module")) {
    const char *after = jqxs_skip_module_header(p + (sizeof("module") - 1),
                                                end, continuations);
    /* An unparseable header is a program jq will reject anyway; erring towards
     * "has imports" keeps the answer conservative for a caller who forbade
     * them. */
    if (!after) return 1;
    p = jqxs_skip_blank(after, end, continuations);
  }

  return jqxs_word_is(p, end, "import") || jqxs_word_is(p, end, "include");
}

static int jqxs_program_has_imports(const char *src, STRLEN len) {
  /* The two comment rules disagree about one thing: whether an "include" on
   * the line after a comment ending in a backslash is a directive or more
   * comment.  jq 1.6 says directive, jq 1.7 and later say comment, and a
   * JQ_SYSTEM=1 build can be linked against either -- so ask under both and
   * take the union, leaving no reading in which allow_includes => 0 is the
   * lenient one.  The only programs this costs are those the two libjqs read
   * differently, which already cannot mean the same thing on both. */
  return jqxs_prologue_imports(src, len, 1)
      || jqxs_prologue_imports(src, len, 0);
}

/* ------------------------------------------------------------------------ *
 * Calling back into Perl from inside libjq
 *
 * All three callbacks run on the C stack of jq_next(), so none of them may let
 * a Perl exception escape: unwinding from there would leave the jq_state
 * half-way through a program.  Each therefore calls with G_EVAL and deals
 * with $@ itself.
 * ------------------------------------------------------------------------ */

/* The debug and stderr builtins: hand the value to Perl, ignore the result. */
static void jqxs_call_msg_cb(pTHX_ jq_xs_t *self, SV *code, jv msg) {
  dSP;
  SV *arg = jv_to_sv(aTHX_ msg);   /* consumes msg */

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(arg));
  PUTBACK;

  call_sv(code, G_VOID|G_DISCARD|G_EVAL);

  if (SvTRUE(ERRSV) && !self->cb_error) {
    self->cb_error = newSVsv(ERRSV);
  }

  FREETMPS;
  LEAVE;
}

static void jqxs_debug_cb(void *data, jv msg) {
  dTHX;
  jq_xs_t *self = (jq_xs_t *)data;
  jqxs_call_msg_cb(aTHX_ self, self->debug_cb, msg);
}

/* jq_set_stderr_cb, and the "stderr" builtin it serves, arrived in jq 1.7.
 * The vendored build always has it; a JQ_SYSTEM=1 build against an older
 * libjq does not, and Makefile.PL link-probes for it. */
#ifdef JQ_XS_HAVE_STDERR_CB
static void jqxs_stderr_cb(void *data, jv msg) {
  dTHX;
  jq_xs_t *self = (jq_xs_t *)data;
  jqxs_call_msg_cb(aTHX_ self, self->stderr_cb, msg);
}
#endif

/* The input/inputs builtins.  An empty return list ends the stream (libjq
 * turns an invalid carrying no message into the "break" that builtin.jq's
 * "def inputs" catches); anything else, undef included, is one more value, so
 * a callback can still yield JSON null.  A Perl exception becomes a jq error,
 * which is what lets the filter's own try/catch see it. */
static jv jqxs_input_cb(jq_state *jq, void *data) {
  dTHX;
  jq_xs_t *self = (jq_xs_t *)data;
  jv result;
  I32 count;
  dSP;

  PERL_UNUSED_ARG(jq);

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  PUTBACK;

  /* G_ARRAY rather than its 5.36 spelling G_LIST: this builds on 5.26.3. */
  count = call_sv(self->input_cb, G_ARRAY|G_EVAL);
  SPAGAIN;

  if (SvTRUE(ERRSV)) {
    STRLEN len;
    const char *msg = SvPVutf8(ERRSV, len);
    result = jv_invalid_with_msg(jv_string_sized(msg, len));
  } else if (count == 0) {
    result = jv_invalid();                    /* end of stream */
  } else {
    result = sv_to_jv(aTHX_ SP[1 - count]);   /* first of what was returned */
  }

  SP -= count;
  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}

/* Empty one of the stored SV slots. */
static void jqxs_clear_sv(pTHX_ SV **slot) {
  if (*slot) {
    SvREFCNT_dec(*slot);
    *slot = NULL;
  }
}

/* Replace one of the stored code refs, taking a reference to the new one. */
static void jqxs_store_cb(pTHX_ SV **slot, SV *code, const char *what) {
  SV *old = *slot;

  if (code && SvOK(code)) {
    if (!(SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV)) {
      croak("%s must be a code reference", what);
    }
    *slot = SvREFCNT_inc_simple_NN(code);
  } else {
    *slot = NULL;
  }

  if (old) SvREFCNT_dec(old);
}

MODULE = JQ::XS		PACKAGE = JQ::XS

JQ::XS
_new(SV *klass, SV *program_sv, SV *args_sv, SV *attrs_sv, int allow_includes)
  PREINIT:
    jq_xs_t *self;
    ErrorContext ctx;
    const char *prog;
    STRLEN prog_len;
    jv args;
  CODE:
    PERL_UNUSED_VAR(klass);
    if (!SvOK(program_sv)) {
      croak("program argument required");
    }
    prog = SvPV(program_sv, prog_len);

    if (!allow_includes && jqxs_program_has_imports(prog, prog_len)) {
      croak("jq compile error: include/import is not allowed "
            "by this JQ::XS object");
    }

    Newxz(self, 1, jq_xs_t);
    self->state = jq_init();
    if (!self->state) {
      Safefree(self);
      croak("jq_init failed");
    }

    /* Clear the callback slots before anything can consult them.  jq 1.6's
     * jq_init() mallocs the jq_state without initialising these three, so a
     * JQ_SYSTEM=1 build against it starts out with whatever the allocator
     * last left in that block -- and if that was a torn-down JQ::XS object,
     * it is one of these trampolines paired with a freed jq_xs_t, which
     * jq_next() will happily call.  jq 1.7 and later zero them in jq_init and
     * do not need this; it costs three stores either way. */
    jq_set_input_cb(self->state, NULL, NULL);
    jq_set_debug_cb(self->state, NULL, NULL);
#ifdef JQ_XS_HAVE_STDERR_CB
    jq_set_stderr_cb(self->state, NULL, NULL);
#endif

    self->program = newSVsv(program_sv);
    self->output_opts = newRV_noinc((SV *)newHV());

    /* Attributes have to be in place before the program is compiled:
     * JQ_LIBRARY_PATH is what the linker searches while it compiles. */
    if (SvOK(attrs_sv)) {
      HV *attrs = (HV *)SvRV(attrs_sv);
      HE *he;
      hv_iterinit(attrs);
      while ((he = hv_iternext(attrs)) != NULL) {
        SV *key_sv = hv_iterkeysv(he);
        STRLEN klen;
        char *kstr = SvPVutf8(key_sv, klen);
        jq_set_attr(self->state, jv_string_sized(kstr, klen),
                    sv_to_jv(aTHX_ HeVAL(he)));
      }
    }

    /* jq_compile_args takes the named arguments as an object; $ARGS is just
     * one more of them, which is how the jq command line builds it too. */
    args = SvOK(args_sv) ? sv_to_jv(aTHX_ args_sv) : jv_object();

    ctx.buffer = sv_2mortal(newSVpv("", 0));
    jq_set_error_cb(self->state, error_callback, &ctx);

    jq_compile_args(self->state, prog, args);

    jq_set_error_cb(self->state, NULL, NULL);

    if (SvCUR(ctx.buffer) > 0) {
      jq_teardown(&self->state);
      SvREFCNT_dec(self->program);
      SvREFCNT_dec(self->output_opts);
      Safefree(self);
      croak("jq compile error: %s", SvPV_nolen(ctx.buffer));
    }
    RETVAL = self;
  OUTPUT:
    RETVAL

SV *
program(JQ::XS self)
  CODE:
    RETVAL = newSVsv(self->program);
  OUTPUT:
    RETVAL

void
_set_output(JQ::XS self, SV *opts, int dump_flags, int raw_output)
  CODE:
    SvREFCNT_dec(self->output_opts);
    self->output_opts = newSVsv(opts);
    self->dump_flags  = dump_flags;
    self->raw_output  = raw_output;

SV *
output_options(JQ::XS self)
  PREINIT:
    HV *copy;
  CODE:
    /* A copy, so that mutating what a caller got back cannot desynchronise
     * the hash from the flags compiled out of it. */
    copy = newHVhv((HV *)SvRV(self->output_opts));
    RETVAL = newRV_noinc((SV *)copy);
  OUTPUT:
    RETVAL

int
flags(JQ::XS self, ...)
  CODE:
    RETVAL = self->start_flags;
    if (items > 1) {
      self->start_flags = SvOK(ST(1)) ? (int)SvIV(ST(1)) : 0;
    }
  OUTPUT:
    RETVAL

int
die_on_halt_error(JQ::XS self, ...)
  CODE:
    RETVAL = self->die_on_halt_error;
    if (items > 1) {
      self->die_on_halt_error = SvTRUE(ST(1)) ? 1 : 0;
    }
  OUTPUT:
    RETVAL

void
set_debug_cb(JQ::XS self, SV *code = &PL_sv_undef)
  CODE:
    jqxs_store_cb(aTHX_ &self->debug_cb, code, "debug callback");
    if (self->debug_cb) {
      jq_set_debug_cb(self->state, jqxs_debug_cb, self);
    } else {
      jq_set_debug_cb(self->state, NULL, NULL);
    }

void
set_stderr_cb(JQ::XS self, SV *code = &PL_sv_undef)
  CODE:
#ifdef JQ_XS_HAVE_STDERR_CB
    jqxs_store_cb(aTHX_ &self->stderr_cb, code, "stderr callback");
    if (self->stderr_cb) {
      jq_set_stderr_cb(self->state, jqxs_stderr_cb, self);
    } else {
      jq_set_stderr_cb(self->state, NULL, NULL);
    }
#else
    PERL_UNUSED_VAR(self);
    /* Disconnecting it is what an unsupporting libjq already does. */
    if (SvOK(code)) {
      croak("this JQ::XS was built against a libjq with no jq_set_stderr_cb "
            "(jq 1.7 added it), so the stderr builtin cannot be served");
    }
#endif

void
set_input_cb(JQ::XS self, SV *code = &PL_sv_undef)
  CODE:
    jqxs_store_cb(aTHX_ &self->input_cb, code, "input callback");
    if (self->input_cb) {
      jq_set_input_cb(self->state, jqxs_input_cb, self);
    } else {
      jq_set_input_cb(self->state, NULL, NULL);
    }

void
set_attr(JQ::XS self, SV *name, SV *value)
  PREINIT:
    STRLEN len;
    char *str;
  CODE:
    str = SvPVutf8(name, len);
    jq_set_attr(self->state, jv_string_sized(str, len), sv_to_jv(aTHX_ value));

SV *
attr(JQ::XS self, SV *name)
  PREINIT:
    STRLEN len;
    char *str;
    jv value;
  CODE:
    str = SvPVutf8(name, len);
    value = jq_get_attr(self->state, jv_string_sized(str, len));
    /* An attribute that was never set comes back invalid, which jv_to_sv maps
     * to undef -- the same as an attribute explicitly set to null. */
    RETVAL = jv_to_sv(aTHX_ value);
  OUTPUT:
    RETVAL

int
halted(JQ::XS self)
  CODE:
    RETVAL = self->halted;
  OUTPUT:
    RETVAL

SV *
exit_code(JQ::XS self)
  CODE:
    RETVAL = self->exit_code ? newSVsv(self->exit_code) : newSV(0);
  OUTPUT:
    RETVAL

SV *
error_message(JQ::XS self)
  CODE:
    RETVAL = self->error_message ? newSVsv(self->error_message) : newSV(0);
  OUTPUT:
    RETVAL

void
dump_disassembly(JQ::XS self, int indent = 0)
  CODE:
    /* jq prints this with C printf() on the process's stdout, which is not
     * Perl's STDOUT handle: flush Perl's first so anything already written
     * through it comes out ahead of the disassembly, and fflush(NULL)
     * afterwards to push out the disassembly itself without having to name
     * a FILE * that PerlIO may have redefined. */
    PerlIO_flush(PerlIO_stdout());
    jq_dump_disassembly(self->state, indent);
    fflush(NULL);

AV *
_xs_process(JQ::XS self, SV *input_sv, int as_json, int dump_flags, int raw_output)
  PREINIT:
    jv input;
    jv res;
    AV *results;
    SV *output_sv;
    int halted;
  CODE:
    /* -1 means "whatever the object was configured with". */
    if (dump_flags < 0) {
      dump_flags = self->dump_flags;
      raw_output = self->raw_output;
    }

    if (self->running) {
      croak("JQ::XS: cannot reenter process() on a filter that is already running");
    }

    /* Parse/convert input */
    if (as_json) {
      STRLEN len;
      const char *json_str = SvPVutf8(input_sv, len);
      input = jv_parse_sized(json_str, len);
      if (!jv_is_valid(input)) {
        jv err_msg = jv_invalid_get_msg(input);
        SV *errsv;
        if (jv_get_kind(err_msg) == JV_KIND_STRING) {
          errsv = sv_2mortal(newSVpv(jv_string_value(err_msg), 0));
        } else {
          errsv = sv_2mortal(newSVpv("unknown parse error", 0));
        }
        jv_free(err_msg);
        croak("Invalid JSON: %s", SvPV_nolen(errsv));
      }
    } else {
      input = sv_to_jv(aTHX_ input_sv);
    }

    /* Forget what the previous run halted with */
    self->halted = 0;
    jqxs_clear_sv(aTHX_ &self->exit_code);
    jqxs_clear_sv(aTHX_ &self->error_message);
    jqxs_clear_sv(aTHX_ &self->cb_error);

    /* Run jq filter */
    self->running = 1;
    jq_start(self->state, input, self->start_flags);

    /* Collect results */
    results = newAV();
    sv_2mortal((SV *)results);
    while (jv_is_valid(res = jq_next(self->state))) {
      if (!as_json) {
        output_sv = jv_to_sv(aTHX_ res);
        av_push(results, output_sv);
      } else if (raw_output && jv_get_kind(res) == JV_KIND_STRING
                 && !(dump_flags & JV_PRINT_ASCII)) {
        /* jq -r: a string result is its own output.  Sized, because unlike a
         * JSON dump -- where a NUL comes back escaped -- a raw string can
         * contain one.  "jq -r -a" deliberately does not come through here:
         * it dumps the string escaped and quoted, and this follows suit. */
        jv sized = jv_copy(res);
        int len = jv_string_length_bytes(sized);
        output_sv = newSVpvn(jv_string_value(res), len);
        SvUTF8_on(output_sv);
        av_push(results, output_sv);
        jv_free(res);
      } else {
        jv json_str_jv = jv_dump_string(res, dump_flags);
        jv sized = jv_copy(json_str_jv);
        int len = jv_string_length_bytes(sized);
        output_sv = newSVpvn(jv_string_value(json_str_jv), len);
        SvUTF8_on(output_sv);
        av_push(results, output_sv);
        jv_free(json_str_jv);
      }
    }

    /* halt and halt_error stop the program without producing a result, so the
     * loop above ends on an invalid just as an uncaught error does.  jq's own
     * main.c checks for the halt first, because that invalid may carry a
     * message belonging to the halt rather than to a failed filter. */
    halted = jq_halted(self->state);
    if (halted) {
      self->halted = 1;
      self->exit_code = jv_to_sv(aTHX_ jq_get_exit_code(self->state));
      self->error_message = jv_to_sv(aTHX_ jq_get_error_message(self->state));
      jv_free(res);
    } else if (!jv_is_valid(res)) {
      if (jv_invalid_has_msg(jv_copy(res))) {
        jv err_msg = jv_invalid_get_msg(res);
        jv err_text_jv = jq_format_error(err_msg);
        SV *errsv;
        if (jv_get_kind(err_text_jv) == JV_KIND_STRING) {
          errsv = sv_2mortal(newSVpv(jv_string_value(err_text_jv), 0));
        } else {
          errsv = sv_2mortal(newSVpv("unknown runtime error", 0));
        }
        jv_free(err_text_jv);
        self->running = 0;
        croak("jq runtime error: %s", SvPV_nolen(errsv));
      }
      jv_free(res);
    }
    self->running = 0;

    /* An exception the debug or stderr callback threw could not be raised
     * from inside libjq; now that the run is over, it can be. */
    if (self->cb_error) {
      SV *err = sv_2mortal(self->cb_error);
      self->cb_error = NULL;
      croak_sv(err);
    }

    /* halt_error is jq's way of failing on purpose.  Left to itself it is
     * silent, so a caller who asked for it gets an exception instead. */
    if (halted && self->die_on_halt_error && SvOK(self->error_message)) {
      croak_sv(sv_2mortal(newSVsv(self->error_message)));
    }

    RETVAL = results;
  OUTPUT:
    RETVAL

SV *
jq_version()
  CODE:
#ifdef JQ_XS_EMBEDDED
    RETVAL = newSVpvs(JQ_VERSION);
#else
    /* The OS libjq exposes no version, at build time or at run time. */
    RETVAL = newSV(0);
#endif
  OUTPUT:
    RETVAL

int
set_colors(const char *spec)
  CODE:
    RETVAL = jq_set_colors(spec);
  OUTPUT:
    RETVAL

SV *
features()
  PREINIT:
    HV *hv;
  CODE:
    /* What this particular build can do, which under JQ_SYSTEM=1 depends on
     * the libjq it was linked against. */
    hv = newHV();
    hv_stores(hv, "embedded_jq",
#ifdef JQ_XS_EMBEDDED
              newSViv(1)
#else
              newSViv(0)
#endif
    );
    hv_stores(hv, "stderr_cb",
#ifdef JQ_XS_HAVE_STDERR_CB
              newSViv(1)
#else
              newSViv(0)
#endif
    );
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
_program_has_imports(SV *program_sv)
  PREINIT:
    const char *prog;
    STRLEN len;
  CODE:
    prog = SvPV(program_sv, len);
    RETVAL = boolSV(jqxs_program_has_imports(prog, len));
  OUTPUT:
    RETVAL

SV *
parse_json(SV *text_sv)
  PREINIT:
    STRLEN len;
    const char *text;
    jv value;
  CODE:
    text = SvPVutf8(text_sv, len);
    value = jv_parse_sized(text, len);
    if (!jv_is_valid(value)) {
      jv msg = jv_invalid_get_msg(value);
      SV *errsv = sv_2mortal(newSVpv(
        jv_get_kind(msg) == JV_KIND_STRING ? jv_string_value(msg)
                                           : "unknown parse error", 0));
      jv_free(msg);
      croak("Invalid JSON: %s", SvPV_nolen(errsv));
    }
    RETVAL = jv_to_sv(aTHX_ value);
  OUTPUT:
    RETVAL

void
parse_json_stream(SV *text_sv)
  PREINIT:
    STRLEN len;
    const char *text;
    jv_parser *parser;
    jv value;
  PPCODE:
    /* jq's own reader: one buffer may hold any number of whitespace- or
     * newline-separated JSON values, which is what "jq ." consumes from a
     * stream and what jv_parse_sized rejects. */
    text = SvPVutf8(text_sv, len);
    parser = jv_parser_new(0);
    jv_parser_set_buf(parser, text, (int)len, 0);

    while (jv_is_valid(value = jv_parser_next(parser))) {
      XPUSHs(sv_2mortal(jv_to_sv(aTHX_ value)));
    }

    if (jv_invalid_has_msg(jv_copy(value))) {
      jv msg = jv_invalid_get_msg(value);
      SV *errsv = sv_2mortal(newSVpv(
        jv_get_kind(msg) == JV_KIND_STRING ? jv_string_value(msg)
                                           : "unknown parse error", 0));
      jv_free(msg);
      jv_parser_free(parser);
      croak("Invalid JSON: %s", SvPV_nolen(errsv));
    }
    jv_free(value);
    jv_parser_free(parser);

SV *
_to_json(SV *data_sv, int dump_flags)
  PREINIT:
    jv text;
    jv sized;
    int len;
  CODE:
    text = jv_dump_string(sv_to_jv(aTHX_ data_sv), dump_flags);
    sized = jv_copy(text);
    len = jv_string_length_bytes(sized);
    RETVAL = newSVpvn(jv_string_value(text), len);
    SvUTF8_on(RETVAL);
    jv_free(text);
  OUTPUT:
    RETVAL

void
DESTROY(JQ::XS self)
  CODE:
    if (self) {
      if (self->state) {
        jq_teardown(&self->state);
      }
      SvREFCNT_dec(self->program);
      SvREFCNT_dec(self->output_opts);
      jqxs_clear_sv(aTHX_ &self->debug_cb);
      jqxs_clear_sv(aTHX_ &self->stderr_cb);
      jqxs_clear_sv(aTHX_ &self->input_cb);
      jqxs_clear_sv(aTHX_ &self->exit_code);
      jqxs_clear_sv(aTHX_ &self->error_message);
      jqxs_clear_sv(aTHX_ &self->cb_error);
      Safefree(self);
    }
