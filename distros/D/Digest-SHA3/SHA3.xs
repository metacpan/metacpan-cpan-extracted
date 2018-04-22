#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef SvPVbyte
	#if PERL_REVISION == 5 && PERL_VERSION < 8
		#undef SvPVbyte
		#define SvPVbyte(sv, lp) \
			(sv_utf8_downgrade((sv), 0), SvPV((sv), (lp)))
	#endif
#else
	#define SvPVbyte SvPV
#endif

#ifndef dTHX
	#define pTHX_
	#define aTHX_
#endif

#ifndef PerlIO
	#define PerlIO				FILE
	#define PerlIO_read(f, buf, count)	fread(buf, 1, count, f)
#endif

#ifndef sv_derived_from
	#include "src/sdf.c"
#endif

#ifndef Newx
	#define Newx(ptr, num, type)	New(0, ptr, num, type)
	#define Newxz(ptr, num, type)	Newz(0, ptr, num, type)
#endif

#include "src/sha3.c"

static const int ix2alg[] =
	{224,224,224,256,256,256,384,384,384,512,512,512,
	 128000,128000,128000,256000,256000,256000};

#ifndef INT2PTR
#define INT2PTR(p, i) (p) (i)
#endif

#define MAX_WRITE_SIZE 16384
#define IO_BUFFER_SIZE 4096

static SHA3 *getSHA3(pTHX_ SV *self)
{
	if (!sv_isobject(self) || !sv_derived_from(self, "Digest::SHA3"))
		return(NULL);
	return INT2PTR(SHA3 *, SvIV(SvRV(self)));
}

MODULE = Digest::SHA3		PACKAGE = Digest::SHA3

PROTOTYPES: ENABLE

int
shainit(s, alg)
	SHA3 *	s
	int	alg

void
sharewind(s)
	SHA3 *	s

unsigned long
shawrite(bitstr, bitcnt, s)
	unsigned char *	bitstr
	unsigned long	bitcnt
	SHA3 *	s

SV *
newSHA3(classname, alg)
	char *	classname
	int 	alg
PREINIT:
	SHA3 *state;
CODE:
	Newxz(state, 1, SHA3);
	if (!shainit(state, alg)) {
		Safefree(state);
		XSRETURN_UNDEF;
	}
	RETVAL = newSV(0);
	sv_setref_pv(RETVAL, classname, (void *) state);
	SvREADONLY_on(SvRV(RETVAL));
OUTPUT:
	RETVAL

SV *
clone(self)
	SV *	self
PREINIT:
	SHA3 *state;
	SHA3 *clone;
CODE:
	if ((state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	Newx(clone, 1, SHA3);
	RETVAL = newSV(0);
	sv_setref_pv(RETVAL, sv_reftype(SvRV(self), 1), (void *) clone);
	SvREADONLY_on(SvRV(RETVAL));
	Copy(state, clone, 1, SHA3);
OUTPUT:
	RETVAL

void
DESTROY(s)
	SHA3 *	s
CODE:
	Safefree(s);

SV *
sha3_224(...)
ALIAS:
	Digest::SHA3::sha3_224 = 0
	Digest::SHA3::sha3_224_hex = 1
	Digest::SHA3::sha3_224_base64 = 2
	Digest::SHA3::sha3_256 = 3
	Digest::SHA3::sha3_256_hex = 4
	Digest::SHA3::sha3_256_base64 = 5
	Digest::SHA3::sha3_384 = 6
	Digest::SHA3::sha3_384_hex = 7
	Digest::SHA3::sha3_384_base64 = 8
	Digest::SHA3::sha3_512 = 9
	Digest::SHA3::sha3_512_hex = 10
	Digest::SHA3::sha3_512_base64 = 11
	Digest::SHA3::shake128 = 12
	Digest::SHA3::shake128_hex = 13
	Digest::SHA3::shake128_base64 = 14
	Digest::SHA3::shake256 = 15
	Digest::SHA3::shake256_hex = 16
	Digest::SHA3::shake256_base64 = 17
PREINIT:
	int i;
	UCHR *data;
	STRLEN len;
	SHA3 sha3;
	char *result;
CODE:
	if (!shainit(&sha3, ix2alg[ix]))
		XSRETURN_UNDEF;
	for (i = 0; i < items; i++) {
		data = (UCHR *) (SvPVbyte(ST(i), len));
		while (len > MAX_WRITE_SIZE) {
			shawrite(data, MAX_WRITE_SIZE << 3, &sha3);
			data += MAX_WRITE_SIZE;
			len  -= MAX_WRITE_SIZE;
		}
		shawrite(data, (ULNG) len << 3, &sha3);
	}
	shafinish(&sha3);
	len = 0;
	if (ix % 3 == 0) {
		result = (char *) shadigest(&sha3);
		len = (STRLEN) sha3.digestlen;
	}
	else if (ix % 3 == 1)
		result = shahex(&sha3);
	else
		result = shabase64(&sha3);
	RETVAL = newSVpv(result, len);
OUTPUT:
	RETVAL

int
hashsize(self)
	SV *	self
ALIAS:
	Digest::SHA3::hashsize = 0
	Digest::SHA3::algorithm = 1
PREINIT:
	SHA3 *state;
CODE:
	if ((state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	RETVAL = ix ? state->alg : state->digestlen << 3;
OUTPUT:
	RETVAL

void
add(self, ...)
	SV *	self
PREINIT:
	int i;
	UCHR *data;
	STRLEN len;
	SHA3 *state;
PPCODE:
	if ((state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	for (i = 1; i < items; i++) {
		data = (UCHR *) (SvPVbyte(ST(i), len));
		while (len > MAX_WRITE_SIZE) {
			shawrite(data, MAX_WRITE_SIZE << 3, state);
			data += MAX_WRITE_SIZE;
			len  -= MAX_WRITE_SIZE;
		}
		shawrite(data, (ULNG) len << 3, state);
	}
	XSRETURN(1);

SV *
digest(self)
	SV *	self
ALIAS:
	Digest::SHA3::digest = 0
	Digest::SHA3::hexdigest = 1
	Digest::SHA3::b64digest = 2
	Digest::SHA3::squeeze = 3
PREINIT:
	STRLEN len;
	SHA3 *state;
	char *result;
CODE:
	if ((state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	shafinish(state);
	len = 0;
	if (ix == 0) {
		result = (char *) shadigest(state);
		len = (STRLEN) state->digestlen;
	}
	else if (ix == 1)
		result = shahex(state);
	else if (ix == 2)
		result = shabase64(state);
	else {
		if ((result = (char *) shasqueeze(state)) == NULL)
			XSRETURN_UNDEF;
		len = (STRLEN) state->digestlen;
	}
	RETVAL = newSVpv(result, len);
	if (ix != 3)
		sharewind(state);
OUTPUT:
	RETVAL

void
_addfilebin(self, f)
	SV *		self
	PerlIO *	f
PREINIT:
	SHA3 *state;
	int n;
	UCHR in[IO_BUFFER_SIZE];
PPCODE:
	if (!f || (state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	while ((n = (int) PerlIO_read(f, in, sizeof(in))) > 0)
		shawrite(in, (ULNG) n << 3, state);
	XSRETURN(1);

void
_addfileuniv(self, f)
	SV *		self
	PerlIO *	f
PREINIT:
	UCHR c;
	int n;
	int cr = 0;
	UCHR *src, *dst;
	UCHR in[IO_BUFFER_SIZE+1];
	SHA3 *state;
PPCODE:
	if (!f || (state = getSHA3(aTHX_ self)) == NULL)
		XSRETURN_UNDEF;
	while ((n = (int) PerlIO_read(f, in+1, IO_BUFFER_SIZE)) > 0) {
		for (dst = in, src = in + 1; n; n--) {
			c = *src++;
			if (!cr) {
				if (c == '\015')
					cr = 1;
				else
					*dst++ = c;
			}
			else {
				if (c == '\015')
					*dst++ = '\012';
				else if (c == '\012') {
					*dst++ = '\012';
					cr = 0;
				}
				else {
					*dst++ = '\012';
					*dst++ = c;
					cr = 0;
				}
			}
		}
		shawrite(in, (ULNG) (dst - in) << 3, state);
	}
	if (cr) {
		in[0] = '\012';
		shawrite(in, 1UL << 3, state);
	}
	XSRETURN(1);
