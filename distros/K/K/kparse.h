#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* sv_from_k(K);
SV* scalar_from_k(K);
SV* vector_from_k(K);
SV* xd_from_k(K);
SV* ptable_from_k(K);
SV* dict_from_k(K);
SV* table_from_k(K);
SV* mixed_list_from_k(K);

SV* bool_from_k(K);
SV* byte_from_k(K);
SV* char_from_k(K);
SV* short_from_k(K);
SV* int_from_k(K);
SV* long_from_k(K);
SV* timestamp_from_k(K);
SV* real_from_k(K);
SV* float_from_k(K);
SV* symbol_from_k(K);
SV* scalar_from_k(K);

SV* bool_vector_from_k(K);
SV* char_vector_from_k(K);
SV* byte_vector_from_k(K);
SV* short_vector_from_k(K);
SV* int_vector_from_k(K);
SV* long_vector_from_k(K);
SV* timestamp_vector_from_k(K);
SV* real_vector_from_k(K);
SV* float_vector_from_k(K);
SV* symbol_vector_from_k(K);
