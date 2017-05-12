package KinoSearch1::Util::BitVector;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::CClass );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params
        capacity => 0,
    );
}

1;

__END__

__XS__

MODULE = KinoSearch1    PACKAGE = KinoSearch1::Util::BitVector

void
new(either_sv, ...)
    SV        *either_sv;
PREINIT:
    const char *class;
    HV         *args_hash;
    U32         capacity;
    BitVector  *bit_vec;
PPCODE:
    /* determine the class */
    class = sv_isobject(either_sv) 
        ? sv_reftype(either_sv, 0) 
        : SvPV_nolen(either_sv);

    /* process hash-style params */
    Kino1_Verify_build_args_hash(args_hash, 
        "KinoSearch1::Util::BitVector::instance_vars", 1);
    capacity = (U32)SvUV( Kino1_Verify_extract_arg(args_hash, "capacity", 8) );

    /* build object */
    bit_vec = Kino1_BitVec_new(capacity);
    ST(0)   = sv_newmortal();
    sv_setref_pv(ST(0), class, (void*)bit_vec);
    XSRETURN(1);


=for comment
Return true if the bit indcated by $num has been set, false if it hasn't
(regardless of whether $num lies within the bounds of the object's capacity).

=cut

bool
get(bit_vec, num)
    BitVector *bit_vec;
    U32        num;
CODE:
    RETVAL = Kino1_BitVec_get(bit_vec, num);
OUTPUT: RETVAL

=for comment
Set the bit at $num to 1.

=cut

void
set(bit_vec, ...)
    BitVector *bit_vec;
PREINIT:
    U32 i, num;
PPCODE:
    for (i = 1; i < items; i++) {
        num = (U32)( SvUV( ST(i) ) );
        Kino1_BitVec_set(bit_vec, num);
    }

=for comment
Clear the bit at $num (i.e. set it to 0).

=cut

void
clear(bit_vec, num)
    BitVector *bit_vec;
    U32        num;
PPCODE:
    Kino1_BitVec_clear(bit_vec, num);

=for comment
Set all the bits bounded by $first and $last, inclusive, to 1.

=cut

void
bulk_set(bit_vec, first, last)
    BitVector *bit_vec;
    U32        first;
    U32        last;
PPCODE:
    Kino1_BitVec_bulk_set(bit_vec, first, last);
    
=for comment
Clear all the bits bounded by $first and $last, inclusive.

=cut

void
bulk_clear(bit_vec, first, last)
    BitVector *bit_vec;
    U32        first;
    U32        last;
PPCODE:
    Kino1_BitVec_bulk_clear(bit_vec, first, last);

=for comment
Given $num, return either $num (if it is set), the next set bit above it, or
if no such bit exists, undef (from Perl) or a sentinel (0xFFFFFFFF) from C.

=cut
    
SV*
next_set_bit(bit_vec, num)
    BitVector *bit_vec;
    U32        num;
CODE:
    num    = Kino1_BitVec_next_set_bit(bit_vec, num);
    RETVAL = num == KINO_BITVEC_SENTINEL ? &PL_sv_undef : newSVuv(num);
OUTPUT: RETVAL

=for comment
Given $num, return $num (if it is clear), or the next clear bit above it.
The highest number that next_clear_bit can return is the object's capacity.

=cut

SV*
next_clear_bit(bit_vec, num)
    BitVector *bit_vec;
    U32        num;
CODE:
    num = Kino1_BitVec_next_clear_bit(bit_vec, num);
    RETVAL = num == KINO_BITVEC_SENTINEL ? &PL_sv_undef : newSVuv(num);
OUTPUT: RETVAL

=for comment
Modify the BitVector so that only bits which remain set are those which 1)
were already set in this BitVector, and 2) were also set in the other
BitVector.

=cut

void
logical_and(bit_vec, other)
    BitVector *bit_vec;
    BitVector *other;
PPCODE:
    Kino1_BitVec_logical_and(bit_vec, other);


=for comment
Return a count of the number of set bits in the BitVector.

=cut

U32
count(bit_vec)
    BitVector *bit_vec;
CODE:
    RETVAL = Kino1_BitVec_count(bit_vec);
OUTPUT: RETVAL


=for comment
Return an arrayref of the with each element the number of a set bit.

=cut

void
to_arrayref(bit_vec)
    BitVector *bit_vec;
PREINIT:
    AV *out_av;
PPCODE:
    out_av = Kino1_BitVec_to_array(bit_vec);
    XPUSHs( sv_2mortal(newRV_noinc( (SV*)out_av )) );
    XSRETURN(1);
    

=for comment
Setters and getters.  A quirk: set_bits automatically adjusts capacity
upwards to the appropriate multiple of 8 if necessary.

=cut

SV* 
_set_or_get(bit_vec, ...)
    BitVector *bit_vec;
ALIAS:
    set_capacity = 1
    get_capacity = 2
    set_bits     = 3
    get_bits     = 4
PREINIT:
    STRLEN  len;
    U32     new_capacity;
    char   *new_bits;
CODE:
{
    KINO_START_SET_OR_GET_SWITCH

    case 1:  new_capacity = SvUV(ST(1));
             if (new_capacity < bit_vec->capacity) {
                 Kino1_BitVec_shrink(bit_vec, new_capacity);
             }
             else if (new_capacity > bit_vec->capacity) {
                 Kino1_BitVec_grow(bit_vec, new_capacity);
             }
             /* fall through */
    case 2:  RETVAL = newSVuv(bit_vec->capacity);
             break;

    case 3:  Kino1_Safefree(bit_vec->bits);
             new_bits          = SvPV(ST(1), len);
             bit_vec->bits     = (unsigned char*)Kino1_savepvn(new_bits, len);
             bit_vec->capacity = len << 3;
             /* fall through */
    case 4:  len = ceil(bit_vec->capacity / 8.0);
             RETVAL = newSVpv((char*)bit_vec->bits, len);
             break;

    KINO_END_SET_OR_GET_SWITCH
}
OUTPUT: RETVAL


void
DESTROY(bit_vec)
    BitVector *bit_vec;
PPCODE:
    Kino1_BitVec_destroy(bit_vec);


__H__

#ifndef H_KINO_BIT_VECTOR
#define H_KINO_BIT_VECTOR 1

#include "limits.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilMathUtils.h"
#include "KinoSearch1UtilCarp.h"
#include "KinoSearch1UtilMemManager.h"

#define KINO_BITVEC_SENTINEL 0xFFFFFFFF

typedef struct bitvector {
    U32            capacity;
    unsigned char *bits;
} BitVector;

BitVector* Kino1_BitVec_new(U32);
BitVector* Kino1_BitVec_clone(BitVector*);
void Kino1_BitVec_grow(BitVector*, U32);
void Kino1_BitVec_shrink(BitVector *, U32);
void Kino1_BitVec_set(BitVector*, U32);
void Kino1_BitVec_clear(BitVector*, U32);
void Kino1_BitVec_bulk_set(BitVector*, U32, U32);
void Kino1_BitVec_bulk_clear(BitVector*, U32, U32);
bool Kino1_BitVec_get(BitVector*, U32);
U32  Kino1_BitVec_next_set_bit(BitVector*, U32);
U32  Kino1_BitVec_next_clear_bit(BitVector*, U32);
void Kino1_BitVec_logical_and(BitVector*, BitVector*);
U32  Kino1_BitVec_count(BitVector*);
AV*  Kino1_BitVec_to_array(BitVector*);
void Kino1_BitVec_destroy(BitVector*);

#endif /* include guard */

__C__

#include "KinoSearch1UtilBitVector.h"

static unsigned char bitmasks[] = { 
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
};

BitVector*
Kino1_BitVec_new(U32 capacity) {
    BitVector *bit_vec;
    Kino1_New(0, bit_vec, 1, BitVector);
    bit_vec->capacity = 0;
    bit_vec->bits = NULL;
    Kino1_BitVec_grow(bit_vec, capacity);
    return bit_vec;
}

BitVector*
Kino1_BitVec_clone(BitVector *bit_vec) {
    BitVector *evil_twin;
    U32 byte_size;

    Kino1_New(0, evil_twin, 1, BitVector);
    byte_size = ceil(bit_vec->capacity / 8.0);
    evil_twin->bits 
        = (unsigned char*)Kino1_savepvn((char*)bit_vec->bits, byte_size);
    evil_twin->capacity = bit_vec->capacity;

    return evil_twin;
}

void
Kino1_BitVec_grow(BitVector *bit_vec, U32 capacity) {
    U32 byte_size;
    U32 old_capacity;

    /* derive size in bytes from size in bits */
    byte_size = ceil(capacity / 8.0);

    if (capacity > bit_vec->capacity && bit_vec->bits != NULL) {
        U32 old_byte_size;
        old_byte_size = ceil(bit_vec->capacity / 8.0);

        Kino1_Renew(bit_vec->bits, byte_size, unsigned char);
        /* zero out all new bits, since Renew doesn't guarantee they're 0 */
        old_capacity      = bit_vec->capacity;
        bit_vec->capacity = capacity;
        Kino1_BitVec_bulk_clear(bit_vec, old_capacity, capacity - 1);

        /* shouldn't be necessary, but Valgrind reports an error without it */
        if (byte_size > old_byte_size) {
            memset( (bit_vec->bits + old_byte_size), 0x00, 
                (byte_size - old_byte_size) );
        }
    }
    else if (bit_vec->bits == NULL) {
        Kino1_Newz(0, bit_vec->bits, byte_size, unsigned char);
        bit_vec->capacity = capacity;
    }
}

void 
Kino1_BitVec_shrink(BitVector *bit_vec, U32 capacity) {
    U32 byte_size;
    
    if (capacity >= bit_vec->capacity)
        return;

    /* derive size in bytes from size in bits */
    byte_size = ceil(capacity / 8.0);
    Kino1_Renew(bit_vec->bits, byte_size, unsigned char);
    bit_vec->capacity = capacity;
}

void 
Kino1_BitVec_set(BitVector *bit_vec, U32 num) {
    if (num >= bit_vec->capacity)
        Kino1_BitVec_grow(bit_vec, num + 1);
    bit_vec->bits[ (num >> 3) ]  |= bitmasks[num & 0x7];
}

void 
Kino1_BitVec_clear(BitVector *bit_vec, U32 num) {
    if (num >= bit_vec->capacity)
        Kino1_BitVec_grow(bit_vec, num + 1);

    bit_vec->bits[ (num >> 3) ] &= ~(bitmasks[num & 0x7]);
}


void
Kino1_BitVec_bulk_set(BitVector *bit_vec, U32 first, U32 last) {
    unsigned char *ptr;
    U32   num_bytes;

    /* detect range errors */
    if (first > last) {
        Kino1_confess("bitvec range error: %d %d %d", first, last, 
            bit_vec->capacity);
    }

    /* grow the bits if necessary */
    if (last >= bit_vec->capacity) {
        Kino1_BitVec_grow(bit_vec, last);
    }

    /* set partial bytes */
    while (first % 8 != 0 && first <= last) {
        Kino1_BitVec_set(bit_vec, first++);
    }
    while (last % 8 != 0 && last >= first) {
        Kino1_BitVec_set(bit_vec, last--);
    }
    Kino1_BitVec_set(bit_vec, last);

    /* mass set whole bytes */
    if (last > first) {
        ptr = bit_vec->bits + (first >> 3);
        num_bytes = (last - first) >> 3;
        memset(ptr, 0xff, num_bytes);
    }
}

void
Kino1_BitVec_bulk_clear(BitVector *bit_vec, U32 first, U32 last) {
    unsigned char *ptr;
    U32   num_bytes;

    /* detect range errors */
    if (first > last) {
        Kino1_confess("bitvec range error: %d %d %d", first, last, 
            bit_vec->capacity);
    }

    /* grow the bits if necessary */
    if (last >= bit_vec->capacity) {
        Kino1_BitVec_grow(bit_vec, last);
    }

    /* clear partial bytes */
    while (first % 8 != 0 && first <= last) {
        Kino1_BitVec_clear(bit_vec, first++);
    }
    while (last % 8 != 0 && last >= first) {
        Kino1_BitVec_clear(bit_vec, last--);
    }
    Kino1_BitVec_clear(bit_vec, last);

    /* mass clear whole bytes */
    if (last > first) {
        ptr       = bit_vec->bits + (first >> 3);
        num_bytes = (last - first) >> 3;
        memset(ptr, 0, num_bytes);
    }
}

bool
Kino1_BitVec_get(BitVector *bit_vec, U32 num) {
    if (num >= bit_vec->capacity) return 0;
    return (bit_vec->bits[ (num >> 3) ] & bitmasks[num & 0x7]) != 0;
}

U32
Kino1_BitVec_next_set_bit(BitVector *bit_vec, U32 num) {
    U32   outval;
    unsigned char *bits_ptr;
    unsigned char *end_ptr;
    int i;
    U32 byte_size;

    if (num >= bit_vec->capacity) {
        return KINO_BITVEC_SENTINEL;
    }

    outval = KINO_BITVEC_SENTINEL;

    bits_ptr  = bit_vec->bits + (num >> 3) ;
    byte_size = ceil(bit_vec->capacity / 8.0);
    end_ptr   = bit_vec->bits + byte_size;

    while (outval == KINO_BITVEC_SENTINEL) {
        if (*bits_ptr != 0) {
            /* check each num in represented in this byte */
            outval = (bits_ptr - bit_vec->bits) * 8;
            for (i = 0; i < 8; i++) {
                if (Kino1_BitVec_get(bit_vec, outval) == 1) {
                    if (outval < bit_vec->capacity && outval >= num) {
                        return outval;
                    }
                }
                outval++;
            }
            /* nothing valid, so reset the sentinel */
            outval = KINO_BITVEC_SENTINEL;
        }
        if (++bits_ptr >= end_ptr)
            break;
    }
    /* nothing valid, so return a sentinel */
    return KINO_BITVEC_SENTINEL;
}

U32
Kino1_BitVec_next_clear_bit(BitVector *bit_vec, U32 num) {
    U32   outval;
    unsigned char *bits_ptr;
    unsigned char *end_ptr;
    int i;

    if (num >= bit_vec->capacity) {
        return num;
    }

    outval = KINO_BITVEC_SENTINEL;

    bits_ptr = bit_vec->bits + (num >> 3) ;
    end_ptr  = bit_vec->bits + (bit_vec->capacity >> 3);

    while (outval == KINO_BITVEC_SENTINEL) {
        if (*bits_ptr != 0xFF) {
            /* check each num in represented in this byte */
            outval = (bits_ptr - bit_vec->bits) * 8;
            for (i = 0; i < 8; i++) {
                if (Kino1_BitVec_get(bit_vec, outval) == 0) {
                    if (outval < bit_vec->capacity && outval >= num) {
                        return outval;
                    }
                }
                outval++;
            }
            /* nothing valid, so reset the sentinel */
            outval = KINO_BITVEC_SENTINEL;
        }
        if (++bits_ptr >= end_ptr)
            break;
    }
    /* didn't find clear bits in the set, so return 1 larger than the max */
    return bit_vec->capacity;
}

void
Kino1_BitVec_logical_and(BitVector *bit_vec, BitVector *other) {
    U32 num = 0;
    while (1) {  
        num = Kino1_BitVec_next_set_bit(bit_vec, num);
        if (num == KINO_BITVEC_SENTINEL)
            break;
        if ( !Kino1_BitVec_get(other, num) ) 
            Kino1_BitVec_clear(bit_vec, num);
        num++;
    }
}

const U32 BYTE_COUNTS[256] = {
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
    4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
};

U32 Kino1_BitVec_count(BitVector *bit_vec) {
    U32 count = 0;
    U32 byte_size = ceil(bit_vec->capacity / 8.0);
    unsigned char *ptr = bit_vec->bits;
    unsigned char *limit = ptr + byte_size;

    for( ; ptr < limit; ptr++) {
        count += BYTE_COUNTS[*ptr];
    }

    return count;
}

AV*  
Kino1_BitVec_to_array(BitVector* bit_vec) {
    U32  num = 0;
    AV  *out_av;

    out_av = newAV();
    while (1) {  
        num = Kino1_BitVec_next_set_bit(bit_vec, num);
        if (num == KINO_BITVEC_SENTINEL)
            break;
        av_push( out_av, newSViv(num) );
        num++;
    }
    return out_av;
}

void
Kino1_BitVec_destroy(BitVector* bit_vec) {
    Kino1_Safefree(bit_vec->bits);
    Kino1_Safefree(bit_vec);
}


__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::BitVector - a set of bits

==head1 DESCRIPTION

A vector of bits, which grows as needed.  The implementation is designed to
resemble both org.apache.lucene.util.BitVector and java.util.BitSet.  
Accessible from both C and Perl.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

