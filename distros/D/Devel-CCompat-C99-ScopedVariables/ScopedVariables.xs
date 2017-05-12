#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* C functions */
int
use_scoped_variable(int size)
{
	if (size < 1) {
		size = -size;
	}

	int x = 0;
	for(int i=0; i< size; ++i) {
		x += i;
	}

	return x;
}

MODULE = Devel::CCompat::C99::ScopedVariables	PACKAGE = Devel::CCompat::C99::ScopedVariables
PROTOTYPES: DISABLE

# XS code

int
create_scoped_variable(int size)
  CODE:
    if(size <= 0) {
        croak("size must be positive\n");
    }
    RETVAL = use_scoped_variable(size);
  OUTPUT: RETVAL

