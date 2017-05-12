#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* C functions */
int
use_var_len_array(int size)
{
	int array[size];
	int i;

	for(i=0; i< size; ++i) {
		array[i] = (i*2)+1;
	}

	return array[size/2];
}

MODULE = Devel::CCompat::C99::VariableLengthArrays	PACKAGE = Devel::CCompat::C99::VariableLengthArrays
PROTOTYPES: DISABLE

# XS code

int
create_array(int size)
  CODE:
    if(size <= 0) {
        croak("size must be positive\n");
    }
    RETVAL = use_var_len_array(size);
  OUTPUT: RETVAL

