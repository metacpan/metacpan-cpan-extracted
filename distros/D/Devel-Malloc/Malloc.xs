#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <stdint.h>

MODULE = Devel::Malloc    PACKAGE = Devel::Malloc   PREFIX = smh

IV
smh_malloc(size)
    size_t size;

    PROTOTYPE: DISABLE

    CODE:
    RETVAL = PTR2IV(safemalloc(size));

    OUTPUT:
    RETVAL

void
smh_free(address)
    IV address;

    PROTOTYPE: DISABLE

    CODE:
    safefree(INT2PTR(void *, address));

    OUTPUT:

IV
smh_memset(address, src, size = 0)
    IV address;
    SV * src;
    STRLEN size;

    PROTOTYPE: DISABLE

    CODE:
    char * ptr = (size == 0) ? SvPVbyte(src, size) : SvPVbyte_nolen(src);
    RETVAL = PTR2IV(memcpy(INT2PTR(void *, address), ptr, size));

    OUTPUT:
    RETVAL

SV *
smh_memget(address, size)
    IV address;
    STRLEN size;

    PROTOTYPE: DISABLE

    CODE:
    RETVAL = newSVpv("",0); 
    SvGROW(RETVAL, size);
    memcpy(SvPVbyte_nolen(RETVAL), INT2PTR(void *, address), size);
    SvCUR_set(RETVAL, size);

    OUTPUT:
    RETVAL

SV *
smh__sync_load_sv(address, size)
    IV address;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    if ((size < 1) || (size > 8)) XSRETURN_UNDEF;
    
    STRLEN len = size;
    if (size == 3) len = 4;
    if ((size >= 5) && (size <= 7)) len = 8;
    
    RETVAL = newSVpv("",0); 
    SvGROW(RETVAL, len);
    switch (len)
    {
	case 1: *(uint8_t*)SvPVbyte_nolen(RETVAL) = __sync_fetch_and_add(INT2PTR(uint8_t *, address), 0); break;
	case 2: *(uint16_t*)SvPVbyte_nolen(RETVAL) = __sync_fetch_and_add(INT2PTR(uint16_t *, address), 0); break;
	case 4: *(uint32_t*)SvPVbyte_nolen(RETVAL) = __sync_fetch_and_add(INT2PTR(uint32_t *, address), 0); break;
	case 8: *(uint64_t*)SvPVbyte_nolen(RETVAL) = __sync_fetch_and_add(INT2PTR(uint64_t *, address), 0); break;
    }
    SvCUR_set(RETVAL, size);
    
    OUTPUT:
    RETVAL

void
smh__sync_store_sv(address, value, size = 0)
    IV address;
    SV * value;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    if (size > 8) XSRETURN_UNDEF;

    STRLEN len;
    char * ptr = SvPVbyte(value, len);
    if (size == 0) size = len;
    if (size == 3) size = 4;
    if ((size >= 5) && (size <= 7)) size = 8;
    if (len < size)
    {
	SvGROW(value, size);
	ptr = SvPVbyte_nolen(value);
    }
    switch (size)
    {
	case 1: __sync_lock_test_and_set(INT2PTR(uint8_t *, address), *(uint8_t*)ptr);
		break;
	case 2: __sync_lock_test_and_set(INT2PTR(uint16_t *, address), *(uint16_t*)ptr);
		break;
	case 4: __sync_lock_test_and_set(INT2PTR(uint32_t *, address), *(uint32_t*)ptr);
		break;
	case 8: __sync_lock_test_and_set(INT2PTR(uint64_t *, address), *(uint64_t*)ptr);
		break;
	default: XSRETURN_UNDEF;
    }
                               
    OUTPUT:

IV
smh__sync_lock_test_and_set(address, value, size)
    IV address;
    IV value;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_lock_test_and_set(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_lock_test_and_set(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_lock_test_and_set(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_lock_test_and_set(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

void
smh__sync_lock_release(address, size)
    IV address;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: __sync_lock_release(INT2PTR(uint8_t *, address)); break;
        case 2: __sync_lock_release(INT2PTR(uint16_t *, address)); break;
        case 4: __sync_lock_release(INT2PTR(uint32_t *, address)); break;
	case 8: __sync_lock_release(INT2PTR(uint64_t *, address)); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:

void
smh__sync_synchronize()

    PROTOTYPE: DISABLE
    
    CODE:
    __sync_synchronize();
    
    OUTPUT:
    
bool
smh__sync_bool_compare_and_swap(address, oldval, newval, size)
    IV address;
    IV oldval;
    IV newval;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = __sync_bool_compare_and_swap(INT2PTR(uint8_t *, address), oldval, newval); break;
        case 2: RETVAL = __sync_bool_compare_and_swap(INT2PTR(uint16_t *, address), oldval, newval); break;
        case 4: RETVAL = __sync_bool_compare_and_swap(INT2PTR(uint32_t *, address), oldval, newval); break;
	case 8: RETVAL = __sync_bool_compare_and_swap(INT2PTR(uint64_t *, address), oldval, newval); break;
	default: XSRETURN_UNDEF;
    }
    
    OUTPUT:
    RETVAL

IV    
smh__sync_val_compare_and_swap(address, oldval, newval, size)
    IV address;
    IV oldval;
    IV newval;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_val_compare_and_swap(INT2PTR(uint8_t *, address), oldval, newval); break;
        case 2: RETVAL = (uint16_t) __sync_val_compare_and_swap(INT2PTR(uint16_t *, address), oldval, newval); break;
        case 4: RETVAL = (uint32_t) __sync_val_compare_and_swap(INT2PTR(uint32_t *, address), oldval, newval); break;
	case 8: RETVAL = (uint64_t) __sync_val_compare_and_swap(INT2PTR(uint64_t *, address), oldval, newval); break;
	default: XSRETURN_UNDEF;
    }
    
    OUTPUT:
    RETVAL

IV
smh__sync_nand_and_fetch(address, value, size)
    IV address;
    IV value;
    UV size;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_nand_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_nand_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_nand_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_nand_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

IV
smh__sync_xor_and_fetch(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_xor_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_xor_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_xor_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_xor_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

IV
smh__sync_or_and_fetch(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_or_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_or_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_or_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_or_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

IV
smh__sync_and_and_fetch(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_and_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_and_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_and_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_and_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

IV
smh__sync_sub_and_fetch(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_sub_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_sub_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_sub_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_sub_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
IV
smh__sync_add_and_fetch(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_add_and_fetch(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_add_and_fetch(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_add_and_fetch(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_add_and_fetch(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
IV
smh__sync_fetch_and_nand(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_nand(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_nand(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_nand(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_nand(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
IV
smh__sync_fetch_and_xor(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_xor(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_xor(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_xor(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_xor(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
IV
smh__sync_fetch_and_or(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_or(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_or(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_or(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_or(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    

IV
smh__sync_fetch_and_and(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_and(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_and(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_and(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_and(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

IV
smh__sync_fetch_and_sub(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_sub(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_sub(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_sub(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_sub(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL
    
IV
smh__sync_fetch_and_add(address, value, size)
    IV address;
    UV size;
    IV value;
    
    PROTOTYPE: DISABLE
    
    CODE:
    switch (size)
    {
        case 1: RETVAL = (uint8_t) __sync_fetch_and_add(INT2PTR(uint8_t *, address), value); break;
        case 2: RETVAL = (uint16_t) __sync_fetch_and_add(INT2PTR(uint16_t *, address), value); break;
        case 4: RETVAL = (uint32_t) __sync_fetch_and_add(INT2PTR(uint32_t *, address), value); break;
	case 8: RETVAL = (uint64_t) __sync_fetch_and_add(INT2PTR(uint64_t *, address), value); break;
	default: XSRETURN_UNDEF;
    }

    OUTPUT:
    RETVAL

