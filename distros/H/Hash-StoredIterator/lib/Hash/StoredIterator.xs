#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../../ppport.h"

/* These were stolen from http://cpansearch.perl.org/src/AMS/Storable-2.30/Storable.xs */

#ifndef HvRITER_set
#  define HvRITER_set(hv,r) (HvRITER(hv) = r)
#endif
#ifndef HvEITER_set
#  define HvEITER_set(hv,r) (HvEITER(hv) = r)
#endif

#ifndef HvRITER_get
#  define HvRITER_get HvRITER
#endif
#ifndef HvEITER_get
#  define HvEITER_get HvEITER
#endif

/* end theft */

typedef struct {
    HE *eiter;
    I32 riter;
} hsi;

MODULE = Hash::StoredIterator PACKAGE = Hash::StoredIterator

TYPEMAP: <<EOT
hsi * T_PTR
EOT

hsi *hash_get_iterator( hv )
        HV  *hv
    CODE:
        Newx( RETVAL, 1, hsi );
        RETVAL->riter = HvRITER_get(hv);
        RETVAL->eiter = HvEITER_get(hv);
    OUTPUT:
        RETVAL

void hash_set_iterator( hv, itr )
        HV  *hv
        hsi *itr
    CODE:
        HvRITER_set(hv, itr->riter);
        HvEITER_set(hv, itr->eiter);

void hash_init_iterator( hv )
        HV *hv
    CODE:
        hv_iterinit(hv);
