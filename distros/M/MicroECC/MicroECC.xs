#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perlmulticore.h"

#include "ppport.h"
#include "uECC.h"
#include "uECC.c"
#include "get_curve.c"

MODULE = MicroECC		PACKAGE = MicroECC		

TYPEMAP: <<END
const char *    T_PV
const uint8_t *    T_PV
uint8_t * T_PV
END

int
curve_public_key_size(int curve_id)
	CODE:
		RETVAL = uECC_curve_public_key_size(get_curve(curve_id));
	OUTPUT:
		RETVAL

int
curve_private_key_size(int curve_id)
	CODE:
		RETVAL = uECC_curve_private_key_size(get_curve(curve_id));
	OUTPUT:
		RETVAL

void 
make_key(int curve_id)
	INIT:
		int pubkey_len, privkey_len;
		uint8_t *pubkey, *privkey;
		uECC_Curve curve;
		int res;

	PPCODE:
		curve = get_curve(curve_id);
		pubkey_len  = uECC_curve_public_key_size(curve);
		privkey_len = uECC_curve_private_key_size(curve);
		pubkey  = (uint8_t *)malloc(pubkey_len);
		privkey = (uint8_t *)malloc(privkey_len);

		res = uECC_make_key(pubkey, privkey, curve);
		if(res) {
			XPUSHs(sv_2mortal(newSVpv(pubkey,  pubkey_len)));
			XPUSHs(sv_2mortal(newSVpv(privkey, privkey_len)));
		}
		else {
			XPUSHs(sv_2mortal(newSVnv(errno)));
		}
		free(pubkey);
		free(privkey);

int
valid_public_key(const uint8_t *pubkey, int curve_id)
	CODE:
		RETVAL = uECC_valid_public_key(pubkey, get_curve(curve_id));
	OUTPUT:
		RETVAL

SV * 
shared_secret(const uint8_t *pubkey, const uint8_t *privkey, int curve_id)
	CODE:
		uint8_t *secret;
		int secret_size;
		SV *d;
		int ret;

		uECC_Curve curve = get_curve(curve_id);

		secret_size = uECC_curve_public_key_size(curve) / 2;
		secret = (uint8_t *)malloc(secret_size);

		ret = uECC_shared_secret(pubkey, privkey, secret, curve);
		if(ret) {
			d = newSVpv(secret, 32);
		}
		else {
			d = sv_newmortal();
		}
		free(secret);
		RETVAL = d;
	OUTPUT:
		RETVAL

SV *
compute_public_key(const uint8_t *private_key, int curve_id)
	CODE:
		int public_key_size = uECC_curve_public_key_size(get_curve(curve_id));
		uint8_t *public_key = (uint8_t *)malloc(public_key_size);
		int res = uECC_compute_public_key(private_key, public_key, get_curve(curve_id));
		SV *d;
		if(res) {
			d = newSVpv(public_key, public_key_size);
		}
		else {
			d = sv_newmortal();
		}
		free(public_key);
		RETVAL = d;
	OUTPUT:
		RETVAL


SV *
sign(SV *sv_private_key, SV *sv_hash, int curve_id)
	CODE:
		STRLEN hash_size, key_size;
		char *hash = (char *)SvPVbyte(sv_hash, hash_size);
		char *private_key = (char *)SvPVbyte(sv_private_key, key_size);
		int public_key_size = uECC_curve_public_key_size(get_curve(curve_id));
		//printf("key size: %d, hash size: %d\n", key_size, hash_size);

		uint8_t *signature = (uint8_t *)malloc(public_key_size);
		int res = uECC_sign(private_key, hash, hash_size, signature, get_curve(curve_id));
		SV* d;
		if(res) {
			d = newSVpv(signature, public_key_size);
		}
		else {
			d = sv_newmortal();
		}
		free(signature);
		RETVAL = d;
	OUTPUT:
		RETVAL

int
verify(SV *sv_public_key, SV *sv_hash, SV *sv_signature, int curve_id)
	CODE:
		STRLEN hash_size, public_key_size, signature_size;
		char *hash = (char *)SvPVbyte(sv_hash, hash_size);
		char *public_key = (char *)SvPVbyte(sv_public_key, public_key_size);
		char *signature = (char *)SvPVbyte(sv_signature, signature_size);

		RETVAL = uECC_verify(public_key, hash, hash_size, signature, get_curve(curve_id));
	OUTPUT:
		RETVAL
