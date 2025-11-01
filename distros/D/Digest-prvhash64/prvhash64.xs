#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>
#include <string.h>

/* Adjust include path via Makefile.PL INC or place headers next to this XS */
#include "prvhash64.h"

MODULE = Digest::prvhash64    PACKAGE = Digest::prvhash64

SV* prvhash64(msg_sv, hash_len, seed=0)
	SV* msg_sv
	size_t hash_len
	UV seed
CODE:
{
	STRLEN msg_len = 0;
	const void* msg = (const void*)SvPVbyte(msg_sv, msg_len);
	if (hash_len == 0 || (hash_len % sizeof(uint64_t)) != 0) {
		croak("hash_len must be a positive multiple of 8");
	}
	SV* out = newSV(hash_len);
	SvPOK_only(out);
	SvCUR_set(out, hash_len);
	char* buf = SvPVX(out);
	prvhash64(msg, (size_t)msg_len, (void*)buf, (size_t)hash_len, (uint64_t)seed);
	RETVAL = out;
}
OUTPUT:
	RETVAL

UV prvhash64_64m(msg_sv, seed=0)
	SV* msg_sv
	UV seed
CODE:
{
	STRLEN msg_len = 0;
	const void* msg = (const void*)SvPVbyte(msg_sv, msg_len);
	uint64_t hv = prvhash64_64m(msg, (size_t)msg_len, (uint64_t)seed);
	RETVAL = (UV)hv;
}
OUTPUT:
	RETVAL
