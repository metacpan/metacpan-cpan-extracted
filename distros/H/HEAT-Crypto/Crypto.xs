#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "curve25519_i64.h"

typedef unsigned char BYTE;

static BYTE *S_get_key_buffer(SV *var, const char *name, bool null)
{
	STRLEN len;
	dTHX;
	if (!SvOK(var) && null) {
		return NULL;
	}
	if (!SvOK(var)) {
		croak("%s cannot be undefined", name);
	}
	BYTE* buff = (BYTE*) SvPV(var, len);
	if (len != 32) {
		croak("%s requires 32 bytes", name);
	}

	return buff;
}

MODULE = HEAT::Crypto	PACKAGE = HEAT::Crypto

PROTOTYPES: DISABLED

void _clamp(key)
	CODE:
	BYTE *key = S_get_key_buffer(ST(0), "key", false);
	clamp25519(key);

void _core(p, s, k, g)
	CODE:
	BYTE *p = S_get_key_buffer(ST(0), "p", false);
	BYTE *s = S_get_key_buffer(ST(1), "s", true);
	BYTE *k = S_get_key_buffer(ST(2), "k", false);
	BYTE *g = S_get_key_buffer(ST(3), "g", true);
	core25519(p, s, k, g);

int _sign(v, h, x, s)
	CODE:
	BYTE *v = S_get_key_buffer(ST(0), "v", false);
	BYTE *h = S_get_key_buffer(ST(1), "h", false);
	BYTE *x = S_get_key_buffer(ST(2), "x", false);
	BYTE *s = S_get_key_buffer(ST(3), "s", false);
	RETVAL = sign25519(v, h, x, s);
	OUTPUT:
	RETVAL

void _verify(y, v, h, p)
	CODE:
	BYTE *y = S_get_key_buffer(ST(0), "y", false);
	BYTE *v = S_get_key_buffer(ST(1), "v", false);
	BYTE *h = S_get_key_buffer(ST(2), "h", false);
	BYTE *p = S_get_key_buffer(ST(3), "p", false);
	verify25519(y, v, h, p);
