#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

# ifdef __GNUC__
#   define GCC_V (10000*__GNUC__ + 100*__GNUC_MINOR__ + __GNUC_PATCHLEVEL__)

#   if GCC_V >= 40102
#     define HAVE_ATOMICS 1
#     define atomic_add(ptr, v) __sync_add_and_fetch((ptr), (v))
#     define atomic_sub(ptr, v) __sync_sub_and_fetch((ptr), (v))
#   endif
# endif

int main( int argc, char *arv[] ) {
# if GCC_V >= 40102
  IV i=-1;
  atomic_add(&i, 2);
  atomic_sub(&i, 1);
  return i;
# endif
  return ~0;
}
