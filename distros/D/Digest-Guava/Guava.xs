#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdint.h>
#include <stdio.h>

static const int64_t
	K   = 2862933555777941757L;

static const double
	D   = 0x1.0p31;

int32_t guava(int64_t state, int32_t buckets) {
	double next_double;
	int32_t candidate = 0;
	int32_t next;
	while (1) {
		state = K * state + 1;
		next_double = (double)( (int32_t)( (uint64_t) state >> 33 ) + 1 ) / D;
		next = (int32_t) ( (candidate + 1) / next_double );
		
		if ( ( next >= 0 ) && ( next < buckets ) ) {
			candidate = next;
		} else {
			return candidate;
		}
	}
}


MODULE = Digest::Guava		PACKAGE = Digest::Guava

SV*
guava_hash(state, buckets)
		long state;
		unsigned buckets;
	PROTOTYPE: $$
	CODE:
		int32_t res = guava(state, buckets);
		RETVAL = newSViv(res);
	OUTPUT:
		RETVAL
