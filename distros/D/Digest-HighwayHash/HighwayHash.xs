#define PERL_NO_GET_CONTEXT
#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perl_math_int64.h"
#include "ppport.h"

#include "highwayhash.c"

void process_key(pTHX_ AV *key_av, uint64_t *key) {
	int i;
	SV *elt;

	if(av_len(key_av) + 1 != 4)
		croak("Key for highway_hash must be a 4-element array");
	for(i = 0 ; i < 4 ; i++) {
		elt = *av_fetch(key_av, i, false);
		if(SvU64OK(elt))
			key[i] = SvU64(elt);
		else
			key[i] = SvUV(elt);
	}
}

uint64_t highway_hash64(AV *key_av, unsigned char *bytes, uint64_t size) {
	dTHX;
	uint64_t key[4];
	process_key(aTHX_ key_av, key);
	return HighwayHash64(bytes, size, key);
}

AV* highway_hash128(AV *key_av, unsigned char *bytes, uint64_t size) {
	dTHX;
	AV* result;
	uint64_t key[4];
	uint64_t hash[2];
	process_key(aTHX_ key_av, key);
	HighwayHash128(bytes, size, key, hash);
	result = newAV();
	av_push(result, sv_2mortal(newSVu64(hash[0])));
	av_push(result, sv_2mortal(newSVu64(hash[1])));
	return result;
}

AV* highway_hash256(AV *key_av, unsigned char *bytes, uint64_t size) {
	dTHX;
	AV* result;
	uint64_t key[4];
	uint64_t hash[4];
	process_key(aTHX_ key_av, key);
	HighwayHash256(bytes, size, key, hash);
	result = newAV();
	av_push(result, sv_2mortal(newSVu64(hash[0])));
	av_push(result, sv_2mortal(newSVu64(hash[1])));
	av_push(result, sv_2mortal(newSVu64(hash[2])));
	av_push(result, sv_2mortal(newSVu64(hash[3])));
	return result;
}

MODULE = Digest::HighwayHash		PACKAGE = Digest::HighwayHash
PROTOTYPES: DISABLE
BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;

uint64_t highway_hash64(AV *key_av, unsigned char *bytes, uint64_t length(bytes))

AV* highway_hash128(AV *key_av, unsigned char *bytes, uint64_t length(bytes))

AV* highway_hash256(AV *key_av, unsigned char *bytes, uint64_t length(bytes))
