/* MMA.xs */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#define NEED_grok_number
#define NEED_grok_numeric_radix
#include "ppport.h"
#include "mm.h"
#include "mma_alloc.h"
#ifdef __cplusplus
}
#endif

/* if you add more, adjust the starting value so the last one is zero */
enum { MM_BOOL_ARRAY = -4, MM_DOUBLE_ARRAY, MM_INT_ARRAY, MM_UINT_ARRAY,
       MM_ARRAY };

/* option values for arrays (exported) */
enum mm_array_option_t { MM_FIXED_REC, MM_CSTRING };

/* flags for store */
enum store_flags_t { MM_NO_CREATE=1, MM_NO_OVERWRITE=2 };

/* number of initial entries if make_array or make_hash doesn't specify,
     also the increase when when a large hash is expanded */
#define DELTA_ENTRIES 64

/* result codes from check rtns */
enum {NOT_SET=1, AD_OK};

/* small pointers */
#define ZERO_LEN ((char *)1)
#define MIN_AD ((char *)4096)

/* range that the size word of a memory pool can be */
#define MIN_SIZE 4096
#define MAX_SIZE 0x7FFFFFFF

/* common error message for > 1 routine */
const char mm_op1mes[] = "IPC::MMA first argument error";

/* this routine is called by the AUTOLOAD sub in MMA.pm,
    to check for a constant defined by IPC::MMA */

static double constant (char *name, int notused) {
    /* errno is $! to AUTOLOAD in MMA.pm; our return value is $arg */
    errno = 0;
    if (strEQ(name, "MM_ARRAY"))        return MM_ARRAY;
    if (strEQ(name, "MM_BOOL_ARRAY"))   return MM_BOOL_ARRAY;
    if (strEQ(name, "MM_CSTRING"))      return MM_CSTRING;
    if (strEQ(name, "MM_DOUBLE_ARRAY")) return MM_DOUBLE_ARRAY;
    if (strEQ(name, "MM_FIXED_REC"))    return MM_FIXED_REC;
    if (strEQ(name, "MM_INT_ARRAY"))    return MM_INT_ARRAY;
    if (strEQ(name, "MM_LOCK_RD"))      return MM_LOCK_RD;
    if (strEQ(name, "MM_LOCK_RW"))      return MM_LOCK_RW;
    if (strEQ(name, "MM_MUST_CREATE"))  return MM_NO_OVERWRITE;
    if (strEQ(name, "MM_NO_CREATE"))    return MM_NO_CREATE;
    if (strEQ(name, "MM_NO_OVERWRITE")) return MM_NO_OVERWRITE;
    if (strEQ(name, "MM_UINT_ARRAY"))   return MM_UINT_ARRAY;
    errno = EINVAL;
    return 0;
}

/*--------------------------------- support -------------------------------*/

/* round size up to multiple of alloc_size */

size_t mm_round_up (size_t size) {
    return ((size - 1) | mma_alloc_mask()) + 1;
}

/* useful for debugging seg faults

size_t mm_sizeof_wrapper (MM *mm, void *ptr) {
    return mm_sizeof (mm, ptr);
}
*/

/*---------------------------- data structures ----------------------------*/

/* scalar base */
typedef struct {
    MM   *mm;
    char *ptr;
} mm_scalar;

/* array base block
   should we split out options as a separate word? */
typedef struct {
    MM   *mm;
    char *ptr;
    IV   type, shiftCount;
    UV   entries;
} mm_array;

/* pointer to value block precedes the key in each hash entry */
typedef struct {
    char *valPtr;
    char key;
} mm_hash_entry;

/* hash base */
typedef struct {
    MM   *mm;
    mm_hash_entry **ptr;
    UV   entries;
} mm_hash;

#define mm_hash_entry_header mm_hash_entry

/*------------------------------ error messages ---------------------------*/

enum textType {MAKE, SCALAR, ARRAY, HASH};

char * mm_textType (enum textType type) {
    switch (type) {
        case MAKE:   return "mm";
        case SCALAR: return "scalar";
        case ARRAY:  return "array";
        case HASH:   return "hash";
        default:     return "";
}   }

void mm_err_set (void *mes) {
    mm_lib_error_set (0, NULL);
    mm_lib_error_set (0, mes);
}

int mm_checkMM (char *mm) {
    size_t size;

    if (mm >= MIN_AD
     && (size = *((size_t *)mm)) >= (size_t)MIN_SIZE
     && size <= (size_t)MAX_SIZE) return AD_OK;

    warn (mm_op1mes);
    return 0;
}

int mm_checkArg (void *arg, enum textType type) {
    char *mm, *ptr;
    size_t size;

    if ((char *)arg >= MIN_AD
     && (mm = ((mm_scalar *)arg)->mm) >= MIN_AD
     && (size = *((size_t *)mm)) >= MIN_SIZE
     && size <= MAX_SIZE
     && (char *)arg > mm
     && (char *)arg < mm + size) {

        ptr = ((mm_scalar *)arg)->ptr;
        if (type == SCALAR && ptr == NULL) return NOT_SET;
        if (ptr > mm
         && ptr < mm + size) return AD_OK;
    }
    warn (mm_op1mes);
    return 0;
}

void mm_err_sv (SV *sv, char *what, IV type) {
    char mes[128];
    char *article = what[0] == 'a' ? "an" : "a";
    mes[0]=0;
    if (!SvOK(sv))
        sprintf (mes, "undefined %s not allowed", what);
    else if (SvROK(sv))
        sprintf (mes, "a reference is not allowed as %s %s", article, what);
    else if (type >= MM_DOUBLE_ARRAY && type <= MM_UINT_ARRAY)
        sprintf (mes,
          "attempt to store non-numeric or out-of-range value in numeric array %s",
          what);
    if (mes[0]) mm_err_set (mes);
}

void mm_err_oper (int index, char *what) {
    char mes[40];
    sprintf (mes, "%s %d is out of range", what, index);
    mm_err_set (mes);
}

void mm_err_cant_lock(void) {
    mm_err_set ("can't lock the shared memory");
}

void mm_err_type (IV type) {
    char mes [40];
    sprintf (mes, "bad array type value %d", type);
    mm_err_set (mes);
}

/*--------------------------------- scalars -------------------------------*/

/* make a scalar */

mm_scalar *mm_make_scalar (MM *mm, int prelocked) {
    mm_scalar *scalar = NULL;
    if (mm_checkMM (mm)) {
        if (prelocked || mm_lock (mm, MM_LOCK_RW)) {

            /* get a cleared header block */
            scalar = mma_calloc (mm, 1, sizeof(mm_scalar));
            /* if it worked, put the pointer to the mm structure into the block */
            if (scalar) scalar->mm = mm;

            prelocked || mm_unlock (mm);
        } else mm_err_cant_lock();
    }
    /* return pointer to block, or NULL if we're out of memory */
    return scalar;
}

/* unmake a scalar */

void mm_free_scalar (mm_scalar *scalar, int prelocked) {

    if (mm_checkArg (scalar, SCALAR)) {
        if (prelocked || mm_lock(scalar->mm, MM_LOCK_RW)) {

            /* if the value has been set, return the memory for the value block */
            if (scalar->ptr > ZERO_LEN) mma_free (scalar->mm, scalar->ptr);
            /* return the header block to the memory pool */
            mma_free (scalar->mm, scalar);

            prelocked || mm_unlock(scalar->mm);
        } else mm_err_cant_lock();
}   }

/* get a Perl scalar from a shared memory scalar */

SV *mm_scalar_fetch (mm_scalar *scalar, int prelocked) {
    void *ptr;
    STRLEN thisLen;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (scalar, SCALAR) > NOT_SET) {
        if (prelocked || mm_lock(scalar->mm, MM_LOCK_RD)) {

            /* zero-length string sets pointer to 1 */
            ptr = scalar->ptr;
            if (ptr == ZERO_LEN) sv = &PL_sv_no;
            /* return it as a Perl scalar */
            else {
                sv = newSVpvn (ptr, thisLen = mm_sizeof(scalar->mm, ptr));
            }
            prelocked || mm_unlock(scalar->mm);
        } else mm_err_cant_lock();
    }
    return sv;
}

/* store a Perl scalar in a shared memory scalar */

int mm_scalar_store (mm_scalar *scalar, SV *sv, int prelocked) {
    STRLEN svLen;
    char *ptr, *newptr, *svPtr;
    int ret=0;
/*    char mes[128]; STRLEN thisLen; **** TEMP ****/

    if (mm_checkArg (scalar, SCALAR)) {
        if (SvOK(sv) && !SvROK(sv)) {
            if (prelocked || mm_lock(scalar->mm, MM_LOCK_RW)) {

                /* get the location and length of the Perl scalar (as a string) */
                svPtr = SvPV(sv, svLen);
                ptr = scalar->ptr;
                if (!svLen) {
                    /* zero-length string makes ptr ZERO_LEN */
                    if (ptr > ZERO_LEN) mma_free (scalar->mm, ptr);
                    scalar->ptr = ZERO_LEN;
                    ret = 1;
                } else if (ptr) {
                    if (!mma_sizeok(ptr, svLen)) {
                        /* need a different block of memory
                        we don't use realloc because it loses memory
                        ptr = mma_realloc (scalar->mm, ptr, svLen); */
                        if (newptr = mma_malloc (scalar->mm, svLen))
                            mma_free (scalar->mm, ptr);
                        ptr = newptr;
                }   } else {
                    ptr = mma_malloc (scalar->mm, svLen);
                }
                if (ptr) {
                    scalar->ptr = ptr;
                    /* move the value to the value block */
                    memcpy (ptr, svPtr, svLen);
                    ret = 1;
                }
                prelocked || mm_unlock(scalar->mm);
            } else mm_err_cant_lock();
        } else mm_err_sv (sv, "value", 0);
    }
    return ret;
}

/*-------------------------------- arrays --------------------------------*/

#if UVSIZE==4
#define BIT_TO_UV_SHIFT 5
#define BIT_WITHIN_UV_MASK 0x1F
#define BIT0    ((UV)0x80000000)
#define ALLONES ((UV)0xFFFFFFFF)

#elif UVSIZE==8
#define BIT_TO_UV_SHIFT 6
#define BIT_WITHIN_UV_MASK 0x3F
#define BIT0    ((UV)0x8000000000000000LLU)
#define ALLONES ((UV)0xFFFFFFFFFFFFFFFFLLU)

#else
#error "Can't determine MM_ARRAY_BOOL parameters for type UV"
#endif

#define BITNO_TO_UV_OFFSET(bitno) (bitno>>BIT_TO_UV_SHIFT)
#define BITNO_TO_BITMASK(bitno) (BIT0>>(bitno&BIT_WITHIN_UV_MASK))
#define BITNO_TO_RIGHTMASK(bitno) (ALLONES>>(bitno&BIT_WITHIN_UV_MASK))

UV mm_type_size (IV type) {
    switch (type) {
        case MM_BOOL_ARRAY:
            return 0;
        case MM_DOUBLE_ARRAY:
            return sizeof(NV);
        case MM_INT_ARRAY:
        case MM_UINT_ARRAY:
            return sizeof(IV);
        case MM_ARRAY:
            return sizeof(void *);
        default:
            return type>>1;
}   }

size_t mm_bytes_for (IV type, UV entries) {
    if (type == MM_BOOL_ARRAY) return (entries + 7) >> 3;
    return (size_t)(mm_type_size(type) * entries);
}

size_t mm_alloc_len (IV type, IV entries) {
    if (entries <= 0) entries = DELTA_ENTRIES;
    return (mm_round_up (mm_bytes_for (type, (UV)entries)));
}

/* Front-end for the grok_number routine, called by mm_array_store
    to determine whether an sv can be stored in a DOUBLE, INT, or
    UINT array.  This is adapted from looks_like_number in perl 5.10.1.
    Under earlier perls, grok_number is provided by ppport.h. */

I32 mm_grokN(SV *sv, IV type) {
    register const char *sbegin;
    STRLEN len;
    I32 flgs = SvFLAGS(sv);

    if (flgs & SVf_POK) {
        sbegin = SvPVX_const(sv);
        len = SvCUR(sv);
    } else {
        if (!(flgs & (SVp_POK|SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK))) return 0;
        sbegin = SvPV_const(sv, len);

#if PERL_VERSION < 8
        /* The following is an attempt to cope with perl 5.6.2 with
            UVSIZE == 8, under which SvPV stringifies sv's in the
            top half of the UV range in E-notation, thus fouling up
            grok_number */
        if (type == MM_UINT_ARRAY
         && flgs & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK)) {
            NV nv = SvNV(sv);
            return nv < UV_MIN ? IS_NUMBER_NEG
                               : nv > UV_MAX ? IS_NUMBER_GREATER_THAN_UV_MAX
                                             : IS_NUMBER_IN_UV;
        }
#endif
    }
    return grok_number(sbegin, len, NULL);
}

/* make an array */

mm_array *mm_make_array (MM *mm, IV type, IV entries, UV option, int prelocked) {
    mm_array *array = NULL;

    if (mm_checkMM (mm)) {
        if (type >= MM_BOOL_ARRAY) {
            if (prelocked || mm_lock(mm, MM_LOCK_RW)) {

                if (array = mma_calloc (mm, 1, sizeof(mm_array))) {

                    array->mm = mm;
                    array->type = type > 0 ? type<<1 | option & 1 : type;

                    if (!(array->ptr = mma_calloc (mm, 1,
                                            mm_alloc_len (array->type, entries)))) {
                        mma_free (mm, array);
                        array = NULL;
                }   }
                prelocked || mm_unlock(mm);
            } else mm_err_cant_lock();
        } else mm_err_type (type);
    }
    return array;
}

/* return the status of an array */

void mm_array_status (mm_array *array, IV *retval, int prelocked) {

    if (mm_checkArg (array, ARRAY)) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RD)) {

            /* see the mm_array_status routine in the XS section
                near the end of this file */
            retval[0] = (IV)(array->entries);
            retval[1] = (IV)(array->shiftCount);
            /* type and option as in mm_make_array */
            retval[2] = array->type > 0 ? array->type>>1 : array->type;
            retval[3] = array->type > 0 ? array->type & 1 : 0;
            prelocked || mm_unlock(array->mm);
        } else {
            retval[0] = -2;
            mm_err_cant_lock();
    }   } else {
        retval[0] = -1;
}   }

/* get an entry from an array */

SV *mm_array_fetch (mm_array *array, IV index, int prelocked) {
    STRLEN len, len2;
    UV uv;
    char *ptr;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (array, ARRAY)
     && array->type >= MM_BOOL_ARRAY) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RD)) {
            if (index >= 0 && index < array->entries) {
                if (array->type >= MM_BOOL_ARRAY) {

                    ptr = array->ptr;
                    switch (array->type) {

                        /* Note that we store booleans in an array such that [0]
                            is the MSbit of the first UV, thru the LSbit of the
                            first UV which is followed by MSbit of the second UV,
                            etc.
                           We do this so that boolean arrays are arranged like
                            other arrays in UV-sized memory printouts.  Generally
                            this means in 32-bit words, but if your Perl is built
                            for 64-bit UVs, display boolean arrays by displaying
                            64-bit long longs */

                        case MM_BOOL_ARRAY:
                            uv = *((UV *)ptr + BITNO_TO_UV_OFFSET(index));
                            sv = uv & BITNO_TO_BITMASK(index) ? &PL_sv_yes : &PL_sv_no;
                            break;
                        case MM_DOUBLE_ARRAY:
                            sv = newSVnv(*((NV *)ptr + index));
                            break;
                        case MM_INT_ARRAY:
                            sv = newSViv(*((IV *)ptr + index));
                            break;
                        case MM_UINT_ARRAY:
                            sv = newSVuv(*((UV *)ptr + index));
                            break;
                        default: /* positive value is a fixed-length string or record */
                            len = (array->type) >> 1;
                            ptr += index * len;
                            if (array->type & 1) {
                                /* cstring */
                                if ((len2 = strlen(ptr)) < len) len = len2;
                            }
                            sv = newSVpvn (ptr, len);
                            break;
                        case MM_ARRAY:
                            if (ptr = *((void **)ptr + index)) {
                                if (ptr == ZERO_LEN) sv = &PL_sv_no;
                                else sv = newSVpvn (ptr, mm_sizeof(array->mm, ptr));
                    }   }
                    prelocked || mm_unlock(array->mm);
                } else mm_err_type (array->type);
            } else mm_err_oper ((int)index, "index");
        } else mm_err_cant_lock();
    }
    return sv;
}

/* change the size of an array block if necessary,
        but not the number of entries */

int mm_array_extend (mm_array *array, UV entries, int prelocked) {
    STRLEN len, bytes_needed;
    char *ptr, **ptr2, *valPtr;
    UV n, size;
    int ret=0;

    if (mm_checkArg (array, ARRAY)) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {

            ptr = array->ptr;
            if (entries < array->entries) {
                if (array->type == MM_ARRAY) {
                    /* free memory blocks containing discarded elements */
                    ptr2 = (char **)ptr + entries;
                    n = array->entries - entries;
                    while (n--) {
                        valPtr = *ptr2;
                        if (valPtr > ZERO_LEN) mma_free (array->mm, valPtr);
                        *ptr2++ = NULL;
                    }
                } else if (array->type == MM_BOOL_ARRAY) {
                    /****** clear bits being discarded ******/
                } else {
                    size = mm_type_size (array->type);
                    ptr2 = (char **)(ptr + entries * size);
                    memset (ptr2, 0, (size_t)((array->entries - entries) * size));
            }   }
            len = mm_sizeof (array->mm, ptr);
            bytes_needed = mm_alloc_len (array->type, entries);

            if (bytes_needed > len
             || entries <= array->entries
             && len >= 256
             && bytes_needed < (len - 256)) {

                /* need a new array block */
                /* we don't use realloc because it loses memory */
                bytes_needed += 16;
                if (ptr2 = mma_malloc(array->mm, bytes_needed)) {
                    if (len < bytes_needed) {
                        memcpy (ptr2, ptr, len);
                        memset ((char *)ptr2 + len, 0, bytes_needed - len);
                    } else memcpy (ptr2, ptr, bytes_needed);
                    mma_free (array->mm, ptr);
                    array->ptr = (char *)ptr2;
                }
                ptr = (char *)ptr2;
            }
            if (ptr) ret = 1;
            prelocked || mm_unlock(array->mm);
        } else mm_err_cant_lock();
    }
    return ret;
}

/* store an entry in an array */

int mm_array_store (mm_array *array, IV index, SV *sv, int prelocked) {
    char *ptr, *valPtr, *svPtr;
    char *newptr = (char *)-1;
    STRLEN len, svLen;
    UV mask;
    I32 grokVal;
    char s[64];
    int ret=0;
    int boole=-1;

    mm_lib_error_set (0, NULL);
    if (mm_checkArg (array, ARRAY)) {
        if (array->type < MM_BOOL_ARRAY) {
            mm_err_type (array->type);
            return 0;
        }
        if (SvOK(sv) && !SvROK(sv)) {
            if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {
                if (index >= 0
                 && (index < array->entries
                  || mm_array_extend (array, index+1, 1))) {

                    /* store the value based on the array type */
                    ptr = array->ptr;
                    switch (array->type) {

                        case MM_ARRAY:
                            svPtr = SvPV (sv, svLen);
                            ptr += index * sizeof(void *);
                            valPtr = *((void **)ptr);
                            if (!svLen) {
                                /* new value is zero-length */
                                if (valPtr > ZERO_LEN) mma_free (array->mm, valPtr);

                                /* pointer value of 1 flags zero-length string */
                                *((void **)ptr) = ZERO_LEN;
                                if (index >= array->entries) array->entries = index + 1;
                                ret = 1;
                            } else {
                                /* new value is a real string
                                    we don't use realloc because it loses memory */
                                if (valPtr <= ZERO_LEN)
                                    valPtr = mma_malloc (array->mm, svLen);
                                else if (!(boole = mma_sizeok(valPtr, svLen))) {
                                    if (newptr = mma_malloc(array->mm, svLen)) {
                                        mma_free(array->mm, valPtr);
                                    }
                                    valPtr = newptr;
                                }
                                if (valPtr) {
                                    /* we have an entry to store in! */
                                    *((void **)ptr) = valPtr;
                                    memcpy (valPtr, svPtr, svLen);
                                    if (index >= array->entries)
                                        array->entries = index + 1;
                                    ret = 1;
                            }   }
                            break;

                        /* Note that we store booleans in an array such that [0]
                            is 0x80 of the lowest byte address, [15] is 0x01 of
                            the second byte address, etc.
                           We do this so that boolean arrays are arranged like
                            other arrays in byte-sized memory printouts. */

                        case MM_BOOL_ARRAY:
                            ptr += BITNO_TO_UV_OFFSET(index) * UVSIZE;
                            mask = BITNO_TO_BITMASK(index);

                            if (SvTRUE(sv)) *(UV *)ptr |=  mask;
                            else            *(UV *)ptr &= ~mask;
                            if (index >= array->entries) array->entries = index + 1;
                            ret = 1;
                            break;

                        case MM_DOUBLE_ARRAY:
                            grokVal = mm_grokN(sv, MM_DOUBLE_ARRAY);
                            if (grokVal) {
                                *((NV *)ptr + index) = SvNV(sv);
                                if (index >= array->entries) array->entries = index + 1;
                                ret = 1;
                            } else {
                                mm_err_sv (sv, "", MM_DOUBLE_ARRAY);
                            }
                            break;

                        case MM_INT_ARRAY:
                            grokVal = mm_grokN(sv, MM_INT_ARRAY);
                            /* following test includes !IS_NUMBER_NOT_INT */
                            if ((grokVal & ~IS_NUMBER_NEG) == IS_NUMBER_IN_UV) {
                                *((IV *)ptr + index) = SvIV(sv);
                                if (index >= array->entries) array->entries = index + 1;
                                ret = 1;
                            } else {
                                sprintf (s, "(grok=0x%X)", grokVal);
                                mm_err_sv (sv, s, MM_INT_ARRAY);
                            }
                            break;

                        case MM_UINT_ARRAY:
                            grokVal = mm_grokN(sv, MM_UINT_ARRAY);
                            /* the following test includes !IS_NUMBER_NEG */
                            if ((grokVal & ~IS_NUMBER_NOT_INT) == IS_NUMBER_IN_UV) {
                                *((UV *)ptr + index) = SvUV(sv);
                                if (index >= array->entries) array->entries = index + 1;
                                ret = 1;
                            } else {
                                sprintf (s, "(grok=0x%X)", grokVal);
                                mm_err_sv (sv, s, MM_UINT_ARRAY);
                            }
                            break;

                        /* positive type value is a fixed-length string or record */
                        default:
                            svPtr = SvPV (sv, svLen);
                            len = (STRLEN)((array->type) >> 1);
                            ptr += index * len;
                            if (svLen < len) {
                                memcpy (ptr, svPtr, svLen);
                                memset (ptr + svLen, 0, len - svLen);
                            } else memcpy (ptr, svPtr, len);
                            if (index >= array->entries) array->entries = index + 1;
                            ret = 1;
                    }
                    prelocked || mm_unlock(array->mm);
                } else mm_err_oper ((int)index, "index");
            } else mm_err_cant_lock();
        } else mm_err_sv (sv, "value", array->type);
    }
    return ret;
}

/* return the number of entries in the array, no lock needed */

IV mm_array_fetchsize (mm_array *array) {
    if (mm_checkArg (array, ARRAY)) return array->entries;
    return -1;
}

/* this is like extend but also stores a new number of entries */

int mm_array_storesize (mm_array *array, UV entries, int prelocked) {
    int ret;
    if (ret = mm_array_extend (array, entries, prelocked)) array->entries = entries;
    return ret;
}

/* return whether a specified entry exists, no lock needed */

int mm_array_exists (mm_array *array, IV index) {
    if (mm_checkArg (array, ARRAY))
        return index >= 0
            && index < array->entries
            && (array->type != MM_ARRAY
             || *(((void **)array->ptr) + index) != NULL);
    return 0;
}

/* non-boolean array is shrinking, pull remaining entries over the splice (if any) down */

void mm_array_splice_contract (mm_array *array, UV index, UV shift_count,
                               UV size, UV new_entries) {
    char **ptr2, *valPtr;
    UV i;
    char *ptr = array->ptr + index*size;

    /* if MM_ARRAY, free blocks that are about to have their pointers eliminated */
    if (array->type == MM_ARRAY) {
        ptr2 = (char **)ptr;
        i = shift_count;
        while (i--) {
            valPtr = *ptr2++;
            if (valPtr > ZERO_LEN) mma_free (array->mm, valPtr);
    }   }
    memcpy (ptr, ptr + shift_count*size,
            (array->entries - (index + shift_count))*size);

    /* clear the now-unused entries at the end of the array */
    memset (array->ptr + new_entries*size, 0, (size_t)(shift_count*size));
}

/* non-boolean array is growing, push entries up in array */

void mm_array_splice_expand (mm_array *array, UV index, UV shift_count, UV size) {
    char *ptr = array->ptr + index*size;

    /* shift the existing entries up (memmove is a tricky routine) */
    memmove (ptr + shift_count*size, ptr, (size_t)((array->entries - index)*size));
    /* clear the newly-duplicated entries starting at index */
    if (index < array->entries) memset (ptr, 0, (size_t)(shift_count*size));
}

/* boolean array is shrinking, pull entries down starting with the index entry */

void mm_array_splice_bool_contract (mm_array *array, UV index,
                                    IV shift_count, UV new_entries) {
    UV *src_ad, *dest_ad, *last_dest_ad;
    IV first_shift, second_shift;
    UV left_mask, right_mask, src_index, prev, this, alloc, words_to_clear;
    UV *ptr = (UV *)array->ptr;

    /* destination bit number is index */
    src_index = index + shift_count;
    last_dest_ad = ptr;
    if (new_entries) last_dest_ad += BITNO_TO_UV_OFFSET(new_entries-1);

    /* nothing to shift if src_index is at the top of the array */
    if (src_index < array->entries) {

        /* source bit number is src_index */
        dest_ad = ptr + BITNO_TO_UV_OFFSET(index);
        src_ad  = ptr + BITNO_TO_UV_OFFSET(src_index);

        first_shift = (    index & BIT_WITHIN_UV_MASK)
                    - (src_index & BIT_WITHIN_UV_MASK);
        /* this can range from -31 to 31 (or -63 to 63)
           < 0 means shift bits left  within words
             0 means bits stay in same bit numbers
           > 0 means shift bits right within words
        */
        if (first_shift < 0) {
            /* shifting array down, left within words,
                 need to fetch 2nd source word to get 1st dest word */
            second_shift = -first_shift;
            first_shift = UVSIZE*8 - second_shift;
            prev = *src_ad++;
        } else {
            /* shifting array down but shifting right within words */
            second_shift = UVSIZE*8 - first_shift;
            prev = 0;
        }
        /* do the lowest-addressed word */
        right_mask = BITNO_TO_RIGHTMASK(index);
        this = *src_ad++;
        *dest_ad = *dest_ad & ~right_mask
                 | (prev << second_shift | this >> first_shift) & right_mask;
        dest_ad++;

        /* pull the rest of the array down (if any) */
        while (dest_ad <= last_dest_ad) {
            prev = this;
            this = *src_ad++;
            *dest_ad++ = prev << second_shift | this >> first_shift;
    }   }
    /* clear right bits from last dest ad */
    left_mask = ~BITNO_TO_RIGHTMASK(new_entries);
    *last_dest_ad++ &= left_mask;

    /* clear words after last dest ad */
    alloc = mm_sizeof (array->mm, array->ptr);
    words_to_clear = ((shift_count | BIT_WITHIN_UV_MASK) + 1) >> BIT_TO_UV_SHIFT;
    while (words_to_clear--
        && (char *)last_dest_ad < (char *)ptr + alloc)
        *last_dest_ad++ = 0;
}

/* boolean array is growing, shift entries upward starting with the highest entries */

void mm_array_splice_bool_expand (mm_array *array, UV index,
                                  IV shift_count, UV new_entries) {
    UV *src_ad, *dest_ad, *last_dest_ad;
    IV first_shift, second_shift;
    UV left_mask, right_mask, dest_index, prev, this;
    UV *ptr = (UV *)array->ptr;

    /* if index is at the top of the array, there's nothing to shift */
    if (index < array->entries) {

        dest_index   = index + shift_count;
        dest_ad      = ptr + BITNO_TO_UV_OFFSET(new_entries-1);
        src_ad       = ptr + BITNO_TO_UV_OFFSET(array->entries-1);
        last_dest_ad = ptr + BITNO_TO_UV_OFFSET(dest_index);

        second_shift = (dest_index & BIT_WITHIN_UV_MASK)
                     - (     index & BIT_WITHIN_UV_MASK);
        /* this can range from -31 to 31 (or -63 to 63)
           < 0 means shift bits left  within words
             0 means bits stay in same bit numbers
           > 0 means shift bits right within words
        */
        prev = 0;
        if (second_shift < 0) {
            /* shifting right in array but shifting words left */
            first_shift = -second_shift;
            second_shift = UVSIZE*8 - first_shift;
        } else {
            first_shift = UVSIZE*8 - second_shift;
        }
        left_mask = ~BITNO_TO_RIGHTMASK(new_entries);

        while (dest_ad > last_dest_ad) {
            this = *src_ad--;
            *dest_ad-- = (this << first_shift | prev >> second_shift) & left_mask;
            left_mask = ALLONES;
            prev = this;
        }
        /* do the leftmost word
            for shifting upward, a left_mask and right_mask based on 'index'
                apply to the last dest word only if it is also the last source word
                (the one containing 'index' */

        if (last_dest_ad == ptr + BITNO_TO_UV_OFFSET(index)) {
            right_mask = left_mask & BITNO_TO_RIGHTMASK(index);
            left_mask &= ~BITNO_TO_RIGHTMASK(index);
        } else {
            right_mask = left_mask;
            left_mask = 0;
        }
        this = *src_ad;
        *dest_ad = *dest_ad & left_mask
                 | (this << first_shift | prev >> second_shift) & right_mask;
}   }

/* splice in and/or out of array */

int mm_array_splice (mm_array *array, IV index, IV del_count,
                      SV **delSVs, IV add_count, SV **addSVs, int prelocked) {
    UV old_entries, new_entries;
    size_t size;
    IV i, shift_count, ret=0;

    if (!mm_checkArg (array, ARRAY)) return 0;

    if (add_count < 0) {
        mm_err_oper ((int)add_count, "add count");
        return 0;
    }
    if (del_count < 0) {
        mm_err_oper ((int)del_count, "delete count");
        return 0;
    }
    if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {

        if (index < 0
            /* if deleting entries, they must exist */
         || del_count
         && index + del_count - 1 >= array->entries) {

            mm_err_oper ((int)index, "index");
            prelocked || mm_unlock(array->mm);
            return 0;
        }

        /* if adding data above the current entries,
            (we can't also be deleting or the test above will give an error)
            call storesize to add entries between */
        old_entries = array->entries;
        if (add_count > 0
         || index <= old_entries
         || mm_array_storesize (array, index, 1)) {

            /* save any deleted entries for return */
            for (i = 0; i < del_count; i++)
                delSVs[i] = mm_array_fetch (array, index + i, 1);

            /* if 1) GP array,
                  2) we're at the end of the array, and
                  3) entries below are undefined, delete them */

            if (array->type == MM_ARRAY
             && (i = index)
             && index + del_count == array->entries) {

                while (--i >= 0 && *((void **)(array->ptr) + i) == NULL) {
                    index--;
                    del_count++;
            }   }

            /* if adds == deletes there's not much to do */
            if (shift_count = add_count - del_count) {

                new_entries = array->entries + shift_count;

                /* give up if the array needs to grow and it can't because memory is full */
                if (shift_count > 0
                 && !mm_array_extend (array, new_entries, 1)) {
                    prelocked || mm_unlock(array->mm);
                    return 0;
                }
                /* this splice should work!
                    call the appropriate routine to expand or contract the array */
                if (size = mm_type_size (array->type)) {
                    if (shift_count > 0)
                         mm_array_splice_expand  (array, index,
                                                  shift_count, size);
                    else mm_array_splice_contract(array, index+add_count,
                                                  -shift_count, size, new_entries);

                } else {
                    /* boolean array */
                    if (shift_count > 0)
                         mm_array_splice_bool_expand  (array, index,
                                                        shift_count, new_entries);
                    else mm_array_splice_bool_contract(array, index+add_count,
                                                       -shift_count, new_entries);
                }

                /* set the new number of entries */
                array->entries = new_entries;

                /* it's no big deal if the block-shrink loses
                    because the shared memory is close to being full */
                if (shift_count < 0) mm_array_extend (array, new_entries, 1);
            }
            /* if we're adding and/or deleting at the start of the array,
                track the total of such adds and deletes in array->shiftCount
                                 (which is the count of deletes at the front) */
            if (!index
             && (del_count
              || add_count && old_entries)) array->shiftCount -= shift_count;

            /* store added entries (if any) */
            ret = 1;
            for (i = 0; i < add_count; i++) {
                if (!mm_array_store (array, index++, addSVs[i], -1)) ret = 0;
            }
        } /* if storesize lost, it made an error message */

        /* release any lock we set, but not an external one */
        prelocked || mm_unlock(array->mm);
    } else mm_err_cant_lock();
    return ret;
}

/* delete one element of an array
    this routine is not called if the XSUB (see last part of this file) detects
        deleting the last element of the array, in which case it calls splice */

SV *mm_array_delete (mm_array *array, IV index, int prelocked) {
    UV mask;
    char *ptr, *valPtr;
    STRLEN len;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (array, ARRAY)) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {
            if (index >= 0 && index < array->entries) {

                sv = mm_array_fetch (array, index, 1);
                ptr = array->ptr;

                switch (array->type) {

                    case MM_ARRAY:
                        ptr += index * sizeof(void *);
                        valPtr = *((void **)ptr);
                        if (valPtr > ZERO_LEN) mma_free (array->mm, valPtr);
                        *((void **)ptr) = NULL;
                        break;

                    case MM_BOOL_ARRAY:
                        ptr += BITNO_TO_UV_OFFSET(index) * UVSIZE;
                        mask = BITNO_TO_BITMASK(index);
                        *(UV *)ptr &= ~mask;
                        break;
                    case MM_DOUBLE_ARRAY:
                        ptr += index * NVSIZE;
                        memset (ptr, 0, NVSIZE);
                        break;
                    case MM_INT_ARRAY:
                    case MM_UINT_ARRAY:
                        *((IV *)ptr + index) = 0;
                        break;
                    /* positive type value is a fixed-length string or record */
                    default:
                        len = (STRLEN)((array->type) >> 1);
                        ptr += index * len;
                        memset (ptr, 0, len);
                }
                prelocked || mm_unlock(array->mm);
            } else mm_err_oper ((int)index, "index");
        } else mm_err_cant_lock();
    }
    return sv;
}

/* delete all elements of an array */

void mm_array_clear (mm_array *array, UV entries, int prelocked) {
    size_t initLen;
    char **ptr, *valPtr;
    UV i;

    if (mm_checkArg (array, ARRAY)) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {

            if (i = array->entries) {
                if (array->type == MM_ARRAY) {
                    /* free the blocks used for values */
                    ptr = (char **)array->ptr;
                    while (i--) {
                        valPtr = *ptr++;
                        if (valPtr > ZERO_LEN) {
                            mma_free (array->mm, valPtr);
                        }
            }   }   }
            initLen = mm_alloc_len (array->type, entries);
            if (ptr = mma_calloc(array->mm, 1, initLen)) {
                mma_free (array->mm, array->ptr);
                array->ptr = (char *)ptr;
            } else memset (array->ptr, 0, mm_sizeof (array->mm, array->ptr));
            array->entries = array->shiftCount = 0;
            prelocked || mm_unlock(array->mm);
        } else mm_err_cant_lock();
}   }

/* free all of the memory used by an array */

void mm_free_array (mm_array *array, int prelocked) {

    if (mm_checkArg (array, ARRAY)) {
        if (prelocked || mm_lock(array->mm, MM_LOCK_RW)) {
            mm_array_clear (array, 0, 1);
            mma_free (array->mm, array->ptr);
            mma_free (array->mm, array);
            prelocked || mm_unlock(array->mm);
        } else mm_err_cant_lock;
}   }

/*------------------------------------- hashes ------------------------------------*/

/* undefs vs. zero-length strings in hashes:
    a hash store is not allowed if either the key or value is/are undef
        but either the key or value can be zero-length strings
    a zero-length key is indicated by the key entry containing just the value pointer
    a zero-length value is indicated by the value pointer being NULL */

/*  create a new hash  */

mm_hash *mm_make_hash (MM *mm, IV entries, int prelocked) {
    mm_hash *hash = NULL;
    if (mm_checkMM (mm)) {
        if (prelocked || mm_lock(mm, MM_LOCK_RW)) {
            if (entries <= 0) entries = DELTA_ENTRIES;

            /* get a cleared block of memory for header */
            if (hash = mma_calloc (mm, 1, sizeof(mm_hash))) {
                /* store the pointer to the overall
                   shared memory structure in the hash */
                hash->mm = mm;
                /* allocate the pointer table and store pointer to it in the hash */
                if (!(hash->ptr = mma_calloc (mm, 1,
                                              mm_round_up(entries*sizeof(void *))))) {
                    mma_free (mm, hash);
                    hash = NULL;
            }   }
            prelocked || mm_unlock(mm);
        } else mm_err_cant_lock();
    }
    return hash;
}

/* return pointer to the entry of a specified key in a hash (NULL if no match)
     for internal use only
     callers must validate operands thru SvOK(key) */

mm_hash_entry *mm_hash_find_entry (mm_hash *hash, SV *key,
                                   mm_hash_entry ***lastPtr) {
    STRLEN keyLen, entryKeyLen, cmpLen;
    UV upper_bound, ix;
    IV cmp = 0, lower_bound = -1;
    mm_hash_entry **ptr = hash->ptr;
    mm_hash_entry *entry = NULL;
    void *keyPtr = SvPV(key, keyLen);

    /* start in the middle of the table of entries (lower_bound starts -1) */
    upper_bound = hash->entries;

    /* binary search through the hash table */
    while (upper_bound - lower_bound > 1) {

        /* start halfway between the upper and lower bound */
        ix = (lower_bound + upper_bound) >> 1;

        if (!(entry = *(ptr = hash->ptr + ix))) {
            /* MAJOR PANIC: NULL inside hash array */
            mm_unlock(hash->mm);
            croak ("mm_hash_find_entry: NULL in hash array");
        }
        entryKeyLen = mm_sizeof (hash->mm, entry) - sizeof(void *);
        cmpLen = entryKeyLen <= keyLen ? entryKeyLen : keyLen;

        /* break out of while if matching entry */
        if (!(cmp = memcmp (keyPtr, &entry->key, cmpLen))
         && keyLen == entryKeyLen) break;

        /* if the keys compared equal within the shorter of their lengths,
            consider the shorter key to be the lesser */
        if (!cmp) cmp = (keyLen < entryKeyLen ? -1 : 1);
        entry = NULL;
        if (cmp < 0) upper_bound = ix;
        else         lower_bound = ix;
    }
    if (lastPtr) *lastPtr = cmp > 0 ? ptr+1 : ptr;
    return entry;
}

/*  return the value of a specified key  */

SV *mm_hash_fetch (mm_hash *hash, SV *key, int prelocked) {
    mm_hash_entry *entry;
    void *valPtr;
    SV *val = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        if (SvOK(key) && !SvROK(key)) {
            if (prelocked || mm_lock(hash->mm, MM_LOCK_RD)) {

                /* Almost all the work is in the routine to find the entry */
                if (entry = mm_hash_find_entry (hash, key, NULL)) {

                    /* found, return the value */
                    if (!(valPtr = entry->valPtr)) val = &PL_sv_no;
                    else val = newSVpv (valPtr, mm_sizeof (hash->mm, valPtr));
                }
                prelocked || mm_unlock(hash->mm);
            } else mm_err_cant_lock();
        } else mm_err_sv(val, "key", 0);
    }
    return val;
}

/* get a hash entry by its index: returns ($key, $value) */

void mm_hash_get_entry (mm_hash *hash, IV index, int prelocked, SV **ret) {
    mm_hash_entry *entry;
    void *valPtr;
    STRLEN keyLen;

    ret[0] = ret[1] = &PL_sv_undef;
    if (mm_checkArg (hash, HASH)) {
        if (prelocked || mm_lock (hash->mm, MM_LOCK_RD)) {
            if (index >= 0 && index < hash->entries) {
                if (entry = *(hash->ptr + index)) {

                    /* all is well, return the key and value */
                    keyLen = mm_sizeof (hash->mm, entry) - sizeof (void *);
                    if (keyLen)
                         ret[0] = newSVpvn((void *)&entry->key, keyLen);
                    else ret[0] = &PL_sv_no;

                    if (valPtr = entry->valPtr)
                         ret[1] = newSVpvn(valPtr, mm_sizeof (hash->mm, valPtr));
                    else ret[1] = &PL_sv_no;
                } else {
                    mm_unlock(hash->mm);
                    croak ("mm_hash_get_entry: NULL in hash array");
                }
            } else mm_err_oper ((int)index, "index");
            prelocked || mm_unlock(hash->mm);
        } else mm_err_cant_lock();
    }
}

/*  return whether a specified key exists in a hash */

SV *mm_hash_exists (mm_hash *hash, SV *key, int prelocked) {
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        if (SvOK(key) && !SvROK(key)) {
            if (prelocked || mm_lock(hash->mm, MM_LOCK_RD)) {

                /* all the work is in the routine to find the entry */
                sv = mm_hash_find_entry (hash, key, NULL) ? &PL_sv_yes
                                                          : &PL_sv_no;
                prelocked || mm_unlock(hash->mm);
            } else mm_err_cant_lock();
        } else mm_err_sv(key, "key", 0);
    }
    return sv;
}

/*  store an entry in a hash */

int mm_hash_store (mm_hash *hash, SV *key, SV *val, UV flags, int prelocked) {
    STRLEN keyLen, valLen, moveLen;
    mm_hash_entry *entry, **ptr, **lastPtr;
    UV new_entries;
    char *keyPtr, *valPtr;
    char *mmValPtr = NULL;
    int ret=0;

    if (mm_checkArg (hash, HASH)) {
        if (SvOK(key) && !SvROK(key)) {
            if (SvOK(val) && !SvROK(val)) {
                if (prelocked || mm_lock(hash->mm, MM_LOCK_RW)) {
                    keyPtr = SvPV(key, keyLen);
                    valPtr = SvPV(val, valLen);

                    /* see if the key is already in the hash */
                    if (entry = mm_hash_find_entry (hash, key, &lastPtr)) {

                        /* the key already exists in the hash */
                        if (!(flags & MM_NO_OVERWRITE)) {
                            if (mmValPtr = entry->valPtr) {
                                if (!valLen) {
                                    mma_free (hash->mm, mmValPtr);
                                    mmValPtr = NULL;
                                } else if (!mma_sizeok(mmValPtr, valLen)) {
                                    /* we don't use realloc because it loses memory */
                                    if (ptr = mma_malloc (hash->mm, valLen))
                                        mma_free (hash->mm, mmValPtr);
                                    mmValPtr = (char *)ptr;
                                }
                            } else if (valLen) mmValPtr = mma_malloc (hash->mm, valLen);
                        } else mm_err_set (
                            "not stored because MM_NO_OVERWRITE specified and key already exists");
                        ret = !valLen || mmValPtr != NULL;
                    } else {

                        /* new key */
                        if (!(flags & MM_NO_CREATE)) {
                            if (entry = mma_calloc(hash->mm, 1, keyLen + sizeof(void *))) {
                                /* allocate the value block if the value
                                   is not a zero-length string */
                                if (valLen && !(mmValPtr = mma_malloc (hash->mm, valLen))) {
                                    mma_free (hash->mm, entry);
                                } else {
                                    /* either we don't need an mmValPtr, or we have one */
                                    ptr = hash->ptr;
                                    if ((moveLen = mm_sizeof(hash->mm, ptr))
                                  /* the = is the important detail */
                                        <= hash->entries * sizeof (void *)) {

                                        /* grow the pointer array:
                                            decide on a larger number of entries */

                                        if (hash->entries >= DELTA_ENTRIES)
                                            new_entries = hash->entries + DELTA_ENTRIES;
                                        else for (new_entries = DELTA_ENTRIES;
                                                  (new_entries >> 1) > hash->entries;
                                                  new_entries >>= 1);

                                        /* grow the pointer array
                                            we don't use realloc 'cause it loses memory */
                                        if (ptr = mma_calloc (hash->mm, (size_t)new_entries,
                                                              sizeof(void *))) {
                                            memcpy (ptr, hash->ptr, moveLen);
                                            mma_free (hash->mm, hash->ptr);
                                            lastPtr = ptr + (lastPtr - hash->ptr);
                                            hash->ptr = ptr;
                                    }   }
                                    if (ptr) {

                                        /* shift the entries whose keys are greater than this
                                            new key, to the right in the pointer array */
                                        moveLen = (char *)(ptr + hash->entries++) - (char *)lastPtr;
                                        if (moveLen)
                                            memmove (lastPtr + 1, lastPtr, moveLen);

                                        /* store the pointer to this entry in the array */
                                        *lastPtr = entry;

                                        /* move the key into the entry block */
                                        memcpy (&entry->key, keyPtr, keyLen);
                                        ret = 1;
                                    } else {
                                        /* we need to expand the hash table and can't,
                                            so give back the entry block and value block if any */
                                        mma_free (hash->mm, mmValPtr);
                                        mma_free (hash->mm, entry);
                                    } /* ptr / no ptr */
                                } /* lose or OK alloc valPtr */
                            } /* mma_calloc 'entry' fail will make its own error message */
                        } else mm_err_set (
                                "not stored because MM_NO_CREATE specified and key does not exist");
                    } /* existing or new key */

                    if (ret) {
                        /* put the link to the value block (if any) into the entry block */
                        entry->valPtr = mmValPtr;
                        /* copy the value (if any) to the value block */
                        if (valLen) memcpy (mmValPtr, valPtr, valLen);
                    }
                    prelocked || mm_unlock(hash->mm);
                } else mm_err_cant_lock();
            } else mm_err_sv (val, "value", 0);
        } else mm_err_sv (key, "key", 0);
    }
    return ret;
}

/* remove an entry from a hash */

SV* mm_hash_delete (mm_hash *hash, SV *key, int prelocked) {
    mm_hash_entry *entry, **ptr;
    UV alloc_entries;
    STRLEN newlen;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        if (SvOK(key) && !SvROK(key)) {
            if (prelocked || mm_lock(hash->mm, MM_LOCK_RW)) {
                if (entry = mm_hash_find_entry (hash, key, &ptr)) {

                    /* if the entry has a value, return it */
                    if (entry->valPtr) sv = newSVpv (entry->valPtr,
                                                     mm_sizeof (hash->mm, entry->valPtr));
                    else sv = &PL_sv_no;

                    /* shift the entries above this one down */
                    memcpy (ptr, ptr+1, (char *)(hash->ptr + --hash->entries) - (char *)ptr);

                    /* return the value block and entry block to shared memory */
                    if (entry->valPtr) mma_free(hash->mm, entry->valPtr);
                    mma_free(hash->mm, entry);

                    /* see if it's time to shrink the pointer block */
                    alloc_entries = mm_sizeof (hash->mm, hash->ptr) / sizeof (void *);

                    if (alloc_entries - hash->entries > DELTA_ENTRIES) {
                        if (alloc_entries >= DELTA_ENTRIES<<1) alloc_entries -= DELTA_ENTRIES;
                        else alloc_entries = DELTA_ENTRIES;

                        /* we don't use realloc 'cause it loses memory */
                        newlen = (STRLEN)(alloc_entries * sizeof(void *));
                        if (ptr = mma_malloc (hash->mm, newlen)) {
                            memcpy (ptr, hash->ptr, newlen);
                            mma_free (hash->mm, hash->ptr);
                            hash->ptr = ptr;
                    }   }
                } /* key found in hash */
                prelocked || mm_unlock(hash->mm);
            } else mm_err_cant_lock();
        } else mm_err_sv(sv, "key", 0);
    }
    return sv;
}

/* return the number of entries in the hash */

SV *mm_hash_scalar (mm_hash *hash) {
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        sv = newSVuv(hash->entries);
    }
    return sv;
}

/*  return the first key in a hash */

SV *mm_hash_first_key (mm_hash *hash, int prelocked) {
    mm_hash_entry *entry;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        if (prelocked || mm_lock(hash->mm, MM_LOCK_RD)) {
            if (hash->entries && (entry = *hash->ptr)) {
                if (entry->valPtr)
                    sv = newSVpvn ((void *)&entry->key,
                                   mm_sizeof (hash->mm, entry) - sizeof(void *));
                /* only the first hash entry can have a zero-length key */
                else return &PL_sv_no;
            } /* something in the hash */
            prelocked || mm_unlock(hash->mm);
        } else mm_err_cant_lock();
    }
    return sv;
}

/*  return the next key in a hash */

SV *mm_hash_next_key (mm_hash *hash, SV *prevKey, int prelocked) {
    mm_hash_entry *entry, **ptr;
    SV *sv = &PL_sv_undef;

    if (mm_checkArg (hash, HASH)) {
        if (SvOK(prevKey) && !SvROK(prevKey)) {
            if (prelocked || mm_lock(hash->mm, MM_LOCK_RD)) {

                /* find the entry that the caller gave us as previous */
                if (entry = mm_hash_find_entry (hash, prevKey, &ptr)) {
                    if (++ptr < hash->ptr + hash->entries) {
                        if (entry = *ptr) {

                            sv = newSVpvn ((void *)&entry->key,
                                        mm_sizeof (hash->mm, entry) - sizeof(void *));
                        } else {
                            mm_unlock(hash->mm);
                            croak ("mm_hash_next_key: NULL in hash array");
                }   }   }
                prelocked || mm_unlock(hash->mm);
            } else mm_err_cant_lock();
        } else mm_err_sv(sv, "key", 0);
    }
    return sv;
}

/*  delete all the entries in a hash */

void mm_hash_clear (mm_hash *hash, IV entries, int prelocked) {
    mm_hash_entry *entry, **ptr;

    if (mm_checkArg (hash, HASH)) {
        if (prelocked || mm_lock(hash->mm, MM_LOCK_RW)) {

            ptr = hash->ptr;
            while (hash->entries) {
                if (entry = *ptr++) {
                    if (entry->valPtr) mma_free (hash->mm, entry->valPtr);
                    mma_free (hash->mm, entry);
                }
                hash->entries--;
            }
            if (entries <= 0) entries = DELTA_ENTRIES;

            if (ptr = mma_calloc (hash->mm, 1, mm_round_up(entries*sizeof(void *)))) {
                mma_free (hash->mm, hash->ptr);
                hash->ptr = ptr;
            } else {
                memset (hash->ptr, 0, mm_sizeof (hash->mm, hash->ptr));
            }
            prelocked || mm_unlock(hash->mm);
        } else mm_err_cant_lock();
}   }

/*  free all the memory used by a hash */

void mm_free_hash (mm_hash *hash, int prelocked) {

    if (mm_checkArg (hash, HASH)) {
        if (prelocked || mm_lock(hash->mm, MM_LOCK_RW)) {

            /* return memory used for keys and values */
            mm_hash_clear (hash, 0, 1);
            /* return memory used for the header table */
            mma_free (hash->mm, hash->ptr);
            /* return the memory used for the hash header block */
            mma_free (hash->mm, hash);
            prelocked || mm_unlock(hash->mm);
        } else mm_err_cant_lock;
}   }

MODULE = IPC::MMA       PACKAGE = IPC::MMA

PROTOTYPES: DISABLE

# so that MMA.pm can call constant in MMA.xs
double
constant(name,arg)
    char *name
    int  arg

#------------------------- pass-throughs and basics -----------------------

MM *
mm_create(size, file)
    size_t size
    char *file

int
mm_permission(mm, mode, owner, group)
    MM *mm
    int mode
    int owner
    int group

void
mm_destroy(mm)
    MM *mm

size_t
mm_maxsize()

size_t
mm_available(mm)
    MM *mm

char *
mm_error()

void
mm_display_info(mm)
    MM *mm

int
mm_lock(mm, mode)
    MM *mm
    mm_lock_mode mode

int
mm_unlock(mm)
    MM *mm

void
mm_alloc_size ()
    PPCODE:
        if (GIMME_V == G_ARRAY) {
            EXTEND(SP, 6);
            XPUSHs(sv_2mortal(newSVuv((UV)mma_alloc_mask()+1)));
            XPUSHs(sv_2mortal(newSVuv((UV)mma_alloc_base())));
            XPUSHs(sv_2mortal(newSVuv((UV)sizeof(void *))));
            XPUSHs(sv_2mortal(newSVuv((UV)IVSIZE)));
            XPUSHs(sv_2mortal(newSVuv((UV)NVSIZE)));
            XPUSHs(sv_2mortal(newSVuv((UV)DELTA_ENTRIES)));
        } else {
            XPUSHs(sv_2mortal(newSVuv((UV)mma_alloc_mask()+1)));
        }

size_t
mm_round_up (size)
    size_t size

#------------------------------------- scalars ------------------------------------

mm_scalar *
mm_make_scalar(mm)
    MM *mm
    ALIAS:
        mma_make_scalar=1
    CODE:
        RETVAL = mm_make_scalar(mm, ix);
    OUTPUT:
        RETVAL

void
mm_free_scalar(scalar)
    mm_scalar *scalar
    ALIAS:
        mma_free_scalar=1
    CODE:
        mm_free_scalar(scalar, ix);

SV *
mm_scalar_fetch(scalar)
    mm_scalar *scalar
    ALIAS:
        mma_scalar_fetch=1
        mm_scalar_get=2
        mma_scalar_get=3
    CODE:
        RETVAL = mm_scalar_fetch(scalar, ix&1);
    OUTPUT:
        RETVAL

int
mm_scalar_store(scalar, sv)
    mm_scalar *scalar
    SV *sv
    ALIAS:
        mma_scalar_store=1
        mm_scalar_set=2
        mma_scalar_set=3
    CODE:
        RETVAL = mm_scalar_store(scalar, sv, ix&1);
        if (!RETVAL && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
    OUTPUT:
        RETVAL

#------------------------------------- arrays ------------------------------------

mm_array *
mm_make_array(mm, type, entries=0, option=0)
    MM *mm
    IV type
    IV entries
    UV option
    ALIAS:
        mma_make_array=1
    CODE:
        RETVAL = mm_make_array(mm, type, entries, option, ix);
    OUTPUT:
        RETVAL

void
mm_array_status (array)
    mm_array *array
    ALIAS:
        mma_array_status=1
    PREINIT:
        IV statArray[4];
        int i=0;
    PPCODE:
        mm_array_status (array, statArray, ix);
        if (GIMME_V == G_ARRAY) {
            if (statArray[0] >= 0) {
                EXTEND(SP, 4);
                while (i < 4) XPUSHs (sv_2mortal (newSViv(statArray[i++])));
        }   } else {
            if (statArray[0] >= 0) {
                XPUSHs (sv_2mortal (newSViv(statArray[0])));
            } else XPUSHs (&PL_sv_undef);
        }

SV *
mm_array_fetch (array, index)
    mm_array *array
    IV index
    ALIAS:
        mma_array_fetch=1
        mm_array_fetch_nowrap=2
        mma_array_fetch_nowrap=3
    CODE:
        if (index < 0 && !(ix & 2)) index += array->entries;
        RETVAL = mm_array_fetch(array, index, ix&1);
    OUTPUT:
        RETVAL

int
mm_array_store (array, index, sv)
    mm_array *array
    IV index
    SV *sv
    ALIAS:
        mma_array_store=1
        mm_array_store_nowrap=2
        mma_array_store_nowrap=3
    CODE:
        if (index < 0 && !(ix & 2)) index += array->entries;
        RETVAL = mm_array_store(array, index, sv, ix&1);
        if (!RETVAL && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
    OUTPUT:
        RETVAL

UV
mm_array_fetchsize (array)
    mm_array *array
    ALIAS:
        mma_array_fetchsize=1

int
mm_array_extend (array, entries)
    mm_array *array
    IV entries
    ALIAS:
        mma_array_extend=1
    CODE:
        RETVAL = mm_array_extend(array, entries, ix);
        if (!RETVAL && PL_dowarn) warn("IPC::MMA: %s", mm_error());
    OUTPUT:
        RETVAL

int
mm_array_storesize (array, entries)
    mm_array *array
    IV entries
    ALIAS:
        mma_array_storesize=1
    CODE:
        RETVAL = mm_array_storesize(array, entries, ix);
        if (!RETVAL && PL_dowarn) warn("IPC::MMA: %s", mm_error());
    OUTPUT:
        RETVAL

int
mm_array_exists (array, index)
    mm_array *array
    IV index
    ALIAS:
        mma_array_exists=1
        mm_array_exists_nowrap=2
        mma_array_exists_nowrap=3
    CODE:
        if (index < 0 && !(ix & 2)) index += array->entries;
        RETVAL = mm_array_exists (array, index);
    OUTPUT:
        RETVAL

void
mm_array_splice (array, offset, length, ...)
    mm_array *array
    SV *offset
    SV *length
    ALIAS:
        mma_array_splice=1
        mm_array_splice_nowrap=2
        mma_array_splice_nowrap=3
    PREINIT:
        IV index = SvOK(offset) ? SvIV(offset) < 0 && !(ix & 2) ? SvIV(offset)
                                                                  + array->entries
                                                                : SvIV(offset)
                                : 0;
        UV del_count = SvOK(length) ? SvUV(length) : array->entries - index;
        SV *delSVs[del_count];
        UV add_count = items>3 ? items-3 : 0;
        SV *addSVs[add_count];
        int i;
    PPCODE:
        for (i=0; i<add_count; i++) addSVs[i] = ST(i+3);
        if (!mm_array_splice (array,index,del_count,delSVs,add_count,addSVs,ix&1)) {
            if (PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
            del_count = 0;
        }
        /* "in scalar context, splice returns the last entry deleted"
           means just return all of them in either scalar or array mode */
        if (del_count || GIMME_V == G_ARRAY) {
            EXTEND (SP, del_count);
            for (i=0; i<del_count; i++) XPUSHs(sv_2mortal(delSVs[i]));
        } else XPUSHs (&PL_sv_undef);

SV *
mm_array_delete (array, index)
    mm_array *array
    IV index
    ALIAS:
        mma_array_delete=1
        mm_array_delete_nowrap=2
        mma_array_delete_nowrap=3
    PREINIT:
        SV *ret;
    CODE:
        if (index < 0 && !(ix & 2)) index += array->entries;
        if (array && index == array->entries - 1) {
            if (!mm_array_splice (array, index, 1, &ret, 0, NULL, ix&1)
             && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
            RETVAL = ret;
        } else {
            RETVAL = mm_array_delete (array, index, ix&1);
        }
    OUTPUT:
        RETVAL

UV
mm_array_push (array, ...)
    mm_array *array
    ALIAS:
        mma_array_push=1
    PREINIT:
        int add_count = items - 1;
        SV *addSVs[add_count];
        int i;
    CODE:
        for (i=0; i < add_count; i++) addSVs[i] = ST(i+1);
        if (!mm_array_splice (array, array->entries, 0, NULL, add_count, addSVs, ix)
         && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
        RETVAL = array->entries;
    OUTPUT:
        RETVAL

SV *
mm_array_pop (array)
    mm_array *array
    ALIAS:
        mma_array_pop=1
    PREINIT:
        SV *ret;
    CODE:
        if (!mm_array_splice (array, array->entries - 1, 1, &ret, 0, NULL, ix)
         && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
        RETVAL = ret;
    OUTPUT:
        RETVAL

SV *
mm_array_shift (array)
    mm_array *array
    ALIAS:
        mma_array_shift=1
    PREINIT:
        SV *ret;
    CODE:
        if (!mm_array_splice (array, 0, 1, &ret, 0, NULL, ix)
         && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
        RETVAL = ret;
    OUTPUT:
        RETVAL

UV
mm_array_unshift(array, ...)
    mm_array *array
    ALIAS:
        mma_array_unshift=1
    PREINIT:
        int add_count = items - 1;
        SV *addSVs[add_count];
        int i;
    CODE:
        for (i=0; i < add_count; i++) addSVs[i] = ST(i+1);
        if (!mm_array_splice (array, 0, 0, NULL, add_count, addSVs, ix)
         && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
        RETVAL = array->entries;
    OUTPUT:
        RETVAL

void
mm_array_clear (array, entries=0)
    mm_array *array
    UV entries
    ALIAS:
        mma_array_clear=1
    CODE:
        mm_array_clear (array, entries, ix);

void
mm_free_array (array)
    mm_array *array
    ALIAS:
        mma_free_array=1
    CODE:
        mm_free_array (array, ix);

#------------------------------------- hashes ------------------------------------

mm_hash *
mm_make_hash(mm, entries=0)
    MM *mm
    IV entries
    ALIAS:
        mma_make_hash=1
        mm_make_btree_table=2
        mma_make_btree_table=3
    CODE:
        RETVAL = mm_make_hash (mm, entries, ix&1);
    OUTPUT:
        RETVAL

SV *
mm_hash_fetch(hash, key)
    mm_hash *hash
    SV *key
    ALIAS:
        mma_hash_fetch=1
        mm_hash_get_value=2
        mma_hash_get_value=3
        mm_hash_get=4
        mma_hash_get=5
        mm_btree_table_get=6
        mma_btree_table_get=7
    CODE:
        RETVAL = mm_hash_fetch (hash, key, ix&1);
    OUTPUT:
        RETVAL

void
mm_hash_get_entry(hash, index)
    mm_hash *hash
    IV index
    ALIAS:
        mma_hash_get_entry=1
    PREINIT:
        SV* ret[2];
    PPCODE:
        mm_hash_get_entry(hash, index, ix, ret);
        if (GIMME_V == G_ARRAY) {
            if (SvOK(ret[0])) {
                EXTEND(SP, 2);
                XPUSHs (sv_2mortal (ret[0]));
                XPUSHs (sv_2mortal (ret[1]));
        }   } else {
            XPUSHs (sv_2mortal (ret[0]));
        }

SV *
mm_hash_exists(hash, key)
    mm_hash *hash
    SV *key
    ALIAS:
        mma_hash_exists=1
        mm_btree_table_exists=2
        mma_btree_table_exists=3
    CODE:
        RETVAL = mm_hash_exists (hash, key, ix&1);
    OUTPUT:
        RETVAL

int
mm_hash_store(hash, key, val, flags=0)
    mm_hash *hash
    SV *key
    SV *val
    UV flags
    ALIAS:
        mma_hash_store=1
        mm_hash_insert=2
        mma_hash_insert=3
        mm_btree_table_insert=4
        mma_btree_table_insert=5
    CODE:
        RETVAL = mm_hash_store (hash, key, val, flags, ix&1);
        if (!RETVAL && PL_dowarn && mm_error()) warn ("IPC::MMA: %s", mm_error());
    OUTPUT:
        RETVAL

SV *
mm_hash_delete(hash, key)
    mm_hash *hash
    SV *key
    ALIAS:
        mma_hash_delete=1
        mm_btree_table_delete=2
        mma_btree_table_delete=3
    CODE:
        RETVAL = mm_hash_delete (hash, key, ix&1);
    OUTPUT:
        RETVAL

SV *
mm_hash_scalar(hash)
    mm_hash *hash
    ALIAS:
        mma_hash_scalar=1
    CODE:
        RETVAL = mm_hash_scalar(ix ? hash : hash);
    OUTPUT:
        RETVAL

SV *
mm_hash_first_key(hash)
    mm_hash *hash
    ALIAS:
        mma_hash_first_key=1
        mm_btree_table_first_key=2
        mma_btree_table_first_key=3
    CODE:
        RETVAL = mm_hash_first_key (hash, ix&1);
    OUTPUT:
        RETVAL

SV *
mm_hash_next_key(hash, key)
    mm_hash *hash
    SV *key
    ALIAS:
        mma_hash_next_key=1
        mm_btree_table_next_key=2
        mma_btree_table_next_key=3
    CODE:
        RETVAL = mm_hash_next_key (hash, key, ix&1);
    OUTPUT:
        RETVAL

void
mm_hash_clear(hash, alloc=0)
    mm_hash *hash
    UV alloc;
    ALIAS:
        mma_hash_clear=1
        mm_clear_btree_table=2
        mma_clear_btree_table=3
    CODE:
        mm_hash_clear (hash, alloc, ix&1);

void
mm_free_hash(hash)
    mm_hash *hash
    ALIAS:
        mma_free_hash=1
        mm_free_btree_table=2
        mma_free_btree_table=3
    CODE:
        mm_free_hash (hash, ix&1);
