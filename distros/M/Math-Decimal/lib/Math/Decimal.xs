#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

/* parameter classification */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

/* fixed strings for important numbers */

static SV *signum_sv[3];

/* exceptions */

#define throw_not_decimal() croak("not a decimal number")

/*
 * decimal syntax handling
 *
 * The "decimal" structure represents a decimal number in a form slightly
 * abstracted from the API string form.  The sign is represented as the
 * "signum" member.  The two pairs of pointers delimit the digits of the
 * number, which must be stored in memory as ASCII digits.  The integer
 * and fractional digits are stored separately, which is a pain to handle
 * but means that the digits can actually be stored in an input SV, where
 * there's a '.' between the groups of digits.  Either group of digits
 * may be empty (foo_start == foo_end).  In the general case, there may
 * be superfluous leading or trailing zeroes in the number.
 *
 * The read_canonical() function takes an input SV and parses it into
 * "struct decimal" form.  The resulting structure points into the SV,
 * which must therefore stay alive while the number is being processed.
 * The number is fully trimmed as it is parsed: it is guaranteed to have
 * no leading or trailing zero digits.  If the input SV is not of valid
 * form, an exception is thrown.
 *
 * The canonical_write() function takes a "struct decimal" and
 * generates an SV expressing the number.  It will always generate valid
 * syntax, but it does not perform trimming.  To generate the output in
 * canonical form, as most functions require, the structure must already
 * be trimmed.
 *
 * The identity_canonical() function canonises a "struct decimal".  It trims
 * off leading and trailing zero digits, and will set signum to 0 if the
 * value is zero.
 */

struct decimal {
	int signum;
	char *int_start, *int_end;
	char *frac_start, *frac_end;
};

#define read_canonical(r, r_sv) THX_read_canonical(aTHX_ r, r_sv)
static void THX_read_canonical(pTHX_ struct decimal *r, SV *r_sv)
{
	STRLEN len;
	char *p, *end, c, *q;
	if(!sv_is_string(r_sv)) throw_not_decimal();
	p = SvPV(r_sv, len);
	end = p + len;
	c = *p;
	r->signum = c == '-' ? -1 : +1;
	if(c == '+' || c == '-') c = *++p;
	if(c < '0' || c > '9') throw_not_decimal();
	q = 0;
	do {
		if(!q && c != '0') q = p;
		c = *++p;
	} while(c >= '0' && c <= '9');
	r->int_start = q ? q : p;
	r->int_end = p;
	if(c == '.') {
		c = *++p;
		r->frac_start = q = p;
		if(c < '0' || c > '9') throw_not_decimal();
		do {
			p++;
			if(c != '0') q = p;
			c = *p;
		} while(c >= '0' && c <= '9');
		r->frac_end = q;
	} else {
		r->frac_start = p;
		r->frac_end = p;
	}
	if(p != end) throw_not_decimal();
	if(r->int_start == r->int_end && r->frac_start == r->frac_end)
		r->signum = 0;
}

#define canonical_write(r) THX_canonical_write(aTHX_ r)
static SV *THX_canonical_write(pTHX_ struct decimal *r)
{
	STRLEN len;
	char *p;
	SV *r_sv = newSVpvs("");
	len = (r->signum == -1) +
		(r->int_start==r->int_end ? 1 : r->int_end-r->int_start) +
		(r->frac_start==r->frac_end ? 0 :
			(r->frac_end-r->frac_start)+1);
	p = SvGROW(r_sv, len+1);
	SvCUR_set(r_sv, len);
	if(r->signum == -1) *p++ = '-';
	if(r->int_start == r->int_end) {
		*p++ = '0';
	} else {
		len = r->int_end - r->int_start;
		Copy(r->int_start, p, len, char);
		p += len;
	}
	if(r->frac_start != r->frac_end) {
		len = r->frac_end - r->frac_start;
		*p++ = '.';
		Copy(r->frac_start, p, len, char);
		p += len;
	}
	*p = 0;
	return r_sv;
}

static void identity_canonical(struct decimal *a)
{
	char *p, *q;
	for(p = a->int_start, q = a->int_end; p != q && *p == '0'; p++)
		;
	a->int_start = p;
	for(p = a->frac_end, q = a->frac_start; p != q && p[-1] == '0'; p--)
		;
	a->frac_end = p;
	if(a->int_start == a->int_end && a->frac_start == a->frac_end)
		a->signum = 0;
}

/*
 * arithmetic utilities
 *
 * A "canonical_" prefix indicates that the function requires trimmed
 * inputs.  A "_canonical" suffix indicates that the function generates
 * trimmed outputs.
 */

#define canonical_get_expt(a) THX_canonical_get_expt(aTHX_ a)
static int THX_canonical_get_expt(pTHX_ struct decimal *a)
{
	char *p, *q;
	int val;
	if(a->frac_start != a->frac_end) croak("not an integer");
	p = a->int_start;
	q = a->int_end;
	if((q-p) > 9) croak("exponent too large");
	val = 0;
	while(p != q)
		val = val*10 + (*p++) - '0';
	return a->signum == -1 ? -val : +val;
}

static int canonical_cmp_magnitude(struct decimal *a, struct decimal *b)
{
	STRLEN al, bl;
	char *ap, *bp;
	al = a->int_end - a->int_start;
	bl = b->int_end - b->int_start;
	if(al != bl) return al < bl ? -1 : +1;
	for(ap=a->int_start, bp=b->int_start; ap != a->int_end; ap++, bp++) {
		char ac = *ap, bc = *bp;
		if(ac != bc) return ac < bc ? -1 : +1;
	}
	ap = a->frac_start;
	bp = b->frac_start;
	for(ap=a->frac_start, bp=b->frac_start; ; ap++, bp++) {
		if(ap == a->frac_end && bp == b->frac_end) {
			return 0;
		} else if(ap == a->frac_end) {
			return -1;
		} else if(bp == b->frac_end) {
			return +1;
		} else {
			char ac = *ap, bc = *bp;
			if(ac != bc) return ac < bc ? -1 : +1;
		}
	}
}

static int canonical_cmp_value(struct decimal *a, struct decimal *b)
{
	int as = a->signum, bs = b->signum;
	if(as != bs) {
		return as < bs ? -1 : +1;
	} else if(as == 0) {
		return 0;
	} else if(as == +1) {
		return canonical_cmp_magnitude(a, b);
	} else {
		return canonical_cmp_magnitude(b, a);
	}
}

#define canonical_add_magnitude(r, a, b) \
	THX_canonical_add_magnitude(aTHX_ r, a, b)
static void THX_canonical_add_magnitude(pTHX_ struct decimal *r,
	struct decimal *a, struct decimal *b)
{
	int carry;
	char *ap, *bp, *rp;
	STRLEN ali = a->int_end - a->int_start;
	STRLEN bli = b->int_end - b->int_start;
	STRLEN rli = 1 + (ali > bli ? ali : bli);
	STRLEN sli = ali < bli ? ali : bli;
	STRLEN alf = a->frac_end - a->frac_start;
	STRLEN blf = b->frac_end - b->frac_start;
	STRLEN rlf = alf > blf ? alf : blf;
	STRLEN slf = alf < blf ? alf : blf;
	SV *digstore = sv_2mortal(newSVpvs(""));
	r->int_start = SvGROW(digstore, rli+rlf+1);
	SvCUR_set(digstore, rli+rlf);
	r->frac_start = r->int_end = r->int_start + rli;
	rp = r->frac_end = r->frac_start + rlf;
	*rp = 0;
	ap = a->frac_end;
	bp = b->frac_end;
	if(alf < blf) {
		STRLEN xl = blf - alf;
		bp -= xl;
		rp -= xl;
		Copy(bp, rp, xl, char);
	} else if(alf > blf) {
		STRLEN xl = alf - blf;
		ap -= xl;
		rp -= xl;
		Copy(ap, rp, xl, char);
	}
	carry = 0;
	while(slf-- != 0) {
		char rc = *--ap + *--bp + carry - '0';
		carry = rc > '9';
		if(carry) rc -= 10;
		*--rp = rc;
	}
	rp = r->int_end;
	ap = a->int_end;
	bp = b->int_end;
	while(sli-- != 0) {
		char rc = *--ap + *--bp + carry - '0';
		carry = rc > '9';
		if(carry) rc -= 10;
		*--rp = rc;
	}
	if(ali > bli) {
		ali -= bli;
		while(ali-- != 0) {
			char rc = *--ap + carry;
			carry = rc > '9';
			if(carry) rc -= 10;
			*--rp = rc;
		}
	} else if(bli > ali) {
		bli -= ali;
		while(bli-- != 0) {
			char rc = *--bp + carry;
			carry = rc > '9';
			if(carry) rc -= 10;
			*--rp = rc;
		}
	}
	*--rp = '0' + carry;
}

#define canonical_sub_magnitude(r, a, b) \
	THX_canonical_sub_magnitude(aTHX_ r, a, b)
static void THX_canonical_sub_magnitude(pTHX_ struct decimal *r,
	struct decimal *a, struct decimal *b)
{
	int carry;
	char *ap, *bp, *rp;
	STRLEN ali = a->int_end - a->int_start;
	STRLEN bli = b->int_end - b->int_start;
	STRLEN rli = ali > bli ? ali : bli;
	STRLEN sli = ali < bli ? ali : bli;
	STRLEN alf = a->frac_end - a->frac_start;
	STRLEN blf = b->frac_end - b->frac_start;
	STRLEN rlf = alf > blf ? alf : blf;
	STRLEN slf = alf < blf ? alf : blf;
	SV *digstore = sv_2mortal(newSVpvs(""));
	r->int_start = SvGROW(digstore, rli+rlf+1);
	SvCUR_set(digstore, rli+rlf);
	r->frac_start = r->int_end = r->int_start + rli;
	rp = r->frac_end = r->frac_start + rlf;
	*rp = 0;
	ap = a->frac_end;
	bp = b->frac_end;
	carry = 0;
	if(alf < blf) {
		while(blf-- != alf) {
			*--rp = '0' - *--bp - carry + '0' + 10;
			carry = 1;
		}
	} else if(alf > blf) {
		STRLEN xl = alf - blf;
		ap -= xl;
		rp -= xl;
		Copy(ap, rp, xl, char);
	}
	while(slf-- != 0) {
		char rc = *--ap - *--bp - carry + '0';
		carry = rc < '0';
		if(carry) rc += 10;
		*--rp = rc;
	}
	rp = r->int_end;
	ap = a->int_end;
	bp = b->int_end;
	while(sli-- != 0) {
		char rc = *--ap - *--bp - carry + '0';
		carry = rc < '0';
		if(carry) rc += 10;
		*--rp = rc;
	}
	ali -= bli;
	while(ali-- != 0) {
		char rc = *--ap - carry;
		carry = rc < '0';
		if(carry) rc += 10;
		*--rp = rc;
	}
}

#define canonical_mul_value(r, a, b) THX_canonical_mul_value(aTHX_ r, a, b)
static void THX_canonical_mul_value(pTHX_ struct decimal *r,
	struct decimal *a, struct decimal *b)
{
	STRLEN ali = a->int_end - a->int_start;
	STRLEN bli = b->int_end - b->int_start;
	STRLEN alf = a->frac_end - a->frac_start;
	STRLEN blf = b->frac_end - b->frac_start;
	SV *digstore = sv_2mortal(newSVpvs(""));
	char *ds, *de, *bp;
	r->signum = a->signum == b->signum ? +1 : -1;
	r->int_start = ds = SvGROW(digstore, ali+bli+alf+blf+1);
	SvCUR_set(digstore, ali+bli+alf+blf);
	r->frac_start = r->int_end = ds + ali+bli;
	r->frac_end = de = ds + ali+bli+alf+blf;
	memset(ds, '0', de-ds);
	*de = 0;
	for(bp = b->frac_end; ; de--) {
		int bmul, carry;
		char *rp, *ap;
		if(bp == b->frac_start) bp = b->int_end;
		if(bp == b->int_start) break;
		bmul = *--bp - '0';
		if(bmul == 0) continue;
		rp = de;
		carry = 0;
		for(ap = a->frac_end; ; ) {
			int v;
			if(ap == a->frac_start) ap = a->int_end;
			if(ap == a->int_start) break;
			v = (*--ap - '0') * bmul + carry + (*--rp - '0');
			*rp = (v % 10) + '0';
			carry = v/10;
		}
		while(carry) {
			int v = carry + (*--rp - '0');
			*rp = (v % 10) + '0';
			carry = v/10;
		}
	}
}

MODULE = Math::Decimal PACKAGE = Math::Decimal

PROTOTYPES: DISABLE

BOOT:
	signum_sv[0] = newSVpvs("-1");
	signum_sv[1] = newSVpvs("0");
	signum_sv[2] = newSVpvs("1");
	{
		int i;
		for(i = 3; i--; ) {
			(void)SvIV(signum_sv[i]);
			SvREADONLY_on(signum_sv[i]);
		}
	}

bool
is_dec_number(SV *arg)
PROTOTYPE: $
PREINIT:
	STRLEN len;
	char *p, *end, c;
CODE:
	RETVAL = 0;
	if(!sv_is_string(arg)) goto out;
	p = SvPV(arg, len);
	end = p + len;
	c = *p;
	if(c == '+' || c == '-') c = *++p;
	if(c < '0' || c > '9') goto out;
	do {
		c = *++p;
	} while(c >= '0' && c <= '9');
	if(c == '.') {
		c = *++p;
		if(c < '0' || c > '9') goto out;
		do {
			c = *++p;
		} while(c >= '0' && c <= '9');
	}
	if(p != end) goto out;
	RETVAL = 1;
	out: ;
OUTPUT:
	RETVAL

void
check_dec_number(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
CODE:
	read_canonical(&a, a_sv);

SV *
dec_canonise(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
CODE:
	read_canonical(&a, a_sv);
	RETVAL = canonical_write(&a);
OUTPUT:
	RETVAL

SV *
dec_sgn(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
CODE:
	read_canonical(&a, a_sv);
	RETVAL = SvREFCNT_inc(signum_sv[1 + a.signum]);
OUTPUT:
	RETVAL

SV *
dec_abs(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
CODE:
	read_canonical(&a, a_sv);
	if(a.signum == -1) a.signum = +1;
	RETVAL = canonical_write(&a);
OUTPUT:
	RETVAL

SV *
dec_cmp(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
	int result;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	result = canonical_cmp_value(&a, &b);
	RETVAL = SvREFCNT_inc(signum_sv[1 + result]);
OUTPUT:
	RETVAL

SV *
dec_min(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	RETVAL = canonical_write(canonical_cmp_value(&a, &b) == -1 ? &a : &b);
OUTPUT:
	RETVAL

SV *
dec_max(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	RETVAL = canonical_write(canonical_cmp_value(&a, &b) == +1 ? &a : &b);
OUTPUT:
	RETVAL

SV *
dec_neg(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
CODE:
	read_canonical(&a, a_sv);
	a.signum = -a.signum;
	RETVAL = canonical_write(&a);
OUTPUT:
	RETVAL

SV *
dec_add(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	if(a.signum == 0) {
		RETVAL = canonical_write(&b);
	} else if(b.signum == 0) {
		RETVAL = canonical_write(&a);
	} else if(a.signum == b.signum) {
		/* same sign, add magnitudes */
		struct decimal r;
		r.signum = a.signum;
		canonical_add_magnitude(&r, &a, &b);
		identity_canonical(&r);
		RETVAL = canonical_write(&r);
	} else {
		/* different sign, subtract magnitudes */
		int cmp = canonical_cmp_magnitude(&a, &b);
		if(cmp == +1) {
			struct decimal r;
			r.signum = a.signum;
			canonical_sub_magnitude(&r, &a, &b);
			identity_canonical(&r);
			RETVAL = canonical_write(&r);
		} else if(cmp == -1) {
			struct decimal r;
			r.signum = b.signum;
			canonical_sub_magnitude(&r, &b, &a);
			identity_canonical(&r);
			RETVAL = canonical_write(&r);
		} else {
			RETVAL = newSVpvs("0");
		}
	}
OUTPUT:
	RETVAL

SV *
dec_sub(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	if(a.signum == 0) {
		b.signum = -b.signum;
		RETVAL = canonical_write(&b);
	} else if(b.signum == 0) {
		RETVAL = canonical_write(&a);
	} else if(a.signum != b.signum) {
		/* different sign, add magnitudes */
		struct decimal r;
		r.signum = a.signum;
		canonical_add_magnitude(&r, &a, &b);
		identity_canonical(&r);
		RETVAL = canonical_write(&r);
	} else {
		/* same sign, subtract magnitudes */
		int cmp = canonical_cmp_magnitude(&a, &b);
		if(cmp == +1) {
			struct decimal r;
			r.signum = a.signum;
			canonical_sub_magnitude(&r, &a, &b);
			identity_canonical(&r);
			RETVAL = canonical_write(&r);
		} else if(cmp == -1) {
			struct decimal r;
			r.signum = -b.signum;
			canonical_sub_magnitude(&r, &b, &a);
			identity_canonical(&r);
			RETVAL = canonical_write(&r);
		} else {
			RETVAL = newSVpvs("0");
		}
	}
OUTPUT:
	RETVAL

SV *
dec_pow10(SV *a_sv)
PROTOTYPE: $
PREINIT:
	struct decimal a;
	int expt;
	char *p;
CODE:
	read_canonical(&a, a_sv);
	expt = canonical_get_expt(&a);
	if(expt < 0) {
		RETVAL = newSVpvs("");
		p = SvGROW(RETVAL, (STRLEN)(3-expt));
		SvCUR_set(RETVAL, (STRLEN)(2-expt));
		p[0] = '0';
		p[1] = '.';
		memset(p+2, '0', -1-expt);
		p[1-expt] = '1';
		p[2-expt] = 0;
	} else {
		RETVAL = newSVpvs("");
		p = SvGROW(RETVAL, (STRLEN)(2+expt));
		SvCUR_set(RETVAL, (STRLEN)(1+expt));
		p[0] = '1';
		memset(p+1, '0', expt);
		p[1+expt] = 0;
	}
OUTPUT:
	RETVAL

SV *
dec_mul_pow10(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b;
	int expt;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	expt = canonical_get_expt(&b);
	if(a.signum == 0 || b.signum == 0) {
		RETVAL = canonical_write(&a);
	} else if(expt < 0) {
		struct decimal r;
		SV *digstore = sv_2mortal(newSVpvs(""));
		STRLEN ali = a.int_end - a.int_start;
		STRLEN alf = a.frac_end - a.frac_start;
		STRLEN lx = ali >= (STRLEN)-expt ? 0 : -expt - ali;
		char *p;
		p = SvGROW(digstore, lx+ali+alf+1);
		SvCUR_set(digstore, lx+ali+alf);
		memset(p, '0', lx);
		Copy(a.int_start, p+lx, ali, char);
		Copy(a.frac_start, p+lx+ali, alf, char);
		p[lx+ali+alf] = 0;
		r.signum = a.signum;
		r.int_start = p;
		r.frac_start = r.int_end = p+lx+ali+expt;
		r.frac_end = p+lx+ali+alf;
		identity_canonical(&r);
		RETVAL = canonical_write(&r);
	} else {
		struct decimal r;
		SV *digstore = sv_2mortal(newSVpvs(""));
		STRLEN ali = a.int_end - a.int_start;
		STRLEN alf = a.frac_end - a.frac_start;
		STRLEN lx = alf >= (STRLEN)expt ? 0 : expt - alf;
		char *p;
		p = SvGROW(digstore, ali+alf+lx+1);
		SvCUR_set(digstore, ali+alf+lx);
		Copy(a.int_start, p, ali, char);
		Copy(a.frac_start, p+ali, alf, char);
		memset(p+ali+alf, '0', lx);
		p[ali+alf+lx] = 0;
		r.signum = a.signum;
		r.int_start = p;
		r.frac_start = r.int_end = p+ali+expt;
		r.frac_end = p+ali+alf+lx;
		identity_canonical(&r);
		RETVAL = canonical_write(&r);
	}
OUTPUT:
	RETVAL

SV *
dec_mul(SV *a_sv, SV *b_sv)
PROTOTYPE: $$
PREINIT:
	struct decimal a, b, r;
CODE:
	read_canonical(&a, a_sv);
	read_canonical(&b, b_sv);
	canonical_mul_value(&r, &a, &b);
	identity_canonical(&r);
	RETVAL = canonical_write(&r);
OUTPUT:
	RETVAL
