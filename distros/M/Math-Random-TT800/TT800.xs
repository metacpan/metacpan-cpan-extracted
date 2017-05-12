#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#ifdef __cplusplus
}
#endif

#include "tt800.h"

MODULE = Math::Random::TT800		PACKAGE = Math::Random::TT800

TT800
new(class = "Math::Random::TT800", ...)
		char *		class
	CODE:
		{
		int i;

		RETVAL = (TT800) safemalloc(sizeof(struct tt800_state));
		memcpy(RETVAL,(char * ) &tt800_initial_state,
			sizeof(struct tt800_state));

		if ( items > (TT800_N + 1))
			items = TT800_N + 1;
		for (i = 1; i < items; i++)
			RETVAL->x[i-1] = (U32) SvIV(ST(i));
		}
	OUTPUT:
		RETVAL


void
DESTROY(tt)
		TT800	tt
	CODE:
		safefree((char *) tt);


U32
next_int(tt)
		TT800 tt
	CODE:
		RETVAL = tt800_get_next_int(tt);
	OUTPUT:
		RETVAL


double
next(tt)
		TT800 tt
	CODE:
		RETVAL = tt800_get_next_int(tt) * TT800_INV_MOD;
	OUTPUT:
		RETVAL

