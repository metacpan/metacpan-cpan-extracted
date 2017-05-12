/*
  MzScheme
  Copyright (c) 2004 PLT Scheme, Inc.
  Copyright (c) 1995-2001 Matthew Flatt
  All rights reserved.

  Please see the full copyright in the documentation.

  Originally based on:
  libscheme
  Copyright (c) 1994 Brent Benson
  All rights reserved.
*/

#ifndef SCHEME_H
#define SCHEME_H

/* The next line is used and set during installation: */
#define INCLUDE_WITHOUT_PATHS

/*========================================================================*/
/*                           configuration                                */
/*========================================================================*/

/* The configuration is not intended to be adjusted here. Instead,
   modify sconfig.h. The code below simply draws a few more
   configuration conclusions and a few extra macros based on those
   settings. */

#ifdef INCLUDE_WITHOUT_PATHS
# include "sconfig.h"
#else
# include "../sconfig.h"
#endif

#ifdef INCLUDE_WITHOUT_PATHS
# include "schvers.h"
#else
# include "../src/schvers.h"
#endif

#if defined(__MWERKS__)
# ifdef MZSCHEME_USES_NEAR_GLOBALS
#  pragma far_data off
# endif
#endif

#if SGC_STD_DEBUGGING
# ifndef USE_SENORA_GC
#  define USE_SENORA_GC
# endif
# define USE_MEMORY_TRACING
#endif

#ifdef MZ_PRECISE_GC
# define MUST_REGISTER_GLOBALS
# define MZTAG_REQUIRED
# undef UNIX_IMAGE_DUMPS
/* In case SGC is used to build PRECISE_GC: */
# undef USE_SENORA_GC
#endif

#ifdef USE_SENORA_GC
# define MUST_REGISTER_GLOBALS
# undef UNIX_IMAGE_DUMPS
#endif

#ifdef USE_SINGLE_FLOATS
# define MZ_USE_SINGLE_FLOATS
#endif

#ifdef DONT_ITIMER
# undef USE_ITIMER
#endif

#if defined(USE_ITIMER) || defined(USE_WIN32_THREAD_TIMER)
# define FUEL_AUTODECEREMENTS
#endif

#ifdef MZ_PRECISE_GC
# define MZ_HASH_KEY_EX  short keyex;
#else
# define MZ_HASH_KEY_EX /**/
#endif

#ifdef PALMOS_STUFF
# include <PalmOS.h>
typedef long FILE;
# define _LINUX_TYPES_H  /* Blocks types.h */
#endif

#ifndef SCHEME_DIRECT_EMBEDDED
# define SCHEME_DIRECT_EMBEDDED 1
#endif

#ifndef MSC_IZE
# define MSC_IZE(x) x
#endif
#ifndef MSCBOR_IZE
# define MSCBOR_IZE(x) MSC_IZE(x)
#endif

#ifdef SIGSET_IS_SIGNAL
# define MZ_SIGSET(s, f) signal(s, f)
#else
# define MZ_SIGSET(s, f) sigset(s, f)
#endif


#ifdef PALMOS_STUFF
typedef jmpbuf jmp_buf[1];
#endif

#define GC_MIGHT_USE_REGISTERED_STATICS

#ifdef MACINTOSH_EVENTS
/* We avoid #including the Carbon headers because we only
   need a few abstract struct types: */
typedef struct FSSpec mzFSSpec;
#endif

/* Set up MZ_EXTERN for DLL build */
#if defined(WINDOWS_DYNAMIC_LOAD) \
    && !defined(LINK_EXTENSIONS_BY_TABLE) \
    && !defined(SCHEME_EMBEDDED_NO_DLL)
# define MZ_DLLIMPORT __declspec(dllimport)
# ifdef __mzscheme_private__
#  define MZ_DLLSPEC __declspec(dllexport)
# else
#  define MZ_DLLSPEC __declspec(dllimport)
# endif
#else
# define MZ_DLLSPEC
# define MZ_DLLIMPORT
#endif

#define MZ_EXTERN extern MZ_DLLSPEC

/* Define _W64 for MSC if needed. */
#if defined(_MSC_VER) && !defined(_W64)
# if !defined(__midl) && (defined(_X86_) || defined(_M_IX86)) && _MSC_VER >= 1300
# define _W64 __w64
# else
# define _W64
# endif
#endif

/* PPC Linux plays a slimy trick: it defines strcpy() as a macro that
   uses __extension__. This breaks the 3m xform. */
#if defined(MZ_XFORM) && defined(strcpy)
START_XFORM_SKIP;
static inline void _mzstrcpy(char *a, const char *b)
{
  strcpy(a, b);
}
END_XFORM_SKIP;
# undef strcpy
# define strcpy _mzstrcpy
#endif

#ifdef __cplusplus
extern "C"
{
#endif

/*========================================================================*/
/*                        basic Scheme values                             */
/*========================================================================*/

typedef short Scheme_Type;

/* Used to use `short' for app arg counts, etc., but adding limit
   checks is difficult, and seems arbitrary. We can switch back
   to short if the expense turns out to be noticable; in that case
   also define MZSHORT_IS_SHORT. */
typedef int mzshort;

/* MzScheme values have the type `Scheme_Object *'.
   The actual Scheme_Object structure only defines a few variants.
   The important thing is that all `Scheme_Object *'s start with
   a Scheme_Type field.

   The structures are defined here, instead of in a private header, so
   that macros can provide quick access. Of course, don't access the
   fields of these structures directly; use the macros instead. */

typedef struct Scheme_Object
{
  Scheme_Type type; /* Anything that starts with a type field
		       can be a Scheme_Object */

  /* For precise GC, the keyex field is used for all object types to
     store a hash key extension. The low bit is not used for this
     purpose, though. For string, pair, vector, and box values in all
     variants of MzScheme, the low bit is set to 1 to indicate that
     the object is immutable. */
  short keyex;

  union
    {
      struct { char *string_val; int tag_val; } str_val;
      struct { void *ptr1, *ptr2; } two_ptr_val;
      struct { int int1; int int2; } two_int_val;
      struct { void *ptr; int pint; } ptr_int_val;
      struct { void *ptr; long pint; } ptr_long_val;
      struct { struct Scheme_Object *car, *cdr; } pair_val;
      struct { mzshort len; mzshort *vec; } svector_val;
    } u;
} Scheme_Object;

typedef struct Scheme_Object *(*Scheme_Closure_Func)(struct Scheme_Object *);

/* Scheme_Small_Object is used for several types of MzScheme values: */
typedef struct {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  union {
    char char_val;
    Scheme_Object *ptr_value;
    long int_val;
    Scheme_Object *ptr_val;
  } u;
} Scheme_Small_Object;

/* A floating-point number: */
typedef struct {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  double double_val;
} Scheme_Double;

#ifdef MZ_USE_SINGLE_FLOATS
typedef struct {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  float float_val;
} Scheme_Float;
#endif

typedef struct Scheme_Symbol {
  Scheme_Type type;
  short keyex; /* 1 in low bit indicates uninterned */
  int len;
  char s[4]; /* Really, a number of chars to match `len' */
} Scheme_Symbol;

typedef struct Scheme_Vector {
  Scheme_Type type;
  short keyex; /* 1 in low bit indicates immutable */
  int size;
  Scheme_Object *els[1];
} Scheme_Vector;


/* This file defines all the built-in types */
#ifdef INCLUDE_WITHOUT_PATHS
# include "stypes.h"
#else
# include "../src/stypes.h"
#endif

/* This rather elaborate pair of NO-OPS is used to persuade the     */
/* MSVC compiler that we really do want to convert between pointers */
/* and integers. */

#if defined(_MSC_VER)
# define OBJ_TO_LONG(ptr) ((long)(_W64 long)(ptr))
# define LONG_TO_OBJ(l)   ((Scheme_Object *)(void *)(_W64 long)(long)(l))
#else
# define OBJ_TO_LONG(ptr) ((long)(ptr))
# define LONG_TO_OBJ(l) ((Scheme_Object *)(void *)(long)(l))
#endif

/* Scheme Objects are always aligned on 2-byte boundaries, so  */
/* words of type Scheme_Object * will always have zero in the  */
/* least significant bit.  Therefore, we can use this bit as a */
/* tag to indicate that the `pointer' isn't really a pointer   */
/* but a 31-bit signed immediate integer. */

#define SCHEME_INTP(obj)     (OBJ_TO_LONG(obj) & 0x1)

#define SAME_PTR(a, b) ((a) == (b))
#define NOT_SAME_PTR(a, b) ((a) != (b))

#define SAME_OBJ(a, b) SAME_PTR(a, b)
#define NOT_SAME_OBJ(a, b) NOT_SAME_PTR(a, b)

#define SAME_TYPE(a, b) ((Scheme_Type)(a) == (Scheme_Type)(b))
#define NOT_SAME_TYPE(a, b) ((Scheme_Type)(a) != (Scheme_Type)(b))

# define SCHEME_TYPE(obj)     (SCHEME_INTP(obj)?(Scheme_Type)scheme_integer_type:(obj)->type)
# define _SCHEME_TYPE(obj) ((obj)->type) /* unsafe version */

/*========================================================================*/
/*                        basic Scheme predicates                         */
/*========================================================================*/

#define SCHEME_CHARP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_char_type)
/* SCHEME_INTP defined above */
#define SCHEME_DBLP(obj)     SAME_TYPE(SCHEME_TYPE(obj), scheme_double_type)
#ifdef MZ_USE_SINGLE_FLOATS
# define SCHEME_FLTP(obj)     SAME_TYPE(SCHEME_TYPE(obj), scheme_float_type)
# define SCHEME_FLOATP(obj)     (SCHEME_FLTP(obj) || SCHEME_DBLP(obj))
#else
# define SCHEME_FLTP SCHEME_DBLP
# define SCHEME_FLOATP SCHEME_DBLP
#endif
#define SCHEME_BIGNUMP(obj)     SAME_TYPE(SCHEME_TYPE(obj), scheme_bignum_type)
#define SCHEME_RATIONALP(obj)     SAME_TYPE(SCHEME_TYPE(obj), scheme_rational_type)
#define SCHEME_COMPLEXP(obj)     (!SCHEME_INTP(obj) && ((_SCHEME_TYPE(obj) >= scheme_complex_izi_type) && (_SCHEME_TYPE(obj) <= scheme_complex_type)))
#define SCHEME_COMPLEX_IZIP(obj)     (SCHEME_TYPE(obj) == scheme_complex_izi_type)
#define SCHEME_EXACT_INTEGERP(obj)  (SCHEME_INTP(obj) || (_SCHEME_TYPE(obj) == scheme_bignum_type))
#define SCHEME_EXACT_REALP(obj)  (SCHEME_INTP(obj) || (_SCHEME_TYPE(obj) == scheme_bignum_type) || (_SCHEME_TYPE(obj) == scheme_rational_type))
#define SCHEME_REALP(obj)  (SCHEME_INTP(obj) || ((_SCHEME_TYPE(obj) >= scheme_bignum_type) && (_SCHEME_TYPE(obj) <= scheme_complex_izi_type)))
#define SCHEME_NUMBERP(obj)  (SCHEME_INTP(obj) || ((_SCHEME_TYPE(obj) >= scheme_bignum_type) && (_SCHEME_TYPE(obj) <= scheme_complex_type)))

#define SCHEME_STRINGP(obj)  SAME_TYPE(SCHEME_TYPE(obj), scheme_string_type)
#define SCHEME_MUTABLE_STRINGP(obj)  (SCHEME_STRINGP(obj) && SCHEME_MUTABLEP(obj))
#define SCHEME_IMMUTABLE_STRINGP(obj)  (SCHEME_STRINGP(obj) && SCHEME_IMMUTABLEP(obj))

#define SCHEME_SYMBOLP(obj)  SAME_TYPE(SCHEME_TYPE(obj), scheme_symbol_type)

#define SCHEME_STRSYMP(obj) (SCHEME_STRINGP(obj) || SCHEME_SYMBOLP(obj))

#define SCHEME_BOOLP(obj)    (SAME_OBJ(obj, scheme_true) || SAME_OBJ(obj, scheme_false))
#define SCHEME_FALSEP(obj)     SAME_OBJ((obj), scheme_false)
#define SCHEME_TRUEP(obj)     (!SCHEME_FALSEP(obj))
#define SCHEME_EOFP(obj)     SAME_OBJ((obj), scheme_eof)
#define SCHEME_VOIDP(obj)     SAME_OBJ((obj), scheme_void)

#define SCHEME_NULLP(obj)    SAME_OBJ(obj, scheme_null)
#define SCHEME_PAIRP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_pair_type)
#define SCHEME_MUTABLE_PAIRP(obj)    (SCHEME_PAIRP(obj) && SCHEME_MUTABLEP(obj))
#define SCHEME_IMMUTABLE_PAIRP(obj)    (SCHEME_PAIRP(obj) && SCHEME_IMMUTABLEP(obj))
#define SCHEME_LISTP(obj)    (SCHEME_NULLP(obj) || SCHEME_PAIRP(obj))

#define SCHEME_BOXP(obj)     SAME_TYPE(SCHEME_TYPE(obj), scheme_box_type)
#define SCHEME_MUTABLE_BOXP(obj)  (SCHEME_BOXP(obj) && SCHEME_MUTABLEP(obj))
#define SCHEME_IMMUTABLE_BOXP(obj)  (SCHEME_BOXP(obj) && SCHEME_IMMUTABLEP(obj))

#define SCHEME_BUCKTP(obj) SAME_TYPE(SCHEME_TYPE(obj),scheme_bucket_table_type)
#define SCHEME_HASHTP(obj) SAME_TYPE(SCHEME_TYPE(obj),scheme_hash_table_type)

#define SCHEME_VECTORP(obj)  SAME_TYPE(SCHEME_TYPE(obj), scheme_vector_type)
#define SCHEME_MUTABLE_VECTORP(obj)  (SCHEME_VECTORP(obj) && SCHEME_MUTABLEP(obj))
#define SCHEME_IMMUTABLE_VECTORP(obj)  (SCHEME_VECTORP(obj) && SCHEME_IMMUTABLEP(obj))

#define SCHEME_STRUCTP(obj) (SAME_TYPE(SCHEME_TYPE(obj), scheme_structure_type) || SAME_TYPE(SCHEME_TYPE(obj), scheme_proc_struct_type))
#define SCHEME_STRUCT_TYPEP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_struct_type_type)

#define SCHEME_INPORTP(obj)  SAME_TYPE(SCHEME_TYPE(obj), scheme_input_port_type)
#define SCHEME_OUTPORTP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_output_port_type)

#define SCHEME_PROMP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_promise_type)

#define SCHEME_THREADP(obj)   SAME_TYPE(SCHEME_TYPE(obj), scheme_thread_type)
#define SCHEME_CUSTODIANP(obj)   SAME_TYPE(SCHEME_TYPE(obj), scheme_custodian_type)
#define SCHEME_SEMAP(obj)   SAME_TYPE(SCHEME_TYPE(obj), scheme_sema_type)
#define SCHEME_CHANNELP(obj)   SAME_TYPE(SCHEME_TYPE(obj), scheme_channel_type)
#define SCHEME_CHANNEL_PUTP(obj)   SAME_TYPE(SCHEME_TYPE(obj), scheme_channel_put_type)

#define SCHEME_CONFIGP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_config_type)
#define SCHEME_NAMESPACEP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_namespace_type)
#define SCHEME_WEAKP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_weak_box_type)

#define SCHEME_STXP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_stx_type)

#define SCHEME_UDPP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_udp_type)
#define SCHEME_UDP_WAITP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_udp_waitable_type)

#define SCHEME_CPTRP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_c_pointer_type)

#define SCHEME_MUTABLEP(obj) (!((obj)->keyex & 0x1))
#define SCHEME_IMMUTABLEP(obj) ((obj)->keyex & 0x1)

#define GUARANTEE_TYPE(fname, argnum, typepred, typenam)                                \
   (typepred (argv [argnum])                                                            \
        ? argv [argnum]                                                                 \
        : (scheme_wrong_type (fname, typenam, argnum, argc, argv), argv [argnum]))

#define GUARANTEE_BOOL(fname, argnum)      GUARANTEE_TYPE (fname, argnum, SCHEME_BOOLP, "boolean")
#define GUARANTEE_CHAR(fname, argnum)      GUARANTEE_TYPE (fname, argnum, SCHEME_CHARP, "character")
#define GUARANTEE_INTEGER(fname, argnum)   GUARANTEE_TYPE (fname, argnum, SCHEME_INTP, "integer")
#define GUARANTEE_PAIR(fname, argnum)      GUARANTEE_TYPE (fname, argnum, SCHEME_PAIRP, "pair")
#define GUARANTEE_PROCEDURE(fname, argnum) GUARANTEE_TYPE (fname, argnum, SCHEME_PROCP, "procedure")
#define GUARANTEE_STRING(fname, argnum)    GUARANTEE_TYPE (fname, argnum, SCHEME_STRINGP, "string")
#define GUARANTEE_STRSYM(fname, argnum)    GUARANTEE_TYPE (fname, argnum, SCHEME_STRSYMP, "string or symbol")
#define GUARANTEE_SYMBOL(fname, argnum)    GUARANTEE_TYPE (fname, argnum, SCHEME_SYMBOLP, "symbol")

/*========================================================================*/
/*                        basic Scheme accessors                          */
/*========================================================================*/

#define SCHEME_CHAR_VAL(obj) (((Scheme_Small_Object *)(obj))->u.char_val)
#define SCHEME_INT_VAL(obj)  (OBJ_TO_LONG(obj)>>1)
#define SCHEME_DBL_VAL(obj)  (((Scheme_Double *)(obj))->double_val)
#ifdef MZ_USE_SINGLE_FLOATS
# define SCHEME_FLT_VAL(obj)  (((Scheme_Float *)(obj))->float_val)
# define SCHEME_FLOAT_VAL(obj) (SCHEME_DBLP(obj) ? SCHEME_DBL_VAL(obj) : SCHEME_FLT_VAL(obj))
#else
# define SCHEME_FLT_VAL(x) ((float)(SCHEME_DBL_VAL(x)))
# define SCHEME_FLOAT_VAL SCHEME_DBL_VAL
# define scheme_make_float(x) scheme_make_double((double)x)
#endif

#define SCHEME_STR_VAL(obj)  ((obj)->u.str_val.string_val)
#define SCHEME_STRTAG_VAL(obj)  ((obj)->u.str_val.tag_val)
#define SCHEME_STRLEN_VAL(obj)  ((obj)->u.str_val.tag_val)
#define SCHEME_SYM_VAL(obj)  (((Scheme_Symbol *)(obj))->s)
#define SCHEME_SYM_LEN(obj)  (((Scheme_Symbol *)(obj))->len)

#define SCHEME_SYMSTR_OFFSET(obj) ((unsigned long)SCHEME_SYM_VAL(obj)-(unsigned long)(obj))

/* return a `char *' pointing to the string or the symbol name */
#define SCHEME_STRSYM_VAL(obj) (SCHEME_SYMBOLP(obj) ? SCHEME_SYM_VAL(obj) : SCHEME_STR_VAL(obj))

#define SCHEME_BOX_VAL(obj)  (((Scheme_Small_Object *)(obj))->u.ptr_val)

#define SCHEME_CAR(obj)      ((obj)->u.pair_val.car)
#define SCHEME_CDR(obj)      ((obj)->u.pair_val.cdr)

#define SCHEME_CADR(obj)     (SCHEME_CAR (SCHEME_CDR (obj)))
#define SCHEME_CAAR(obj)     (SCHEME_CAR (SCHEME_CAR (obj)))
#define SCHEME_CDDR(obj)     (SCHEME_CDR (SCHEME_CDR (obj)))

#define SCHEME_VEC_SIZE(obj) (((Scheme_Vector *)(obj))->size)
#define SCHEME_VEC_ELS(obj)  (((Scheme_Vector *)(obj))->els)
#define SCHEME_VEC_BASE(obj) SCHEME_VEC_ELS(obj)

#define SCHEME_ENVBOX_VAL(obj)  (*((Scheme_Object **)(obj)))
#define SCHEME_WEAK_BOX_VAL(obj) SCHEME_BOX_VAL(obj)

#define SCHEME_PTR_VAL(obj)  (((Scheme_Small_Object *)(obj))->u.ptr_val)
#define SCHEME_PTR1_VAL(obj) ((obj)->u.two_ptr_val.ptr1)
#define SCHEME_PTR2_VAL(obj) ((obj)->u.two_ptr_val.ptr2)
#define SCHEME_IPTR_VAL(obj) ((obj)->u.ptr_int_val.ptr)
#define SCHEME_LPTR_VAL(obj) ((obj)->u.ptr_long_val.ptr)
#define SCHEME_INT1_VAL(obj) ((obj)->u.two_int_val.int1)
#define SCHEME_INT2_VAL(obj) ((obj)->u.two_int_val.int2)
#define SCHEME_PINT_VAL(obj) ((obj)->u.ptr_int_val.pint)
#define SCHEME_PLONG_VAL(obj) ((obj)->u.ptr_long_val.pint)

#define SCHEME_CPTR_VAL(obj) SCHEME_PTR1_VAL(obj)
#define SCHEME_CPTR_TYPE(obj) ((char *)SCHEME_PTR2_VAL(obj))

#define SCHEME_SET_IMMUTABLE(obj)  (((obj)->keyex |= 0x1))
#define SCHEME_SET_STRING_IMMUTABLE(obj) SCHEME_SET_IMMUTABLE(obj)
#define SCHEME_SET_PAIR_IMMUTABLE(obj) SCHEME_SET_IMMUTABLE(obj)
#define SCHEME_SET_VECTOR_IMMUTABLE(obj) SCHEME_SET_IMMUTABLE(obj)
#define SCHEME_SET_BOX_IMMUTABLE(obj) SCHEME_SET_IMMUTABLE(obj)

/*========================================================================*/
/*               fast basic Scheme constructor macros                     */
/*========================================================================*/

#define scheme_make_integer(i)    LONG_TO_OBJ ((OBJ_TO_LONG(i) << 1) | 0x1)
#define scheme_make_character(ch) (scheme_char_constants[(unsigned char)(ch)])

/*========================================================================*/
/*                          procedure values                              */
/*========================================================================*/

/* Constants for flags in Scheme_Primitive_[Closed]_Proc.
   Do not use them directly. */
#define SCHEME_PRIM_IS_FOLDING 1
#define SCHEME_PRIM_IS_PRIMITIVE 2
#define SCHEME_PRIM_IS_STRUCT_PROC 4
#define SCHEME_PRIM_IS_STRUCT_SETTER 8
#define SCHEME_PRIM_IS_PARAMETER 16
#define SCHEME_PRIM_IS_STRUCT_GETTER 32
#define SCHEME_PRIM_IS_STRUCT_PRED 64
#define SCHEME_PRIM_IS_STRUCT_CONSTR 128
#define SCHEME_PRIM_IS_MULTI_RESULT 256
#define SCHEME_PRIM_IS_GENERIC 512
#define SCHEME_PRIM_IS_USER_PARAMETER 1024
#define SCHEME_PRIM_IS_METHOD 2048

typedef struct Scheme_Object *
(Scheme_Prim)(int argc, struct Scheme_Object *argv[]);

typedef struct Scheme_Object *
(Scheme_Closed_Prim)(void *d, int argc, struct Scheme_Object *argv[]);

typedef struct {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  short flags; /* keep flags at same place as in closed */
  Scheme_Prim *prim_val;
  const char *name;
  mzshort mina, maxa;
} Scheme_Primitive_Proc;

typedef struct {
  Scheme_Primitive_Proc p;
  mzshort minr, maxr;
} Scheme_Prim_W_Result_Arity;

typedef struct {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  short flags; /* keep flags at same place as in unclosed */
  Scheme_Closed_Prim *prim_val;
  void *data;
  const char *name;
  mzshort mina, maxa; /* mina == -2 => maxa is negated case count and
		       record is a Scheme_Closed_Case_Primitive_Proc */
} Scheme_Closed_Primitive_Proc;

typedef struct {
  Scheme_Closed_Primitive_Proc p;
  mzshort minr, maxr;
} Scheme_Closed_Prim_W_Result_Arity;

typedef struct {
  Scheme_Closed_Primitive_Proc p;
  mzshort *cases;
} Scheme_Closed_Case_Primitive_Proc;

#define _scheme_fill_prim_closure(rec, cfunc, dt, nm, amin, amax, flgs) \
  ((rec)->type = scheme_closed_prim_type, \
   (rec)->prim_val = cfunc, \
   (rec)->data = (void *)(dt), \
   (rec)->name = nm, \
   (rec)->mina = amin, \
   (rec)->maxa = amax, \
   (rec)->flags = flgs, \
   rec)

#define _scheme_fill_prim_case_closure(rec, cfunc, dt, nm, ccount, cses, flgs) \
  ((rec)->p.type = scheme_closed_prim_type, \
   (rec)->p.prim_val = cfunc, \
   (rec)->p.data = (void *)(dt), \
   (rec)->p.name = nm, \
   (rec)->p.mina = -2, \
   (rec)->p.maxa = -(ccount), \
   (rec)->p.flags = flgs, \
   (rec)->cases = cses, \
   rec)

#define SCHEME_PROCP(obj)  (!SCHEME_INTP(obj) && ((_SCHEME_TYPE(obj) >= scheme_prim_type) && (_SCHEME_TYPE(obj) <= scheme_proc_struct_type)))
#define SCHEME_SYNTAXP(obj)  SAME_TYPE(SCHEME_TYPE(obj), scheme_syntax_compiler_type)
#define SCHEME_PRIMP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_prim_type)
#define SCHEME_CLSD_PRIMP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_closed_prim_type)
#define SCHEME_CONTP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_cont_type)
#define SCHEME_ECONTP(obj)    SAME_TYPE(SCHEME_TYPE(obj), scheme_escaping_cont_type)
#define SCHEME_PROC_STRUCTP(obj) SAME_TYPE(SCHEME_TYPE(obj), scheme_proc_struct_type)
#define SCHEME_STRUCT_PROCP(obj) (SCHEME_CLSD_PRIMP(obj) && (((Scheme_Closed_Primitive_Proc *)obj)->flags & SCHEME_PRIM_IS_STRUCT_PROC))
#define SCHEME_GENERICP(obj) (SCHEME_CLSD_PRIMP(obj) && (((Scheme_Closed_Primitive_Proc *)obj)->flags & SCHEME_PRIM_IS_GENERIC))
#define SCHEME_CLOSUREP(obj) (SAME_TYPE(SCHEME_TYPE(obj), scheme_closure_type) || SAME_TYPE(SCHEME_TYPE(obj), scheme_case_closure_type))

#define SCHEME_PRIM(obj)     (((Scheme_Primitive_Proc *)(obj))->prim_val)
#define SCHEME_CLSD_PRIM(obj) (((Scheme_Closed_Primitive_Proc *)(obj))->prim_val)
#define SCHEME_CLSD_PRIM_DATA(obj) (((Scheme_Closed_Primitive_Proc *)(obj))->data)
#define SCHEME_CLOS_FUNC(obj) ((Scheme_Closure_Func)SCHEME_CAR(obj))
#define SCHEME_CLOS_DATA(obj) SCHEME_CDR(obj)

/*========================================================================*/
/*                      hash tables and environments                      */
/*========================================================================*/

typedef struct Scheme_Hash_Table
{
  Scheme_Type type;
  short keyex; /* always needed to support immutability */
  int size, count, step;
  Scheme_Object **keys;
  Scheme_Object **vals;
  void (*make_hash_indices)(void *v, long *h1, long *h2);
  int (*compare)(void *v1, void *v2);
  Scheme_Object *mutex;
  int mcount; /* number of non-null keys, <= count */
} Scheme_Hash_Table;


typedef struct Scheme_Bucket
{
  Scheme_Type type;
  MZ_HASH_KEY_EX
  void *val;
  char *key;
} Scheme_Bucket;

typedef struct Scheme_Bucket_Table
{
  Scheme_Type type;
  MZ_HASH_KEY_EX
  int size, count, step;
  Scheme_Bucket **buckets;
  char weak, with_home;
  void (*make_hash_indices)(void *v, long *h1, long *h2);
  int (*compare)(void *v1, void *v2);
  Scheme_Object *mutex;
} Scheme_Bucket_Table;

/* Hash tablekey types, used with scheme_hash_table */
enum {
  SCHEME_hash_string,
  SCHEME_hash_ptr,
  SCHEME_hash_bound_id,
  SCHEME_hash_weak_ptr
};

typedef struct Scheme_Env Scheme_Env;

#define SCHEME_VAR_BUCKET(obj) ((Scheme_Bucket *)(obj))

/*========================================================================*/
/*                    setjmpup (continuation) support                     */
/*========================================================================*/

#ifdef USE_MZ_SETJMP
typedef long mz_pre_jmp_buf[8];
#else
# define mz_pre_jmp_buf jmp_buf
#endif

#ifdef MZ_PRECISE_GC
typedef struct {
  mz_pre_jmp_buf jb;
  long gcvs; /* declared as `long' so it isn't pushed when on the stack! */
  long gcvs_cnt;
} mz_jmp_buf;
#else
# define mz_jmp_buf mz_pre_jmp_buf
#endif

/* Like setjmp & longjmp, but you can jmp to a deeper stack position */
/* Intialize a Scheme_Jumpup_Buf record before using it */

typedef struct Scheme_Jumpup_Buf_Holder {
  Scheme_Type type; /* for precise GC only */
  Scheme_Jumpup_Buf buf;
} Scheme_Jumpup_Buf_Holder;

typedef struct Scheme_Continuation_Jump_State {
  struct Scheme_Escaping_Cont *jumping_to_continuation;
  union {
    Scheme_Object **vals;
    Scheme_Object *val;
  } u;
  mzshort num_vals;
  short is_kill;
} Scheme_Continuation_Jump_State;

/* Although it's really an integer, it seems beneficial to declare the
   mark position counter as a poiner, perhaps due to locality effects. */
#define MZ_MARK_POS_TYPE char*
#define MZ_MARK_STACK_TYPE char*

typedef struct Scheme_Cont_Frame_Data {
  MZ_MARK_POS_TYPE cont_mark_pos;
  MZ_MARK_STACK_TYPE cont_mark_stack;
} Scheme_Cont_Frame_Data;

/*========================================================================*/
/*                              threads                                   */
/*========================================================================*/

typedef void (Scheme_Close_Custodian_Client)(Scheme_Object *o, void *data);
typedef void (*Scheme_Exit_Closer_Func)(Scheme_Object *, Scheme_Close_Custodian_Client *, void *);
typedef Scheme_Object *(*Scheme_Custodian_Extractor)(Scheme_Object *o);

#ifdef MZ_PRECISE_GC
typedef struct Scheme_Object Scheme_Custodian_Reference;
#else
typedef struct Scheme_Custodian *Scheme_Custodian_Reference;
#endif

typedef struct Scheme_Custodian Scheme_Custodian;

typedef int (*Scheme_Ready_Fun)(Scheme_Object *o);
typedef void (*Scheme_Needs_Wakeup_Fun)(Scheme_Object *, void *);
typedef Scheme_Object *(*Scheme_Wait_Sema_Fun)(Scheme_Object *, int *repost);
typedef int (*Scheme_Wait_Filter_Fun)(Scheme_Object *);

/* The Scheme_Thread structure represents a MzScheme thread. */


#if !SCHEME_DIRECT_EMBEDDED
# ifdef LINK_EXTENSIONS_BY_TABLE
#  define scheme_current_thread (*scheme_current_thread_ptr)
# endif
#endif

typedef void (*Scheme_Kill_Action_Func)(void *);

# define BEGIN_ESCAPEABLE(func, data) \
    { mz_jmp_buf savebuf; \
      scheme_push_kill_action((Scheme_Kill_Action_Func)func, (void *)data); \
      memcpy(&savebuf, &scheme_error_buf, sizeof(mz_jmp_buf)); \
      if (scheme_setjmp(scheme_error_buf)) { \
        func(data); \
        scheme_longjmp(savebuf, 1); \
      } else {
# define END_ESCAPEABLE() \
      scheme_pop_kill_action(); \
      memcpy(&scheme_error_buf, &savebuf, sizeof(mz_jmp_buf)); } }


/*========================================================================*/
/*                             parameters                                 */
/*========================================================================*/

enum {
  MZCONFIG_ENV,
  MZCONFIG_INPUT_PORT,
  MZCONFIG_OUTPUT_PORT,
  MZCONFIG_ERROR_PORT,

  MZCONFIG_ENABLE_BREAK,

  MZCONFIG_ERROR_DISPLAY_HANDLER,
  MZCONFIG_ERROR_PRINT_VALUE_HANDLER,

  MZCONFIG_EXIT_HANDLER,

  MZCONFIG_EXN_HANDLER,
  MZCONFIG_INIT_EXN_HANDLER,

  MZCONFIG_EVAL_HANDLER,
  MZCONFIG_LOAD_HANDLER,

  MZCONFIG_PRINT_HANDLER,
  MZCONFIG_PROMPT_READ_HANDLER,

  MZCONFIG_CAN_READ_GRAPH,
  MZCONFIG_CAN_READ_COMPILED,
  MZCONFIG_CAN_READ_BOX,
  MZCONFIG_CAN_READ_PIPE_QUOTE,
  MZCONFIG_CAN_READ_DOT,
  MZCONFIG_CAN_READ_QUASI,
  MZCONFIG_READ_DECIMAL_INEXACT,

  MZCONFIG_PRINT_GRAPH,
  MZCONFIG_PRINT_STRUCT,
  MZCONFIG_PRINT_BOX,
  MZCONFIG_PRINT_VEC_SHORTHAND,
  MZCONFIG_PRINT_HASH_TABLE,

  MZCONFIG_CASE_SENS,
  MZCONFIG_SQUARE_BRACKETS_ARE_PARENS,
  MZCONFIG_CURLY_BRACES_ARE_PARENS,

  MZCONFIG_ERROR_PRINT_WIDTH,

  MZCONFIG_ERROR_ESCAPE_HANDLER,

  MZCONFIG_ALLOW_SET_UNDEFINED,

  MZCONFIG_CUSTODIAN,
  MZCONFIG_INSPECTOR,

  MZCONFIG_USE_COMPILED_KIND,

  MZCONFIG_LOAD_DIRECTORY,

  MZCONFIG_COLLECTION_PATHS,

  MZCONFIG_PORT_PRINT_HANDLER,

  MZCONFIG_LOAD_EXTENSION_HANDLER,

  MZCONFIG_CURRENT_DIRECTORY,

  MZCONFIG_RANDOM_STATE,

  MZCONFIG_CURRENT_MODULE_RESOLVER,
  MZCONFIG_CURRENT_MODULE_PREFIX,

  MZCONFIG_ERROR_PRINT_SRCLOC,

  MZCONFIG_CMDLINE_ARGS,

  MZCONFIG_LOCALE,

  MZCONFIG_SECURITY_GUARD,

  MZCONFIG_PORT_COUNT_LINES,

  MZCONFIG_SCHEDULER_RANDOM_STATE,

  MZCONFIG_THREAD_SET,

  __MZCONFIG_BUILTIN_COUNT__
};


typedef struct Scheme_Config {
  Scheme_Type type;
  MZ_HASH_KEY_EX
  int *use_count; /* non-zero => copy-on-write of extensions table */
  Scheme_Bucket_Table *extensions;
  Scheme_Object *configs[1];
} Scheme_Config;

#define scheme_set_param(c, pos, o) ((c)->configs[pos] = (o))
#define scheme_get_param(c, pos) ((c)->configs[pos])

/*========================================================================*/
/*                                  ports                                 */
/*========================================================================*/

typedef struct Scheme_Input_Port Scheme_Input_Port;
typedef struct Scheme_Output_Port Scheme_Output_Port;

typedef long (*Scheme_Get_String_Fun)(Scheme_Input_Port *port,
				      char *buffer, long offset, long size,
				      int nonblock);
typedef long (*Scheme_Peek_String_Fun)(Scheme_Input_Port *port,
				       char *buffer, long offset, long size,
				       Scheme_Object *skip,
				       int nonblock);
typedef int (*Scheme_In_Ready_Fun)(Scheme_Input_Port *port);
typedef void (*Scheme_Close_Input_Fun)(Scheme_Input_Port *port);
typedef void (*Scheme_Need_Wakeup_Input_Fun)(Scheme_Input_Port *, void *);

typedef long (*Scheme_Write_String_Fun)(Scheme_Output_Port *,
					const char *str, long offset, long size,
					int rarely_block);
typedef int (*Scheme_Out_Ready_Fun)(Scheme_Output_Port *port);
typedef void (*Scheme_Close_Output_Fun)(Scheme_Output_Port *port);
typedef void (*Scheme_Need_Wakeup_Output_Fun)(Scheme_Output_Port *, void *);

struct Scheme_Input_Port
{
  Scheme_Type type;
  MZ_HASH_KEY_EX
  char closed, pending_eof;
  Scheme_Object *sub_type;
  Scheme_Custodian_Reference *mref;
  void *port_data;
  Scheme_Get_String_Fun get_string_fun;
  Scheme_Peek_String_Fun peek_string_fun;
  Scheme_In_Ready_Fun char_ready_fun;
  Scheme_Close_Input_Fun close_fun;
  Scheme_Need_Wakeup_Input_Fun need_wakeup_fun;
  Scheme_Object *read_handler;
  char *name;
  Scheme_Object *peeked_read, *peeked_write;
  unsigned char ungotten[4];
  int ungotten_count;
  Scheme_Object *special, *ungotten_special;
  long position, readpos, lineNumber, charsSinceNewline;
  long column, oldColumn; /* column tracking with one tab/newline ungetc */
  int count_lines, was_cr;
  struct Scheme_Output_Port *output_half;
};

struct Scheme_Output_Port
{
  Scheme_Type type;
  MZ_HASH_KEY_EX
  short closed;
  Scheme_Object *sub_type;
  Scheme_Custodian_Reference *mref;
  void *port_data;
  Scheme_Write_String_Fun write_string_fun;
  Scheme_Close_Output_Fun close_fun;
  Scheme_Out_Ready_Fun ready_fun;
  Scheme_Need_Wakeup_Output_Fun need_wakeup_fun;
  long pos;
  Scheme_Object *display_handler;
  Scheme_Object *write_handler;
  Scheme_Object *print_handler;
  struct Scheme_Input_Port *input_half;
};

#define SCHEME_INPORT_VAL(obj) (((Scheme_Input_Port *)(obj))->port_data)
#define SCHEME_OUTPORT_VAL(obj) (((Scheme_Output_Port *)(obj))->port_data)
#define SCHEME_IPORT_NAME(obj) (((Scheme_Input_Port *)obj)->name)

#define SCHEME_SPECIAL (-2)

/*========================================================================*/
/*                              exceptions                                */
/*========================================================================*/

/* This file includes the MZEXN constants */
#ifdef INCLUDE_WITHOUT_PATHS
# include "schexn.h"
#else
# include "../src/schexn.h"
#endif

/*========================================================================*/
/*                               security                                 */
/*========================================================================*/

#define SCHEME_GUARD_FILE_READ    0x1
#define SCHEME_GUARD_FILE_WRITE   0x2
#define SCHEME_GUARD_FILE_EXECUTE 0x4
#define SCHEME_GUARD_FILE_DELETE  0x8
#define SCHEME_GUARD_FILE_EXISTS  0x10

/*========================================================================*/
/*                               modules                                  */
/*========================================================================*/

typedef void (*Scheme_Invoke_Proc)(Scheme_Env *env, long phase_shift,
				   Scheme_Object *self_modidx, void *data);

/*========================================================================*/
/*                               evaluation                               */
/*========================================================================*/

/* Exploit the fact that these should never be dereferenced: */
#ifndef FIRST_TWO_BYTES_ARE_LEGAL_ADDRESSES
# define MZ_EVAL_WAITING_CONSTANT ((Scheme_Object *)0x2)
# define MZ_APPLY_WAITING_CONSTANT ((Scheme_Object *)0x4)
# define MZ_MULTIPLE_VALUES_CONSTANT ((Scheme_Object *)0x6)
#endif

#ifdef MZ_EVAL_WAITING_CONSTANT
# define SCHEME_EVAL_WAITING MZ_EVAL_WAITING_CONSTANT
# define SCHEME_TAIL_CALL_WAITING MZ_APPLY_WAITING_CONSTANT
# define SCHEME_MULTIPLE_VALUES MZ_MULTIPLE_VALUES_CONSTANT
#else
# define SCHEME_TAIL_CALL_WAITING scheme_tail_call_waiting
# define SCHEME_EVAL_WAITING scheme_eval_waiting
# define SCHEME_MULTIPLE_VALUES scheme_multiple_values
#endif

#define SCHEME_ASSERT(expr,msg) ((expr) ? 1 : (scheme_signal_error(msg), 0))

#define scheme_eval_wait_expr (scheme_current_thread->ku.eval.wait_expr)
#define scheme_tail_rator (scheme_current_thread->ku.apply.tail_rator)
#define scheme_tail_num_rands (scheme_current_thread->ku.apply.tail_num_rands)
#define scheme_tail_rands (scheme_current_thread->ku.apply.tail_rands)
#define scheme_overflow_k (scheme_current_thread->overflow_k)
#define scheme_overflow_reply (scheme_current_thread->overflow_reply)

#define scheme_error_buf (scheme_current_thread->error_buf)
#define scheme_jumping_to_continuation (scheme_current_thread->cjs.jumping_to_continuation)
#define scheme_config (scheme_current_thread->config)

#define scheme_multiple_count (scheme_current_thread->ku.multiple.count)
#define scheme_multiple_array (scheme_current_thread->ku.multiple.array)

#define scheme_setjmpup(b, base, s) scheme_setjmpup_relative(b, base, s, NULL)

#define scheme_do_eval_w_thread(r,n,e,f,p) scheme_do_eval(r,n,e,f)
#define scheme_apply_wp(r,n,a,p) scheme_apply(r,n,a)
#define scheme_apply_multi_wp(r,n,a,p) scheme_apply_multi(r,n,a)
#define scheme_apply_eb_wp(r,n,a,p) scheme_apply_eb(r,n,a)
#define scheme_apply_multi_eb_wp(r,n,a,p) scheme_apply_multi_eb(r,n,a)

#define _scheme_apply(r,n,rs) scheme_do_eval(r,n,rs,1)
#define _scheme_apply_multi(r,n,rs) scheme_do_eval(r,n,rs,-1)
#define _scheme_apply_wp(r,n,rs,p) scheme_do_eval_w_thread(r,n,rs,1,p)
#define _scheme_apply_multi_wp(r,n,rs,p) scheme_do_eval_w_thread(r,n,rs,-1,p)
#define _scheme_tail_apply scheme_tail_apply
#define _scheme_tail_apply_wp scheme_tail_apply_wp

#define _scheme_tail_eval scheme_tail_eval
#define _scheme_tail_eval_wp scheme_tail_eval_wp

#define _scheme_direct_apply_primitive_multi(prim, argc, argv) \
    (((Scheme_Primitive_Proc *)prim)->prim_val(argc, argv))
#define _scheme_direct_apply_primitive(prim, argc, argv) \
    scheme_check_one_value(_scheme_direct_apply_primitive_multi(prim, argc, argv))
#define _scheme_direct_apply_closed_primitive_multi(prim, argc, argv) \
    (((Scheme_Closed_Primitive_Proc *)prim)->prim_val(((Scheme_Closed_Primitive_Proc *)prim)->data, argc, argv))
#define _scheme_direct_apply_closed_primitive(prim, argc, argv) \
    scheme_check_one_value(_scheme_direct_apply_closed_primitive_multi(prim, argc, argv))

#define _scheme_force_value(v) ((v == SCHEME_TAIL_CALL_WAITING) ? scheme_force_value(v) : v)

#define scheme_tail_apply_buffer_wp(n, p) ((p)->tail_buffer)
#define scheme_tail_apply_buffer(n) scheme_tail_apply_buffer_wp(n, scheme_current_thread)

#define _scheme_tail_apply_no_copy_wp_tcw(f, n, args, p, tcw) (p->ku.apply.tail_rator = f, p->ku.apply.tail_rands = args, p->ku.apply.tail_num_rands = n, tcw)
#define _scheme_tail_apply_no_copy_wp(f, n, args, p) _scheme_tail_apply_no_copy_wp_tcw(f, n, args, p, SCHEME_TAIL_CALL_WAITING)
#define _scheme_tail_apply_no_copy(f, n, args) _scheme_tail_apply_no_copy_wp(f, n, args, scheme_current_thread)

#define scheme_thread_block_w_thread(t,p) scheme_thread_block(t)

#if !SCHEME_DIRECT_EMBEDDED
# ifdef LINK_EXTENSIONS_BY_TABLE
#  define scheme_fuel_counter (*scheme_fuel_counter_ptr)
# endif
#else
#endif

#ifdef FUEL_AUTODECEREMENTS
# define DECREMENT_FUEL(f, p) (f)
#else
# define DECREMENT_FUEL(f, p) (f -= (p))
#endif

#define SCHEME_USE_FUEL(n) \
  { if (DECREMENT_FUEL(scheme_fuel_counter, n) <= 0) { scheme_out_of_fuel(); }}

#if SCHEME_DIRECT_EMBEDDED
#define scheme_tail_eval(obj) \
 (scheme_eval_wait_expr = obj, SCHEME_EVAL_WAITING)
#endif

#define scheme_break_waiting(p) (p->external_break)

#ifndef USE_MZ_SETJMP
# ifdef USE_UNDERSCORE_SETJMP
#  define scheme_mz_longjmp(b, v) _longjmp(b, v)
#  define scheme_mz_setjmp(b) _setjmp(b)
# else
#  define scheme_mz_longjmp(b, v) longjmp(b, v)
#  define scheme_mz_setjmp(b) setjmp(b)
# endif
#endif

#ifdef MZ_PRECISE_GC
/* Need to make sure that a __gc_var_stack__ is always available where
   setjmp & longjmp are used. */
# define scheme_longjmp(b, v) (((long *)((b).gcvs))[1] = (b).gcvs_cnt, \
                               GC_variable_stack = (void **)(b).gcvs, \
                               scheme_mz_longjmp((b).jb, v))
# define scheme_setjmp(b)     ((b).gcvs = (long)__gc_var_stack__, \
                               (b).gcvs_cnt = (long)(__gc_var_stack__[1]), \
                               scheme_mz_setjmp((b).jb))
#else
# define scheme_longjmp(b, v) scheme_mz_longjmp(b, v)
# define scheme_setjmp(b) scheme_mz_setjmp(b)
#endif

/*========================================================================*/
/*                      memory management macros                          */
/*========================================================================*/

/* Allocation */
#define scheme_alloc_object() \
   ((Scheme_Object *) scheme_malloc_tagged(sizeof(Scheme_Object)))
#define scheme_alloc_small_object() \
   ((Scheme_Object *) scheme_malloc_tagged(sizeof(Scheme_Small_Object)))
#define scheme_alloc_stubborn_object() \
   ((Scheme_Object *) scheme_malloc_stubborn_tagged(sizeof(Scheme_Object)))
#define scheme_alloc_stubborn_small_object() \
   ((Scheme_Object *) scheme_malloc_stubborn_tagged(sizeof(Scheme_Small_Object)))
#define scheme_alloc_eternal_object() \
   ((Scheme_Object *) scheme_malloc_eternal_tagged(sizeof(Scheme_Object)))
#define scheme_alloc_eternal_small_object() \
   ((Scheme_Object *) scheme_malloc_eternal_tagged(sizeof(Scheme_Small_Object)))

#ifdef SCHEME_NO_GC
void *scheme_malloc(size_t size);
# define scheme_malloc_atomic scheme_malloc
# define scheme_malloc_stubborn scheme_malloc
# define scheme_malloc_uncollectable scheme_malloc
#else
# define scheme_malloc GC_malloc
# define scheme_malloc_atomic GC_malloc_atomic
# ifdef MZ_PRECISE_GC
#  define scheme_malloc_stubborn scheme_malloc
# else
#  define scheme_malloc_stubborn GC_malloc_stubborn
# endif
# define scheme_malloc_uncollectable GC_malloc_uncollectable
#endif

#ifdef USE_MEMORY_TRACING
# define USE_TAGGED_ALLOCATION
# define MEMORY_COUNTING_ON
#endif

#ifdef MZ_PRECISE_GC
# ifndef GC2_EXTERN
#  define GC2_EXTERN MZ_EXTERN
# endif
# ifdef INCLUDE_WITHOUT_PATHS
#  if SCHEME_DIRECT_EMBEDDED
#   include "gc2.h"
#  else
#   define GC2_JUST_MACROS_AND_TYPEDEFS
#   include "schemegc2.h"
#  endif
# else
#  include "../gc2/gc2.h"
# endif
# define scheme_malloc_tagged GC_malloc_one_tagged
# define scheme_malloc_array_tagged GC_malloc_array_tagged
# define scheme_malloc_atomic_tagged GC_malloc_atomic_tagged
# define scheme_malloc_stubborn_tagged GC_malloc_one_tagged
# define scheme_malloc_eternal_tagged GC_malloc_atomic_uncollectable
# define scheme_malloc_uncollectable_tagged >> error <<
# define scheme_malloc_envunbox GC_malloc
# define scheme_malloc_weak GC_malloc_weak
# define scheme_malloc_weak_tagged GC_malloc_one_weak_tagged
# define scheme_malloc_allow_interior GC_malloc_allow_interior
#else
# ifdef USE_TAGGED_ALLOCATION
extern void *scheme_malloc_tagged(size_t);
#  define scheme_malloc_array_tagged scheme_malloc
extern void *scheme_malloc_atomic_tagged(size_t);
extern void *scheme_malloc_stubborn_tagged(size_t);
extern void *scheme_malloc_eternal_tagged(size_t);
extern void *scheme_malloc_uncollectable_tagged(size_t);
extern void *scheme_malloc_envunbox(size_t);
# else
#  define scheme_malloc_tagged scheme_malloc
#  define scheme_malloc_array_tagged scheme_malloc
#  define scheme_malloc_atomic_tagged scheme_malloc_atomic
#  define scheme_malloc_stubborn_tagged scheme_malloc_stubborn
#  define scheme_malloc_eternal_tagged scheme_malloc_eternal
#  define scheme_malloc_uncollectable_tagged scheme_malloc_uncollectable
#  define scheme_malloc_envunbox scheme_malloc
# endif
# define scheme_malloc_allow_interior scheme_malloc
#endif


#ifdef MZ_PRECISE_GC
# define MZ_GC_DECL_REG(size) void *__gc_var_stack__[size+2] = { 0, size };
# define MZ_GC_VAR_IN_REG(x, v) (__gc_var_stack__[x+2] = (void *)&(v))
# define MZ_GC_ARRAY_VAR_IN_REG(x, v, l) (__gc_var_stack__[x+2] = (void *)0, \
                                          __gc_var_stack__[x+3] = (void *)&(v), \
                                          __gc_var_stack__[x+4] = (void *)l)
# define MZ_GC_REG()  (__gc_var_stack__[0] = GC_variable_stack, \
                       GC_variable_stack = __gc_var_stack__)
# define MZ_GC_UNREG() (GC_variable_stack = __gc_var_stack__[0])
#else
# define MZ_GC_DECL_REG(size)            /* empty */
# define MZ_GC_VAR_IN_REG(x, v)          /* empty */
# define MZ_GC_ARRAY_VAR_IN_REG(x, v, l) /* empty */
# define MZ_GC_REG()                     /* empty */
# define MZ_GC_UNREG()                   /* empty */
#endif

/*========================================================================*/
/*                   embedding configuration and hooks                    */
/*========================================================================*/

#if SCHEME_DIRECT_EMBEDDED

#if defined(_IBMR2)
#endif


/* These flags must be set before MzScheme is started: */


/* Set these global hooks (optionally): */
#ifdef MZ_PRECISE_GC
#endif
#ifdef USE_WIN32_THREADS
int scheme_set_in_main_thread(void);
void scheme_restore_nonmain_thread(void);
#endif
#ifdef MAC_FILE_SYSTEM
extern long scheme_creator_id;
#endif



/* Initialization */

#ifdef USE_MSVC_MD_LIBRARY
#endif


/* image dump enabling startup: */

/* GC registration: */
#ifdef GC_MIGHT_USE_REGISTERED_STATICS
#endif

#if defined(MUST_REGISTER_GLOBALS) || defined(GC_MIGHT_USE_REGISTERED_STATICS)
# define MZ_REGISTER_STATIC(x)  scheme_register_static((void *)&x, sizeof(x))
#else
# define MZ_REGISTER_STATIC(x) /* empty */
#endif



#endif /* SCHEME_DIRECT_EMBEDDED */

/*========================================================================*/
/*                              FFI functions                             */
/*========================================================================*/

/* If MzScheme is being empbedded, then we just include the
   prototypes. Otherwise, we may include a function-table definition
   instead, plus macros that map the usual name to table lookups. */

#if SCHEME_DIRECT_EMBEDDED

/* All functions & global constants prototyped here */
#ifdef INCLUDE_WITHOUT_PATHS
# include "schemef.h"
#else
# include "../src/schemef.h"
#endif

#else

#ifdef LINK_EXTENSIONS_BY_TABLE
/* Constants and function prototypes as function pointers in a struct: */
# ifdef INCLUDE_WITHOUT_PATHS
#  include "schemex.h"
# else
#  include "../src/schemex.h"
# endif

extern Scheme_Extension_Table *scheme_extension_table;

/* Macro mapping names to record access */
# ifdef INCLUDE_WITHOUT_PATHS
#  include "schemexm.h"
# else
#  include "../src/schemexm.h"
# endif

#else

/* Not LINK_EXTENSIONS_BY_TABLE */
# ifdef INCLUDE_WITHOUT_PATHS
#  include "schemef.h"
# else
#  include "../src/schemef.h"
# endif

#endif

#endif

/*========================================================================*/
/*                              misc flags                                */
/*========================================================================*/

/* For use with scheme_symbol_name_and_size: */
#define SCHEME_SNF_FOR_TS 0x1
#define SCHEME_SNF_PIPE_QUOTE 0x2
#define SCHEME_SNF_NO_PIPE_QUOTE 0x4
#define SCHEME_SNF_NEED_CASE 0x8

/* For use with scheme_make_struct_values et al.: */
#define SCHEME_STRUCT_NO_TYPE 0x01
#define SCHEME_STRUCT_NO_CONSTR 0x02
#define SCHEME_STRUCT_NO_PRED 0x04
#define SCHEME_STRUCT_NO_GET 0x08
#define SCHEME_STRUCT_NO_SET 0x10
#define SCHEME_STRUCT_GEN_GET 0x20
#define SCHEME_STRUCT_GEN_SET 0x40
#define SCHEME_STRUCT_EXPTIME 0x80

/*========================================================================*/
/*                           file descriptors                             */
/*========================================================================*/

#if defined(DETECT_WIN32_CONSOLE_STDIN) || defined(WINDOWS_PROCESSES)
# ifndef NO_STDIO_THREADS
#  define USE_FAR_MZ_FDCALLS
# endif
#endif
#ifdef USE_DYNAMIC_FDSET_SIZE
# define USE_FAR_MZ_FDCALLS
#endif
#ifdef USE_BEOS_PORT_THREADS
# define USE_FAR_MZ_FDCALLS
#endif

#ifdef USE_FAR_MZ_FDCALLS
# define MZ_GET_FDSET(p, n) scheme_get_fdset(p, n)
# define MZ_FD_ZERO(p) scheme_fdzero(p)
# define MZ_FD_SET(n, p) scheme_fdset(p, n)
# define MZ_FD_CLR(n, p) scheme_fdclr(p, n)
# define MZ_FD_ISSET(n, p) scheme_fdisset(p, n)
#else
# define MZ_GET_FDSET(p, n) ((void *)(((fd_set *)p) + n))
# define MZ_FD_ZERO(p) FD_ZERO(p)
# define MZ_FD_SET(n, p) FD_SET(n, p)
# define MZ_FD_CLR(n, p) FD_CLR(n, p)
# define MZ_FD_ISSET(n, p) FD_ISSET(n, p)
#endif

#ifdef __cplusplus
}
#endif

#if defined(__MWERKS__)
# ifdef MZSCHEME_USES_NEAR_GLOBALS
#  pragma far_data reset
# endif
#endif

#endif /* ! SCHEME_H */

/*
  MzScheme
  Copyright (c) 2004 PLT Scheme, Inc.
  Copyright (c) 1995-2001 Matthew Flatt
  All rights reserved.

  Please see the full copyright in the documentation.

  Originally based on:
  libscheme
  Copyright (c) 1994 Brent Benson
  All rights reserved.
*/

/* MzScheme function prototypes */
/* Macros generally shouldn't go in this file; it is used both to
   prototype functions, and as a parsing source for
   declaring scheme_extension_table */

/* The scheme_extension_table "parser" is picky; don't leave a space
   between a function name and it's opening parameter parenthesis. */

/* After this START tag, all comments should start & end on same line */

/*========================================================================*/
/*                       setjmpup (continuations)                         */
/*========================================================================*/
void scheme_init_jmpup_buf(Scheme_Jumpup_Buf *b);
int scheme_setjmpup_relative(Scheme_Jumpup_Buf *b, void *base,
				       void * volatile start, Scheme_Jumpup_Buf *cont);
void scheme_longjmpup(Scheme_Jumpup_Buf *b);
void scheme_reset_jmpup_buf(Scheme_Jumpup_Buf *b);
#ifdef USE_MZ_SETJMP
int scheme_mz_setjmp(mz_pre_jmp_buf b);
void scheme_mz_longjmp(mz_pre_jmp_buf b, int v);
#endif
void scheme_clear_escape(void);
Scheme_Jumpup_Buf_Holder *scheme_new_jmpupbuf_holder(void);
/*========================================================================*/
/*                                parameters                              */
/*========================================================================*/
Scheme_Object *scheme_make_config(Scheme_Config *base);
Scheme_Object *scheme_branch_config(void);
int scheme_new_param(void);
Scheme_Object *scheme_param_config(char *name, Scheme_Object *pos,
					     int argc, Scheme_Object **argv,
					     int arity,
					     Scheme_Prim *check, char *expected,
					     int isbool);
Scheme_Object *scheme_register_parameter(Scheme_Prim *function, char *name, int which);
Scheme_Env *scheme_get_env(Scheme_Config *config);
/*========================================================================*/
/*                                threads                                 */
/*========================================================================*/
#ifndef LINK_EXTENSIONS_BY_TABLE
Scheme_Thread *scheme_current_thread;
volatile int scheme_fuel_counter;
#else
Scheme_Thread **scheme_current_thread_ptr;
volatile int *scheme_fuel_counter_ptr;
#endif
void scheme_out_of_fuel(void);
Scheme_Object *scheme_thread(Scheme_Object *thunk, Scheme_Config *config);
Scheme_Object *scheme_thread_w_custodian(Scheme_Object *thunk, Scheme_Config *config,
						   Scheme_Custodian *mgr);
Scheme_Object *scheme_thread_w_custodian_killkind(Scheme_Object *thunk, Scheme_Config *config,
							    Scheme_Custodian *mgr, int normal_kill);
void scheme_kill_thread(Scheme_Thread *p);
void scheme_break_thread(Scheme_Thread *p);
void scheme_thread_block(float sleep_time);
void scheme_swap_thread(Scheme_Thread *process);
void scheme_making_progress();
void scheme_weak_suspend_thread(Scheme_Thread *p);
void scheme_weak_resume_thread(Scheme_Thread *p);
int scheme_block_until(Scheme_Ready_Fun f, Scheme_Needs_Wakeup_Fun, Scheme_Object *, float);
int scheme_in_main_thread(void);
void scheme_cancel_sleep(void);
int scheme_tls_allocate();
void scheme_tls_set(int pos, void *v);
void *scheme_tls_get(int pos);
Scheme_Custodian *scheme_make_custodian(Scheme_Custodian *);
Scheme_Custodian_Reference *scheme_add_managed(Scheme_Custodian *m, Scheme_Object *o,
							 Scheme_Close_Custodian_Client *f, void *data,
							 int strong);
void scheme_custodian_check_available(Scheme_Custodian *m, const char *who, const char *what);
void scheme_remove_managed(Scheme_Custodian_Reference *m, Scheme_Object *o);
void scheme_close_managed(Scheme_Custodian *m);
void scheme_schedule_custodian_close(Scheme_Custodian *c);
void scheme_add_custodian_extractor(Scheme_Type t, Scheme_Custodian_Extractor e);
void scheme_add_atexit_closer(Scheme_Exit_Closer_Func f);
void scheme_add_waitable(Scheme_Type type,
				   Scheme_Ready_Fun ready,
				   Scheme_Needs_Wakeup_Fun wakeup,
				   Scheme_Wait_Filter_Fun filter,
				   int can_redirect);
void scheme_add_waitable_through_sema(Scheme_Type type,
						Scheme_Wait_Sema_Fun sema,
						Scheme_Wait_Filter_Fun filter);
int scheme_is_waitable(Scheme_Object *o);
Scheme_Object *scheme_object_wait_multiple(int argc, Scheme_Object *argv[]);
Scheme_Object *scheme_object_wait_multiple_enable_break(int argc, Scheme_Object *argv[]);
Scheme_Object *scheme_make_waitable_set(int argc, Scheme_Object **argv);
void scheme_add_swap_callback(Scheme_Closure_Func f, Scheme_Object *data);
Scheme_Object *scheme_call_enable_break(Scheme_Prim *prim, int argc, Scheme_Object *argv[]);
int scheme_close_should_force_port_closed();
void scheme_push_kill_action(Scheme_Kill_Action_Func f, void *d);
void scheme_pop_kill_action();
/*========================================================================*/
/*                              error handling                            */
/*========================================================================*/
void scheme_signal_error(const char *msg, ...);
void scheme_raise_exn(int exnid, ...);
void scheme_warning(char *msg, ...);
void scheme_raise(Scheme_Object *exn);
void scheme_wrong_count(const char *name, int minc, int maxc,
				  int argc, Scheme_Object **argv);
void scheme_wrong_count_m(const char *name, int minc, int maxc,
				    int argc, Scheme_Object **argv,
				    int is_method);
void scheme_case_lambda_wrong_count(const char *name, int argc,
					      Scheme_Object **argv, int is_method, int count, ...);
void scheme_wrong_type(const char *name, const char *expected,
				 int which, int argc,
				 Scheme_Object **argv);
void scheme_arg_mismatch(const char *name, const char *msg, Scheme_Object *o);
void scheme_wrong_return_arity(const char *where,
					 int expected, int got,
					 Scheme_Object **argv,
					 const char *context_detail, ...);
void scheme_unbound_global(Scheme_Bucket *b);
Scheme_Object *scheme_dynamic_wind(void (*pre)(void *),
					     Scheme_Object *(* volatile act)(void *),
					     void (* volatile post)(void *),
					     Scheme_Object *jmp_handler(void *),
					     void * volatile data);
/*========================================================================*/
/*                                 types                                  */
/*========================================================================*/
Scheme_Type scheme_make_type(const char *name);
char *scheme_get_type_name(Scheme_Type type);
/*========================================================================*/
/*                              constants                                 */
/*========================================================================*/
Scheme_Object *scheme_eof;
Scheme_Object *scheme_make_eof(void);
Scheme_Object *scheme_null;
Scheme_Object *scheme_make_null(void);
Scheme_Object *scheme_true;
Scheme_Object *scheme_make_true(void);
Scheme_Object *scheme_false;
Scheme_Object *scheme_make_false(void);
Scheme_Object *scheme_void;
Scheme_Object *scheme_make_void(void);
Scheme_Object *scheme_undefined;
Scheme_Object *scheme_tail_call_waiting;
Scheme_Object *scheme_multiple_values;
/*========================================================================*/
/*                              evaluation                                */
/*========================================================================*/
Scheme_Object *scheme_eval(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *scheme_eval_multi(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *scheme_eval_compiled(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *scheme_eval_compiled_multi(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *_scheme_eval_compiled(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *_scheme_eval_compiled_multi(Scheme_Object *obj, Scheme_Env *env);
Scheme_Object *scheme_apply(Scheme_Object *rator, int num_rands, Scheme_Object **rands);
Scheme_Object *scheme_apply_multi(Scheme_Object *rator, int num_rands, Scheme_Object **rands);
Scheme_Object *scheme_apply_eb(Scheme_Object *rator, int num_rands, Scheme_Object **rands);
Scheme_Object *scheme_apply_multi_eb(Scheme_Object *rator, int num_rands, Scheme_Object **rands);
Scheme_Object *scheme_apply_to_list(Scheme_Object *rator, Scheme_Object *argss);
Scheme_Object *scheme_eval_string(const char *str, Scheme_Env *env);
Scheme_Object *scheme_eval_string_multi(const char *str, Scheme_Env *env);
Scheme_Object *scheme_eval_string_all(const char *str, Scheme_Env *env, int all);
Scheme_Object *_scheme_apply_known_closed_prim(Scheme_Object *rator, int argc,
					       Scheme_Object **argv);
Scheme_Object *_scheme_apply_known_closed_prim_multi(Scheme_Object *rator, int argc,
						     Scheme_Object **argv);
Scheme_Object *_scheme_apply_closed_prim(Scheme_Object *rator, int argc,
					 Scheme_Object **argv);
Scheme_Object *_scheme_apply_closed_prim_multi(Scheme_Object *rator, int argc,
					       Scheme_Object **argv);
Scheme_Object *scheme_values(int c, Scheme_Object **v);
Scheme_Object *scheme_check_one_value(Scheme_Object *v);
/* Tail calls - only use these when you're writing new functions/syntax */
Scheme_Object *scheme_tail_apply(Scheme_Object *f, int n, Scheme_Object **arg);
Scheme_Object *scheme_tail_apply_no_copy(Scheme_Object *f, int n, Scheme_Object **arg);
Scheme_Object *scheme_tail_apply_to_list(Scheme_Object *f, Scheme_Object *l);
Scheme_Object *scheme_tail_eval_expr(Scheme_Object *obj);
void scheme_set_tail_buffer_size(int s);
Scheme_Object *scheme_force_value(Scheme_Object *);
void scheme_set_cont_mark(Scheme_Object *key, Scheme_Object *val);
void scheme_push_continuation_frame(Scheme_Cont_Frame_Data *);
void scheme_pop_continuation_frame(Scheme_Cont_Frame_Data *);
void scheme_temp_dec_mark_depth();
void scheme_temp_inc_mark_depth();
Scheme_Object *scheme_current_continuation_marks(void);
/* Internal */
Scheme_Object *scheme_do_eval(Scheme_Object *obj, int _num_rands, Scheme_Object **rands, int val);
Scheme_Object *scheme_eval_compiled_stx_string(Scheme_Object *expr, Scheme_Env *env,
							 long shift, Scheme_Object *modidx);
Scheme_Object *scheme_load_compiled_stx_string(const char *str, long len);
Scheme_Object *scheme_compiled_stx_symbol(Scheme_Object *stx);
Scheme_Object *scheme_eval_compiled_sized_string(const char *str, int len, Scheme_Env *env);
/*========================================================================*/
/*                           memory management                            */
/*========================================================================*/
/* The core allocator functions depend on the GC. Macros in scheme.h */
/*  map to the apporpriate core allocation function. */
#ifndef SCHEME_NO_GC
# ifndef SCHEME_NO_GC_PROTO
void *GC_malloc(size_t size_in_bytes);
void *GC_malloc_atomic(size_t size_in_bytes);
#  ifdef MZ_PRECISE_GC
void *GC_malloc_one_tagged(size_t size_in_bytes);
void *GC_malloc_atomic_uncollectable(size_t size_in_bytes);
void *GC_malloc_array_tagged(size_t size_in_bytes);
#  else
void *GC_malloc_stubborn(size_t size_in_bytes);
void *GC_malloc_uncollectable(size_t size_in_bytes);
#  endif
# endif
#endif
void *scheme_malloc_eternal(size_t n);
void scheme_end_stubborn_change(void *p);
void *scheme_calloc(size_t num, size_t size);
char *scheme_strdup(const char *str);
char *scheme_strdup_eternal(const char *str);
void *scheme_malloc_fail_ok(void *(*f)(size_t), size_t);
#ifndef MZ_PRECISE_GC
void scheme_weak_reference(void **p);
void scheme_weak_reference_indirect(void **p, void *v);
void scheme_unweak_reference(void **p);
#endif
void scheme_add_finalizer(void *p, void (*f)(void *p, void *data), void *data);
void scheme_add_finalizer_once(void *p, void (*f)(void *p, void *data), void *data);
void scheme_add_scheme_finalizer(void *p, void (*f)(void *p, void *data), void *data);
void scheme_add_scheme_finalizer_once(void *p, void (*f)(void *p, void *data), void *data);
void scheme_register_finalizer(void *p,
					 void f(void *p, void *data), void *data,
					 void (**oldf)(void *p, void *data),
					 void **olddata);
void scheme_remove_all_finalization(void *p);
void scheme_dont_gc_ptr(void *p);
void scheme_gc_ptr_ok(void *p);
void scheme_collect_garbage(void);
#ifdef MZ_PRECISE_GC
void **GC_variable_stack;
void GC_register_traversers(short tag, Size_Proc size, Mark_Proc mark, Fixup_Proc fixup,
				      int is_constant_size, int is_atomic);
void *GC_resolve(void *p);
void GC_mark(const void *p);
void GC_fixup(void *p);
#endif
/*========================================================================*/
/*                             hash tables                                */
/*========================================================================*/
Scheme_Bucket_Table *scheme_make_bucket_table(int size_hint, int type);
void scheme_add_to_table(Scheme_Bucket_Table *table, const char *key, void *val, int);
void scheme_change_in_table(Scheme_Bucket_Table *table, const char *key, void *new_val);
void *scheme_lookup_in_table(Scheme_Bucket_Table *table, const char *key);
Scheme_Bucket *scheme_bucket_from_table(Scheme_Bucket_Table *table, const char *key);
int scheme_bucket_table_equal(Scheme_Bucket_Table *t1, Scheme_Bucket_Table *t2);
Scheme_Hash_Table *scheme_make_hash_table(int type);
Scheme_Hash_Table *scheme_make_hash_table_equal();
void scheme_hash_set(Scheme_Hash_Table *table, Scheme_Object *key, Scheme_Object *val);
Scheme_Object *scheme_hash_get(Scheme_Hash_Table *table, Scheme_Object *key);
int scheme_hash_table_equal(Scheme_Hash_Table *t1, Scheme_Hash_Table *t2);
int scheme_is_hash_table_equal(Scheme_Object *o);
/*========================================================================*/
/*                   basic Scheme value constructors                      */
/*========================================================================*/
Scheme_Object *scheme_make_prim(Scheme_Prim *prim);
Scheme_Object *scheme_make_noneternal_prim(Scheme_Prim *prim);
Scheme_Object *scheme_make_closed_prim(Scheme_Closed_Prim *prim, void *data);
Scheme_Object *scheme_make_prim_w_arity(Scheme_Prim *prim, const char *name,
					mzshort mina, mzshort maxa);
Scheme_Object *scheme_make_folding_prim(Scheme_Prim *prim,
					const char *name,
					mzshort mina, mzshort maxa,
					short functional);
Scheme_Object *scheme_make_noneternal_prim_w_arity(Scheme_Prim *prim,
						   const char *name,
						   mzshort mina, mzshort maxa);
Scheme_Object *scheme_make_closed_prim_w_arity(Scheme_Closed_Prim *prim,
					       void *data, const char *name,
					       mzshort mina, mzshort maxa);
Scheme_Object *scheme_make_folding_closed_prim(Scheme_Closed_Prim *prim,
					       void *data, const char *name,
					       mzshort mina, mzshort maxa,
					       short functional);
Scheme_Object *scheme_make_prim_w_everything(Scheme_Prim *fun, int eternal,
						       const char *name,
						       mzshort mina, mzshort maxa,
						       short folding,
						       mzshort minr, mzshort maxr);
Scheme_Object *scheme_make_closed_prim_w_everything(Scheme_Closed_Prim *fun,
							      void *data,
							      const char *name,
							      mzshort mina, mzshort maxa,
							      short folding,
							      mzshort minr, mzshort maxr);
void scheme_prim_is_method(Scheme_Object *o);
Scheme_Object *scheme_make_pair(Scheme_Object *car, Scheme_Object *cdr);
Scheme_Object *scheme_make_immutable_pair(Scheme_Object *car, Scheme_Object *cdr);
Scheme_Object *scheme_make_string(const char *chars);
Scheme_Object *scheme_make_sized_string(char *chars, long len, int copy);
Scheme_Object *scheme_make_sized_offset_string(char *chars, long d, long len, int copy);
Scheme_Object *scheme_make_immutable_sized_string(char *chars, long len, int copy);
Scheme_Object *scheme_make_string_without_copying(char *chars);
Scheme_Object *scheme_alloc_string(int size, char fill);
Scheme_Object *scheme_append_string(Scheme_Object *, Scheme_Object *);
Scheme_Object *scheme_make_vector(int size, Scheme_Object *fill);
Scheme_Object *scheme_make_integer_value(long i);
Scheme_Object *scheme_make_integer_value_from_unsigned(unsigned long i);
Scheme_Object *scheme_make_integer_value_from_long_long(unsigned long lowhalf, unsigned long hihalf);
Scheme_Object *scheme_make_integer_value_from_unsigned_long_long(unsigned long lowhalf, unsigned long hihalf);
Scheme_Object *scheme_make_double(double d);
#ifdef MZ_USE_SINGLE_FLOATS
Scheme_Object *scheme_make_float(float f) ;
#endif
Scheme_Object *scheme_make_char(char ch);
Scheme_Object *scheme_make_sema(long v);
void scheme_post_sema(Scheme_Object *o);
void scheme_post_sema_all(Scheme_Object *o);
int scheme_wait_sema(Scheme_Object *o, int just_try);
Scheme_Object **scheme_char_constants;
Scheme_Object *scheme_make_channel();
int scheme_get_int_val(Scheme_Object *o, long *v);
int scheme_get_unsigned_int_val(Scheme_Object *o, unsigned long *v);
double scheme_real_to_double(Scheme_Object *r);
Scheme_Object *scheme_make_cptr(void *cptr, const char *typestr);
const char *scheme_get_proc_name(Scheme_Object *p, int *len, int for_error);
/*========================================================================*/
/*                               bignums                                  */
/*========================================================================*/
Scheme_Object *scheme_make_bignum(long v);
Scheme_Object *scheme_make_bignum_from_unsigned(unsigned long v);
double scheme_bignum_to_double(const Scheme_Object *n);
Scheme_Object *scheme_bignum_from_double(double d);
#ifdef MZ_USE_SINGLE_FLOATS
float scheme_bignum_to_float(const Scheme_Object *n);
Scheme_Object *scheme_bignum_from_float(float d);
#else
# define scheme_bignum_to_float scheme_bignum_to_double
# define scheme_bignum_from_float scheme_bignum_from_double
#endif
char *scheme_bignum_to_string(const Scheme_Object *n, int radix);
char *scheme_bignum_to_allocated_string(const Scheme_Object *n, int radix, int alloc);
Scheme_Object *scheme_read_bignum(const char *str, int offset, int radix);
Scheme_Object *scheme_bignum_normalize(const Scheme_Object *n);
/*========================================================================*/
/*                              rationals                                 */
/*========================================================================*/
Scheme_Object *scheme_make_rational(const Scheme_Object *r, const Scheme_Object *d);
double scheme_rational_to_double(const Scheme_Object *n);
Scheme_Object *scheme_rational_from_double(double d);
#ifdef MZ_USE_SINGLE_FLOATS
float scheme_rational_to_float(const Scheme_Object *n);
Scheme_Object *scheme_rational_from_float(float d);
#else
# define scheme_rational_to_float scheme_rational_to_double
# define scheme_rational_from_float scheme_rational_from_double
#endif
Scheme_Object *scheme_rational_normalize(const Scheme_Object *n);
Scheme_Object *scheme_rational_numerator(const Scheme_Object *n);
Scheme_Object *scheme_rational_denominator(const Scheme_Object *n);
/*========================================================================*/
/*                              complexes                                 */
/*========================================================================*/
Scheme_Object *scheme_make_complex(const Scheme_Object *r, const Scheme_Object *i);
Scheme_Object *scheme_complex_normalize(const Scheme_Object *n);
Scheme_Object *scheme_complex_real_part(const Scheme_Object *n);
Scheme_Object *scheme_complex_imaginary_part(const Scheme_Object *n);
/* Exact/inexact: */
int scheme_is_exact(Scheme_Object *n);
int scheme_is_inexact(Scheme_Object *n);
/*========================================================================*/
/*                 macros, syntax, and compilation                        */
/*========================================================================*/
Scheme_Object *scheme_expand(Scheme_Object *form, Scheme_Env *env);
Scheme_Object *scheme_compile(Scheme_Object *form, Scheme_Env *env, int writeable);
/*========================================================================*/
/*                               ports                                    */
/*========================================================================*/
Scheme_Object *scheme_read(Scheme_Object *port);
Scheme_Object *scheme_read_syntax(Scheme_Object *port, Scheme_Object *stxsrc);
void scheme_write(Scheme_Object *obj, Scheme_Object *port);
void scheme_display(Scheme_Object *obj, Scheme_Object *port);
void scheme_write_w_max(Scheme_Object *obj, Scheme_Object *port, long maxl);
void scheme_display_w_max(Scheme_Object *obj, Scheme_Object *port, long maxl);
void scheme_write_string(const char *str, long len, Scheme_Object *port);
long scheme_put_string(const char *who, Scheme_Object *port,
				 const char *str, long d, long len,
				 int rarely_block);
char *scheme_write_to_string(Scheme_Object *obj, long *len);
char *scheme_display_to_string(Scheme_Object *obj, long *len);
char *scheme_write_to_string_w_max(Scheme_Object *obj, long *len, long maxl);
char *scheme_display_to_string_w_max(Scheme_Object *obj, long *len, long maxl);
void scheme_debug_print(Scheme_Object *obj);
void scheme_flush_output(Scheme_Object *port);
char *scheme_format(char *format, int flen, int argc, Scheme_Object **argv, long *rlen);
void scheme_printf(char *format, int flen, int argc, Scheme_Object **argv);
int scheme_getc(Scheme_Object *port);
int scheme_peekc(Scheme_Object *port);
int scheme_peekc_skip(Scheme_Object *port, Scheme_Object *skip);
int scheme_getc_special_ok(Scheme_Object *port);
int scheme_peekc_special_ok(Scheme_Object *port);
int scheme_peekc_special_ok_skip(Scheme_Object *port, Scheme_Object *skip);
void scheme_ungetc(int ch, Scheme_Object *port);
int scheme_char_ready(Scheme_Object *port);
int scheme_peekc_is_ungetc(Scheme_Object *port);
void scheme_need_wakeup(Scheme_Object *port, void *fds);
long scheme_get_string(const char *who,
				 Scheme_Object *port,
				 char *buffer, long offset, long size,
				 int only_avail,
				 int peek, Scheme_Object *peek_skip);
long scheme_get_chars(Scheme_Object *port, long size, char *buffer, int offset);
long scheme_tell(Scheme_Object *port);
long scheme_output_tell(Scheme_Object *port);
long scheme_tell_line(Scheme_Object *port);
long scheme_tell_column(Scheme_Object *port);
void scheme_count_lines(Scheme_Object *port);
void scheme_close_input_port(Scheme_Object *port);
void scheme_close_output_port(Scheme_Object *port);
Scheme_Object *scheme_make_port_type(const char *name);
Scheme_Input_Port *scheme_make_input_port(Scheme_Object *subtype, void *data,
						    Scheme_Get_String_Fun get_string_fun,
						    Scheme_Peek_String_Fun peek_string_fun,
						    Scheme_In_Ready_Fun char_ready_fun,
						    Scheme_Close_Input_Fun close_fun,
						    Scheme_Need_Wakeup_Input_Fun need_wakeup_fun,
						    int must_close);
Scheme_Output_Port *scheme_make_output_port(Scheme_Object *subtype,
						      void *data,
						      Scheme_Write_String_Fun write_string_fun,
						      Scheme_Out_Ready_Fun ready_fun,
						      Scheme_Close_Output_Fun close_fun,
						      Scheme_Need_Wakeup_Output_Fun need_wakeup_fun,
						      int must_close);
Scheme_Object *scheme_open_input_file(const char *name, const char *who);
Scheme_Object *scheme_open_output_file(const char *name, const char *who);
Scheme_Object *scheme_make_file_input_port(FILE *fp);
Scheme_Object *scheme_make_named_file_input_port(FILE *fp, const char *filename);
Scheme_Object *scheme_make_file_output_port(FILE *fp);
Scheme_Object *scheme_make_string_input_port(const char *str);
Scheme_Object *scheme_make_sized_string_input_port(const char *str, long len);
Scheme_Object *scheme_make_string_output_port();
char *scheme_get_string_output(Scheme_Object *);
char *scheme_get_sized_string_output(Scheme_Object *, long *len);
void scheme_pipe(Scheme_Object **read, Scheme_Object **write);
void scheme_pipe_with_limit(Scheme_Object **write, Scheme_Object **read, int maxsize);
long scheme_set_file_position(Scheme_Object *port, long pos);
int scheme_file_exists(char *filename);
int scheme_directory_exists(char *dirname);
char *scheme_expand_filename(char* filename, int ilen, const char *errorin, int *ex, int guards);
char *scheme_os_getcwd(char *buf, int buflen, int *actlen, int noexn);
int scheme_os_setcwd(char *buf, int noexn);
char *scheme_getdrive(void);
Scheme_Object *scheme_split_pathname(const char *path, int len, Scheme_Object **base, int *isdir);
Scheme_Object *scheme_build_pathname(int argc, Scheme_Object **argv);
#ifdef MACINTOSH_EVENTS
char *scheme_mac_spec_to_path(mzFSSpec *spec);
int scheme_mac_path_to_spec(const char *filename, mzFSSpec *spec);
#endif
void *scheme_alloc_fdset_array(int count, int permanent);
void *scheme_init_fdset_array(void *fdarray, int count);
void *scheme_get_fdset(void *fdarray, int pos);
void scheme_fdzero(void *fd);
void scheme_fdset(void *fd, int pos);
void scheme_fdclr(void *fd, int pos);
int scheme_fdisset(void *fd, int pos);
void scheme_add_fd_handle(void *h, void *fds, int repost);
void scheme_add_fd_eventmask(void *fds, int mask);
void scheme_security_check_file(const char *who, const char *filename, int guards);
void scheme_security_check_network(const char *who, const char *host, int port, int client);
int scheme_get_host_address(const char *address, int id, void *result);
/*========================================================================*/
/*                        namespace/environment                           */
/*========================================================================*/
Scheme_Object *scheme_make_namespace(int argc, Scheme_Object *argv[]);
void scheme_add_namespace_option(Scheme_Object *key, void (*f)(Scheme_Env *));
void scheme_require_from_original_env(Scheme_Env *env, int syntax_only);
void scheme_add_global(const char *name, Scheme_Object *val, Scheme_Env *env);
void scheme_add_global_symbol(Scheme_Object *name, Scheme_Object *val,
			      Scheme_Env *env);
Scheme_Object *scheme_make_envunbox(Scheme_Object *value);
Scheme_Object *scheme_lookup_global(Scheme_Object *symbol, Scheme_Env *env);
Scheme_Bucket *scheme_global_bucket(Scheme_Object *symbol, Scheme_Env *env);
Scheme_Bucket *scheme_global_keyword_bucket(Scheme_Object *symbol, Scheme_Env *env);
Scheme_Bucket *scheme_module_bucket(Scheme_Object *mod, Scheme_Object *var, int pos, Scheme_Env *env);
Scheme_Bucket *scheme_exptime_global_bucket(Scheme_Object *symbol, Scheme_Env *env);
Scheme_Bucket *scheme_exptime_module_bucket(Scheme_Object *mod, Scheme_Object *var, int pos, Scheme_Env *env);
Scheme_Object *scheme_builtin_value(const char *name); /* convenience */
void scheme_set_global_bucket(char *proc, Scheme_Bucket *var, Scheme_Object *val,
			      int set_undef);
void scheme_install_macro(Scheme_Bucket *b, Scheme_Object *v);
void scheme_save_initial_module_set(Scheme_Env *env);
Scheme_Env *scheme_primitive_module(Scheme_Object *name, Scheme_Env *for_env);
void scheme_finish_primitive_module(Scheme_Env *env);
Scheme_Object *scheme_make_modidx(Scheme_Object *path,
				  Scheme_Object *base,
				  Scheme_Object *resolved);
Scheme_Object *scheme_declare_module(Scheme_Object *shape, Scheme_Invoke_Proc ivk,
				     Scheme_Invoke_Proc sivk, void *data, Scheme_Env *env);
/*========================================================================*/
/*                                symbols                                 */
/*========================================================================*/
Scheme_Object *scheme_intern_symbol(const char *name);
Scheme_Object *scheme_intern_exact_symbol(const char *name, unsigned int len);
Scheme_Object *scheme_make_symbol(const char *name); /* Make uninterned */
Scheme_Object *scheme_make_exact_symbol(const char *name, unsigned int len); /* Exact case */
const char *scheme_symbol_name(Scheme_Object *sym);
const char *scheme_symbol_name_and_size(Scheme_Object *sym, unsigned int *l, int flags);
char *scheme_symbol_val(Scheme_Object *sym);
/*========================================================================*/
/*                                structs                                 */
/*========================================================================*/
Scheme_Object **scheme_make_struct_values(Scheme_Object *struct_type,
					  Scheme_Object **names,
					  int count, int flags);
Scheme_Object **scheme_make_struct_names(Scheme_Object *base,
					 Scheme_Object *field_names,
					 int flags, int *count_out);
Scheme_Object *scheme_make_struct_type(Scheme_Object *base,
				       Scheme_Object *parent,
				       Scheme_Object *inspector,
				       int num_fields, int num_uninit_fields,
				       Scheme_Object *uninit_val,
				       Scheme_Object *properties);
Scheme_Object *scheme_make_struct_instance(Scheme_Object *stype,
					   int argc,
					   Scheme_Object **argv);
Scheme_Object *scheme_make_struct_exptime(Scheme_Object **names, int count,
						    Scheme_Object *super_sym,
						    Scheme_Object *super_exptime,
						    int flags);
int scheme_is_struct_instance(Scheme_Object *type, Scheme_Object *v);
Scheme_Object *scheme_struct_ref(Scheme_Object *s, int pos);
void scheme_struct_set(Scheme_Object *s, int pos, Scheme_Object *v);
Scheme_Object *scheme_make_struct_type_property(Scheme_Object *name);
Scheme_Object *scheme_make_struct_type_property_w_guard(Scheme_Object *name, Scheme_Object *guard);
Scheme_Object *scheme_struct_type_property_ref(Scheme_Object *prop, Scheme_Object *s);
/*========================================================================*/
/*                              utilities                                 */
/*========================================================================*/
int scheme_eq(Scheme_Object *obj1, Scheme_Object *obj2);
int scheme_eqv(Scheme_Object *obj1, Scheme_Object *obj2);
int scheme_equal(Scheme_Object *obj1, Scheme_Object *obj2);
#ifdef MZ_PRECISE_GC
long scheme_hash_key(Scheme_Object *o);
#endif
long scheme_equal_hash_key(Scheme_Object *o);
long scheme_equal_hash_key2(Scheme_Object *o);
Scheme_Object *scheme_build_list(int argc, Scheme_Object **argv);
void scheme_make_list_immutable(Scheme_Object *l);
int scheme_list_length(Scheme_Object *list);
int scheme_proper_list_length(Scheme_Object *list);
Scheme_Object *scheme_alloc_list(int size);
Scheme_Object *scheme_map_1(Scheme_Object *(*f)(Scheme_Object*),
			    Scheme_Object *l);
Scheme_Object *scheme_car(Scheme_Object *pair);
Scheme_Object *scheme_cdr(Scheme_Object *pair);
Scheme_Object *scheme_cadr(Scheme_Object *pair);
Scheme_Object *scheme_caddr(Scheme_Object *pair);
Scheme_Object *scheme_vector_to_list(Scheme_Object *vec);
Scheme_Object *scheme_list_to_vector(Scheme_Object *list);
Scheme_Object *scheme_append(Scheme_Object *lstx, Scheme_Object *lsty);
Scheme_Object *scheme_box(Scheme_Object *v);
Scheme_Object *scheme_unbox(Scheme_Object *obj);
void scheme_set_box(Scheme_Object *b, Scheme_Object *v);
Scheme_Object *scheme_make_weak_box(Scheme_Object *v);
Scheme_Object *scheme_load(const char *file);
Scheme_Object *scheme_load_extension(const char *filename, Scheme_Env *env);
void scheme_register_extension_global(void *ptr, long size);
long scheme_get_seconds(void);
long scheme_get_milliseconds(void);
double scheme_get_inexact_milliseconds(void);
long scheme_get_process_milliseconds(void);
char *scheme_banner(void);
char *scheme_version(void);
int scheme_check_proc_arity(const char *where, int a,
			    int which, int argc, Scheme_Object **argv);
char *scheme_make_provided_string(Scheme_Object *o, int count, int *len);
char *scheme_make_args_string(char *s, int which, int argc, Scheme_Object **argv, long *len);
void scheme_no_dumps(char *why);
const char *scheme_system_library_subpath();
void scheme_signal_received(void);
#ifndef SCHEME_EX_INLINE
#endif

enum {

  /* compiled object types: (internal) */
  scheme_toplevel_type,
  scheme_local_type, 
  scheme_local_unbox_type,
  scheme_syntax_type,
  scheme_application_type,
  scheme_application2_type,
  scheme_application3_type,
  scheme_sequence_type,
  scheme_branch_type,
  scheme_unclosed_procedure_type,
  scheme_let_value_type, /* 10 */
  scheme_let_void_type,
  scheme_letrec_type,
  scheme_let_one_type,
  scheme_with_cont_mark_type,

  _scheme_values_types_, /* All following types are values */
  
  /* intermediate compiled: */
  scheme_compiled_unclosed_procedure_type,
  scheme_compiled_let_value_type,
  scheme_compiled_let_void_type,
  scheme_compiled_syntax_type,
  scheme_compiled_toplevel_type,  /* 20 */
  scheme_compiled_quote_syntax_type,

  scheme_quote_compilation_type, /* used while writing, only */

  /* Registered in prefix table: */
  scheme_variable_type,
  scheme_module_variable_type, /* link replaces with scheme_variable_type */

  _scheme_compiled_values_types_,

  /* procedure types */
  scheme_prim_type,
  scheme_closed_prim_type,
  scheme_closure_type,
  scheme_case_closure_type,
  scheme_cont_type, /* 30 */
  scheme_escaping_cont_type,
  scheme_proc_struct_type,

  /* structure types (overlaps with procs) */
  scheme_structure_type,

  /* basic types */
  scheme_char_type,
  scheme_integer_type,
  scheme_bignum_type,
  scheme_rational_type,
  scheme_float_type,
  scheme_double_type,
  scheme_complex_izi_type, /* 40 */
  scheme_complex_type,
  scheme_string_type,
  scheme_symbol_type,
  scheme_null_type,
  scheme_pair_type,
  scheme_vector_type,
  scheme_inspector_type,
  scheme_input_port_type,
  scheme_output_port_type,
  scheme_eof_type, /* 50 */
  scheme_true_type,
  scheme_false_type,
  scheme_void_type,
  scheme_syntax_compiler_type,
  scheme_macro_type,
  scheme_box_type,
  scheme_thread_type,
  scheme_stx_offset_type, 
  scheme_cont_mark_set_type, 
  scheme_sema_type, /* 60 */
  scheme_hash_table_type,
  scheme_c_pointer_type,
  scheme_weak_box_type,
  scheme_struct_type_type,
  scheme_module_index_type,
  scheme_set_macro_type,
  scheme_listener_type,
  scheme_namespace_type, 
  scheme_config_type,
  scheme_stx_type,  /* 70 */
  scheme_will_executor_type,
  scheme_custodian_type,
  scheme_random_state_type,
  scheme_regexp_type,
  scheme_bucket_type,
  scheme_bucket_table_type,
  scheme_subprocess_type,
  scheme_compilation_top_type,
  scheme_wrap_chunk_type,
  scheme_eval_waiting_type, /* 80 */
  scheme_tail_call_waiting_type,
  scheme_undefined_type,
  scheme_struct_property_type,
  scheme_multiple_values_type,
  scheme_placeholder_type,
  scheme_case_lambda_sequence_type,
  scheme_begin0_sequence_type,
  scheme_rename_table_type,
  scheme_module_type,
  scheme_svector_type, /* 90 */
  scheme_lazy_macro_type,
  scheme_resolve_prefix_type,
  scheme_security_guard_type,
  scheme_indent_type,
  scheme_udp_type,
  scheme_udp_waitable_type,
  scheme_id_macro_type,  
  scheme_waitable_set_type,
  scheme_wrapped_waitable_type,
  scheme_nack_guard_waitable_type, /* 100 */
  scheme_semaphore_repost_type,
  scheme_channel_type,
  scheme_channel_put_type,
  scheme_thread_resume_type,
  scheme_thread_suspend_type,
  scheme_thread_dead_type,
  scheme_poll_waitable_type,
  scheme_nack_waitable_type,
  scheme_module_registry_type,
  scheme_thread_set_type,   /* 110 */

  scheme_reserved1_type,
  scheme_reserved2_type,
  scheme_reserved3_type,

#ifdef MZTAG_REQUIRED
  _scheme_last_normal_type_,

  scheme_rt_comp_env,       
  scheme_rt_constant_binding,
  scheme_rt_resolve_info,
  scheme_rt_compile_info,
  scheme_rt_cont_mark,
  scheme_rt_saved_stack,  /* 120 */
  scheme_rt_eval_in_env,
  scheme_rt_reply_item,
  scheme_rt_closure_info,
  scheme_rt_overflow,
  scheme_rt_dyn_wind_cell,
  scheme_rt_cont_mark_chain,
  scheme_rt_dyn_wind_info,
  scheme_rt_dyn_wind,
  scheme_rt_dup_check,
  scheme_rt_thread_memory,  /* 130 */
  scheme_rt_input_file,
  scheme_rt_input_fd,
  scheme_rt_oskit_console_input,
  scheme_rt_tested_input_file,
  scheme_rt_tested_output_file,
  scheme_rt_indexed_string,
  scheme_rt_output_file,
  scheme_rt_load_handler_data,
  scheme_rt_load_data,
  scheme_rt_pipe,        /* 140 */
  scheme_rt_beos_process,
  scheme_rt_system_child,
  scheme_rt_tcp,
  scheme_rt_write_data,
  scheme_rt_tcp_select_info,
  scheme_rt_namespace_option,
  scheme_rt_param_data, 
  scheme_rt_will,
  scheme_rt_will_registration,
  scheme_rt_breakable_wait, /* 150 */
  scheme_rt_sema_waiter,
  scheme_rt_struct_proc_info,
  scheme_rt_linker_name,
  scheme_rt_param_map,
  scheme_rt_finalization,
  scheme_rt_finalizations,
  scheme_rt_cpp_object,
  scheme_rt_cpp_array_object,
  scheme_rt_stack_object, 
  scheme_rt_preallocated_object,  /* 160 */
  scheme_thread_hop_type,
  scheme_rt_breakable,
  scheme_rt_srcloc,
  scheme_rt_waitable,
  scheme_rt_waiting,
  scheme_rt_comp_prefix,
  scheme_rt_user_input,
  scheme_rt_user_output,
  scheme_rt_compact_port,
  scheme_rt_read_special_dw,  /* 170 */
  scheme_rt_regwork,
  scheme_rt_buf_holder,
#endif

  _scheme_last_type_
};
