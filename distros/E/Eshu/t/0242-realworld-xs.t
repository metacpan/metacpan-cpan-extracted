use strict;
use warnings;
use Test::More;
use Eshu;

sub xs { Eshu->indent_xs($_[0]) }

# ── already-formatted XS snippets ─────────────────────────────────

# 1. basic MODULE/PACKAGE header
{
	my $code = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = MyModule    PACKAGE = MyModule
END
	is(xs($code), $code, 'XS: module/package header');
}

# 2. simple void XSUB
{
	my $code = <<'END';
MODULE = MyMod    PACKAGE = MyMod

void
hello()
	CODE:
		printf("Hello from XS!\n");
END
	is(xs($code), $code, 'XS: simple void XSUB');
}

# 3. XSUB returning int
{
	my $code = <<'END';
MODULE = Math    PACKAGE = Math

int
add(a, b)
	int a
	int b
	CODE:
		RETVAL = a + b;
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB returning int with OUTPUT');
}

# 4. XSUB returning SV*
{
	my $code = <<'END';
MODULE = Str    PACKAGE = Str

SV *
repeat(s, n)
	const char *s
	int         n
	CODE:
		RETVAL = newSV(0);
		for (int i = 0; i < n; i++) {
			sv_catpv(RETVAL, s);
		}
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB returning SV* with CODE/OUTPUT');
}

# 5. XSUB with INIT section
{
	my $code = <<'END';
MODULE = Buf    PACKAGE = Buf

SV *
read_chunk(fh, len)
	FILE  *fh
	size_t len
	INIT:
		if (len == 0)
		XSRETURN_UNDEF;
	CODE:
		char *buf = malloc(len + 1);
		if (!buf)
		XSRETURN_UNDEF;
		size_t n = fread(buf, 1, len, fh);
		buf[n] = '\0';
		RETVAL = newSVpvn(buf, n);
		free(buf);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB with INIT guard');
}

# 6. PPCODE XSUB returning list
{
	my $code = <<'END';
MODULE = ListOps    PACKAGE = ListOps

void
range(from, to)
	int from
	int to
	PPCODE:
		for (int i = from; i <= to; i++) {
			XPUSHs(sv_2mortal(newSViv(i)));
		}
END
	is(xs($code), $code, 'XS: PPCODE returning list');
}

# 7. XSUB with C helper function
{
	my $code = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static unsigned long
djb2(const char *s) {
	unsigned long h = 5381;
	int c;
	while ((c = (unsigned char)*s++) != 0) {
		h = ((h << 5) + h) + c;
	}
	return h;
}

MODULE = Hash    PACKAGE = Hash

unsigned long
hash_string(s)
	const char *s
	CODE:
		RETVAL = djb2(s);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB with C helper');
}

# 8. BOOT section
{
	my $code = <<'END';
MODULE = MyExt    PACKAGE = MyExt

BOOT:
	av_push(get_av("MyExt::ISA", GV_ADD), newSVpvs("Exporter"));
	SV *ver = get_sv("MyExt::VERSION", GV_ADD);
	sv_setpvs(ver, "1.00");
END
	is(xs($code), $code, 'XS: BOOT section');
}

# 9. XSUB with nested C
{
	my $code = <<'END';
MODULE = Crypto    PACKAGE = Crypto

SV *
xor_bytes(data, key)
	SV *data
	SV *key
	CODE:
		STRLEN dlen, klen;
		const char *d = SvPVbyte(data, dlen);
		const char *k = SvPVbyte(key,  klen);
		if (klen == 0)
		XSRETURN_UNDEF;
		char *out = malloc(dlen);
		if (!out)
		XSRETURN_UNDEF;
		for (size_t i = 0; i < dlen; i++) {
			out[i] = d[i] ^ k[i % klen];
		}
		RETVAL = newSVpvn(out, dlen);
		free(out);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB with nested C loop');
}

# 10. multiple XSUBs in one file
{
	my $code = <<'END';
MODULE = Vec    PACKAGE = Vec

double
dot(ax, ay, bx, by)
	double ax
	double ay
	double bx
	double by
	CODE:
		RETVAL = ax * bx + ay * by;
	OUTPUT:
		RETVAL

double
length(x, y)
	double x
	double y
	CODE:
		RETVAL = sqrt(x * x + y * y);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: multiple XSUBs');
}

# 11. XSUB accessing Perl hash
{
	my $code = <<'END';
MODULE = Obj    PACKAGE = Obj

void
set_field(self, key, val)
	SV         *self
	const char *key
	SV         *val
	CODE:
		HV *hv = (HV *)SvRV(self);
		hv_store(hv, key, strlen(key), SvREFCNT_inc(val), 0);
END
	is(xs($code), $code, 'XS: XSUB setting hash field');
}

# 12. XSUB reading Perl array
{
	my $code = <<'END';
MODULE = Arr    PACKAGE = Arr

IV
sum_array(aref)
	SV *aref
	CODE:
		AV *av = (AV *)SvRV(aref);
		IV  total = 0;
		for (SSize_t i = 0; i <= av_len(av); i++) {
			SV **svp = av_fetch(av, i, 0);
			if (svp && *svp) {
				total += SvIV(*svp);
			}
		}
		RETVAL = total;
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB summing array ref');
}

# 13. XSUB with SV mortal
{
	my $code = <<'END';
MODULE = Fmt    PACKAGE = Fmt

void
print_pairs(href)
	SV *href
	PPCODE:
		HV *hv = (HV *)SvRV(href);
		HE *he;
		hv_iterinit(hv);
		while ((he = hv_iternext(hv)) != NULL) {
			SV *key = hv_iterkeysv(he);
			SV *val = hv_iterval(hv, he);
			XPUSHs(sv_2mortal(newSVpvf("%s=%s",
			SvPVutf8_nolen(key), SvPVutf8_nolen(val))));
		}
END
	is(xs($code), $code, 'XS: PPCODE iterating hash ref');
}

# 14. XSUB with typemap
{
	my $code = <<'END';
MODULE = File    PACKAGE = File

FILE *
fopen_wrap(path, mode)
	const char *path
	const char *mode
	CODE:
		RETVAL = fopen(path, mode);
		if (!RETVAL)
		XSRETURN_UNDEF;
	OUTPUT:
		RETVAL

void
fclose_wrap(fh)
	FILE *fh
	CODE:
		fclose(fh);
END
	is(xs($code), $code, 'XS: FILE* typemap usage');
}

# 15. XSUB with C struct
{
	my $code = <<'END';
typedef struct {
	double x;
	double y;
} Point;

MODULE = Geom    PACKAGE = Geom

SV *
point_new(x, y)
	double x
	double y
	CODE:
		Point *p = malloc(sizeof(Point));
		p->x = x;
		p->y = y;
		RETVAL = newSViv((IV)p);
	OUTPUT:
		RETVAL

double
point_distance(p1_sv, p2_sv)
	SV *p1_sv
	SV *p2_sv
	CODE:
		Point *p1 = (Point *)SvIV(p1_sv);
		Point *p2 = (Point *)SvIV(p2_sv);
		double dx = p1->x - p2->x;
		double dy = p1->y - p2->y;
		RETVAL = sqrt(dx*dx + dy*dy);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: C struct wrapped in XS');
}

# 16. XSUB calling Perl callback
{
	my $code = <<'END';
MODULE = Iter    PACKAGE = Iter

void
each_char(str, callback)
	SV *str
	SV *callback
	CODE:
		STRLEN len;
		const char *s = SvPVutf8(str, len);
		for (STRLEN i = 0; i < len; i++) {
			dSP;
			ENTER; SAVETMPS;
			PUSHMARK(SP);
			XPUSHs(sv_2mortal(newSVpvn(s + i, 1)));
			PUTBACK;
			call_sv(callback, G_VOID | G_DISCARD);
			FREETMPS; LEAVE;
		}
END
	is(xs($code), $code, 'XS: calling Perl callback from C');
}

# 17. XSUB with NO_INIT
{
	my $code = <<'END';
MODULE = Conv    PACKAGE = Conv

SV *
int_to_hex(n)
	UV n
	CODE:
		char buf[32];
		snprintf(buf, sizeof(buf), "0x%llx", (unsigned long long)n);
		RETVAL = newSVpv(buf, 0);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: UV to hex string');
}

# 18. XSUB with CLEANUP
{
	my $code = <<'END';
MODULE = Tmp    PACKAGE = Tmp

SV *
compress(data)
	SV *data
	CODE:
		STRLEN len;
		const char *in = SvPVbyte(data, len);
		uLong out_len = compressBound(len);
		Bytef *out = malloc(out_len);
		if (!out)
		XSRETURN_UNDEF;
		int rc = compress2(out, &out_len, (const Bytef *)in, len, Z_BEST_SPEED);
		if (rc != Z_OK) {
			free(out);
			XSRETURN_UNDEF;
		}
		RETVAL = newSVpvn((char *)out, out_len);
	CLEANUP:
		free(out);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: XSUB with CLEANUP section');
}

# 19. XSUB error propagation
{
	my $code = <<'END';
MODULE = Net    PACKAGE = Net

IV
connect_tcp(host, port)
	const char *host
	int         port
	CODE:
		struct addrinfo *ai = NULL;
		char port_str[8];
		snprintf(port_str, sizeof(port_str), "%d", port);
		int rc = getaddrinfo(host, port_str, NULL, &ai);
		if (rc != 0) {
			Perl_croak(aTHX_ "getaddrinfo: %s", gai_strerror(rc));
		}
		int fd = socket(ai->ai_family, SOCK_STREAM, 0);
		if (fd < 0) {
			freeaddrinfo(ai);
			Perl_croak(aTHX_ "socket: %s", strerror(errno));
		}
		if (connect(fd, ai->ai_addr, ai->ai_addrlen) < 0) {
			close(fd);
			freeaddrinfo(ai);
			Perl_croak(aTHX_ "connect: %s", strerror(errno));
		}
		freeaddrinfo(ai);
		RETVAL = fd;
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: TCP connect with croak on error');
}

# 20. XSUB with #ifdef
{
	my $code = <<'END';
MODULE = Sys    PACKAGE = Sys

SV *
hostname()
	CODE:
#ifdef _WIN32
		char buf[256];
		DWORD len = sizeof(buf);
		GetComputerNameA(buf, &len);
		RETVAL = newSVpvn(buf, len);
#else
		char buf[256];
		gethostname(buf, sizeof(buf));
		RETVAL = newSVpv(buf, 0);
#endif
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: platform ifdef inside XSUB');
}

# 21. XS with inline C
{
	my $code = <<'END';
#define FAST_ABS(x) ((x) < 0 ? -(x) : (x))

MODULE = Fast    PACKAGE = Fast

IV
fast_abs(n)
	IV n
	CODE:
		RETVAL = FAST_ABS(n);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: inline macro used in XSUB');
}

# 22. XSUB modifying caller's SV
{
	my $code = <<'END';
MODULE = Ref    PACKAGE = Ref

void
double_in_place(sv)
	SV *sv
	CODE:
		sv_setiv(sv, SvIV(sv) * 2);
END
	is(xs($code), $code, 'XS: modify SV in place');
}

# 23. XSUB accepting and returning AV*
{
	my $code = <<'END';
MODULE = Arr2    PACKAGE = Arr2

SV *
array_reverse(aref)
	SV *aref
	CODE:
		AV *in  = (AV *)SvRV(aref);
		AV *out = newAV();
		SSize_t n = av_len(in);
		for (SSize_t i = n; i >= 0; i--) {
			SV **svp = av_fetch(in, i, 0);
			av_push(out, svp ? SvREFCNT_inc(*svp) : newSV(0));
		}
		RETVAL = newRV_noinc((SV *)out);
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: reverse array ref');
}

# 24. XSUB with multiple return values via PPCODE
{
	my $code = <<'END';
MODULE = Math2    PACKAGE = Math2

void
divmod(a, b)
	IV a
	IV b
	PPCODE:
		if (b == 0)
		Perl_croak(aTHX_ "division by zero");
		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(a / b)));
		PUSHs(sv_2mortal(newSViv(a % b)));
END
	is(xs($code), $code, 'XS: divmod via PPCODE');
}

# 25. XS constant sub
{
	my $code = <<'END';
MODULE = Const    PACKAGE = Const

IV
PI_TIMES_1000()
	CODE:
		RETVAL = 3141;
	OUTPUT:
		RETVAL

IV
MAX_UINT16()
	CODE:
		RETVAL = 65535;
	OUTPUT:
		RETVAL
END
	is(xs($code), $code, 'XS: constant XSUBs');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
MODULE = T    PACKAGE = T

int
square(n)
int n
CODE:
RETVAL = n * n;
OUTPUT:
RETVAL
END
	my $exp = <<'END';
MODULE = T    PACKAGE = T

int
square(n)
	int n
	CODE:
		RETVAL = n * n;
	OUTPUT:
		RETVAL
END
	is(xs($in), $exp, 'XS: unindented CODE/OUTPUT normalised');
}

# 27
{
	my $in = <<'END';
MODULE = T    PACKAGE = T

void
hello()
CODE:
printf("hi\n");
END
	my $exp = <<'END';
MODULE = T    PACKAGE = T

void
hello()
	CODE:
		printf("hi\n");
END
	is(xs($in), $exp, 'XS: unindented printf in CODE normalised');
}

# 28
{
	my $in = <<'END';
MODULE = T    PACKAGE = T

IV
clamp(v, lo, hi)
IV v
IV lo
IV hi
CODE:
if (v < lo) { RETVAL = lo; }
else if (v > hi) { RETVAL = hi; }
else { RETVAL = v; }
OUTPUT:
RETVAL
END
	my $exp = <<'END';
MODULE = T    PACKAGE = T

IV
clamp(v, lo, hi)
	IV v
	IV lo
	IV hi
	CODE:
		if (v < lo) { RETVAL = lo; }
		else if (v > hi) { RETVAL = hi; }
		else { RETVAL = v; }
	OUTPUT:
		RETVAL
END
	is(xs($in), $exp, 'XS: unindented clamp normalised');
}

# 29
{
	my $in = <<'END';
MODULE = T    PACKAGE = T

BOOT:
av_push(get_av("T::EXPORT_OK", GV_ADD), newSVpvs("square"));
END
	my $exp = <<'END';
MODULE = T    PACKAGE = T

BOOT:
	av_push(get_av("T::EXPORT_OK", GV_ADD), newSVpvs("square"));
END
	is(xs($in), $exp, 'XS: unindented BOOT normalised');
}

# 30
{
	my $in = <<'END';
MODULE = T    PACKAGE = T

void
each(aref, cb)
SV *aref
SV *cb
PPCODE:
AV *av = (AV *)SvRV(aref);
for (SSize_t i = 0; i <= av_len(av); i++) {
SV **svp = av_fetch(av, i, 0);
dSP; ENTER; SAVETMPS; PUSHMARK(SP);
XPUSHs(svp ? *svp : &PL_sv_undef);
PUTBACK; call_sv(cb, G_VOID|G_DISCARD);
FREETMPS; LEAVE;
}
END
	my $exp = <<'END';
MODULE = T    PACKAGE = T

void
each(aref, cb)
	SV *aref
	SV *cb
	PPCODE:
		AV *av = (AV *)SvRV(aref);
		for (SSize_t i = 0; i <= av_len(av); i++) {
			SV **svp = av_fetch(av, i, 0);
			dSP; ENTER; SAVETMPS; PUSHMARK(SP);
			XPUSHs(svp ? *svp : &PL_sv_undef);
			PUTBACK; call_sv(cb, G_VOID|G_DISCARD);
			FREETMPS; LEAVE;
		}
END
	is(xs($in), $exp, 'XS: unindented PPCODE with loop normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"MODULE = T    PACKAGE = T\n\nint\nadd(a,b)\nint a\nint b\nCODE:\nRETVAL=a+b;\nOUTPUT:\nRETVAL\n",
	"MODULE = T    PACKAGE = T\n\nvoid\nnoop()\nCODE:\n/* nothing */\n",
	"#include \"EXTERN.h\"\n#include \"perl.h\"\n#include \"XSUB.h\"\nMODULE=T PACKAGE=T\nBOOT:\nSV*v=get_sv(\"T::VERSION\",GV_ADD);sv_setpvs(v,\"1.0\");\n",
	"MODULE=T PACKAGE=T\nSV*\nhex_sv(n)\nUV n\nCODE:\nchar b[32];snprintf(b,sizeof(b),\"0x%llx\",(ull)n);RETVAL=newSVpv(b,0);\nOUTPUT:\nRETVAL\n",
	"MODULE=T PACKAGE=T\nvoid\nfree_ptr(p)\nSV*p\nCODE:\nfree((void*)SvIV(p));\n",
	"MODULE = T    PACKAGE = T\n\nIV\ncount(aref)\n\tSV *aref\nCODE:\n\tRETVAL = av_len((AV*)SvRV(aref)) + 1;\nOUTPUT:\n\tRETVAL\n",
	"MODULE = T PACKAGE = T\n\nSV *\nslurp(path)\n\tconst char *path\nCODE:\n\tFILE *f=fopen(path,\"r\");\n\tif(!f)XSRETURN_UNDEF;\n\tfseek(f,0,SEEK_END);\n\tlong n=ftell(f);\n\trewind(f);\n\tchar *b=malloc(n+1);\n\tfread(b,1,n,f);\n\tb[n]='\\0';\n\tfclose(f);\n\tRETVAL=newSVpvn(b,n);\n\tfree(b);\nOUTPUT:\n\tRETVAL\n",
	"MODULE=T PACKAGE=T\nBOOT:\nHV*stash=gv_stashpvs(\"T\",GV_ADD);\nnewCONSTSUB(stash,\"OK\",newSViv(1));\nnewCONSTSUB(stash,\"ERR\",newSViv(-1));\n",
	"MODULE = T PACKAGE = T\n\nvoid\nlog_call(name, args)\n\tconst char *name\n\tSV *args\nCODE:\n\tAV *av=(AV*)SvRV(args);\n\tPerlIO_printf(PerlIO_stderr(),\"%s(%ld args)\\n\",name,(long)(av_len(av)+1));\n",
	"MODULE = T PACKAGE = T\n\nIV\nbsearch_iv(aref, target)\n\tSV *aref\n\tIV target\nCODE:\n\tAV *av=(AV*)SvRV(aref);\n\tSSize_t lo=0,hi=av_len(av),mid;\n\tRETVAL=-1;\n\twhile(lo<=hi){\n\t\tmid=lo+(hi-lo)/2;\n\t\tIV v=SvIV(*av_fetch(av,mid,0));\n\t\tif(v==target){RETVAL=mid;break;}\n\t\telse if(v<target)lo=mid+1;\n\t\telse hi=mid-1;\n\t}\nOUTPUT:\n\tRETVAL\n",
) {
	my $once = xs($snippet);
	is(xs($once), $once, 'XS: snippet idempotent');
}

done_testing;
