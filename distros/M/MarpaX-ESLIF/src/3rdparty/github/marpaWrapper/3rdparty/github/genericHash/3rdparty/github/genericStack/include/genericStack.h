#ifndef GENERICSTACK_H
#define GENERICSTACK_H

#include <stdlib.h>       /* For malloc, free */
#include <stddef.h>       /* For size_t */
#include <string.h>       /* For memcpy */
#include <errno.h>        /* For errno */

/* =============== */
/* C generic stack */
/* =============== */

/* ---------------------------------------------------------------------- */
/* Most of the generic stack implementations either assume that every     */
/* element is of the same size, or bypass type checking going through     */
/* a C layer. This version does not have these two constraints.           */
/* By default it is restricted to ANSI-C data type, nevertheless          */
/* adding others is as trivial as looking into e.g. long long below.      */
/* Please note that, IF the data typecast to the stack, no warning.       */
/*                                                                        */
/* Purists will notice this is an array-based implementation. This        */
/* choice was made because it is fits all my applications.                */
/*                                                                        */
/* Define GENERICSTACK_C99           to have C99 data type                */
/* Define GENERICSTACK_CUSTOM to XXX to have a custom type XXX            */
/*                                                                        */
/* Stack size increases automatically if needed until user disposes it.   */
/* ---------------------------------------------------------------------- */
/* About the implementation we do use flexible arrays, because we do not  */
/* want to access out of what the compiler did on memory alignment,       */
/* internal padding etc...                                                */
/* Instead the rule is the following: as long as the generic stack usage  */
/* do not goes beyond the default size, internal default pool is used.    */
/* As soon as the usage goes beyond, the full data moved to the heap.     */
/* So, from access point of view, all data will always be aligned in a    */
/* single internal array, but there is a cost when:                       */
/* - usage goes beyond default length (once with a malloc + memcpy)       */

/* We count on any decent compiler to automatically inline our functions. */
/* In doubt, set the GENERICSTACK_INLINE keyword, that will tell we WISH  */
/* inlining.                                                              */
#ifdef __cplusplus
#  undef GENERICSTACK_INLINE /* With C++ inline is well defined */
#  define GENERICSTACK_INLINE inline
#else
#  ifndef GENERICSTACK_INLINE
#    define GENERICSTACK_INLINE /* Define it to nothing */
#  endif
#endif

/* ====================================================================== */
/* gcc family has the __builtin_expect that optimizes branch prediction.  */
/* This is off by default, but you can set the macros                     */
/* GENERICSTACK_LIKELY and GENERICSTACK_UNLIKELY to handle that.          */
/* ====================================================================== */
#ifndef GENERICSTACK_LIKELY
#  define GENERICSTACK_LIKELY(x) x
#endif
#ifndef GENERICSTACK_UNLIKELY
#  define GENERICSTACK_UNLIKELY(x) x
#endif

/* ====================================================================== */
/* In theory we should check for int turnaround. In practice this is      */
/* instructions for nothing, this is a so improbable case. Nevertheless   */
/* if you insist, set the variable GENERICSTACK_PARANOID.                 */
/* ====================================================================== */
/* #define GENERICSTACK_PARANOID */

/* ====================================================================== */
/* Stack default length.                                                  */
/* ====================================================================== */
#ifndef GENERICSTACK_DEFAULT_LENGTH
#  define GENERICSTACK_DEFAULT_LENGTH 128 /* Subjective number */
#endif
#if GENERICSTACK_DEFAULT_LENGTH < 0
/* We rely on GENERICSTACK_DEFAULT_LENGTH >= 0 to managed extension */
#  error "GENERICSTACK_DEFAULT_LENGTH < 0 is not allowed"
#endif

/* ====================================================================== */
/* C99 support.                                                           */
/* ====================================================================== */
#ifdef GENERICSTACK_C99
#  undef GENERICSTACK_HAVE_LONG_LONG
#  define GENERICSTACK_HAVE_LONG_LONG 1
#  undef GENERICSTACK_HAVE__BOOL
#  define GENERICSTACK_HAVE__BOOL     1
#  undef GENERICSTACK_HAVE__COMPLEX
#  define GENERICSTACK_HAVE__COMPLEX  1
#else
#  ifndef GENERICSTACK_HAVE_LONG_LONG
#    define GENERICSTACK_HAVE_LONG_LONG 0
#  endif
#  ifndef GENERICSTACK_HAVE__BOOL
#    define GENERICSTACK_HAVE__BOOL     0
#  endif
#  ifndef GENERICSTACK_HAVE__COMPLEX
#    define GENERICSTACK_HAVE__COMPLEX  0
#  endif
#endif

/* ====================================================================== */
/* Custom type support.                                                   */
/* ====================================================================== */
#ifdef GENERICSTACK_CUSTOM
#  undef GENERICSTACK_HAVE_CUSTOM
#  define GENERICSTACK_HAVE_CUSTOM 1
#else
#  ifndef GENERICSTACK_HAVE_CUSTOM
#    define GENERICSTACK_HAVE_CUSTOM 0
#  endif
#endif

/* ====================================================================== */
/* Items definition.                                                      */
/* ====================================================================== */
typedef enum genericStackItemType {
  GENERICSTACKITEMTYPE_NA = 0,    /* Not a hasard it is explicitely 0 */
  GENERICSTACKITEMTYPE_CHAR,
  GENERICSTACKITEMTYPE_SHORT,
  GENERICSTACKITEMTYPE_INT,
  GENERICSTACKITEMTYPE_LONG,
  GENERICSTACKITEMTYPE_FLOAT,
  GENERICSTACKITEMTYPE_DOUBLE,
  GENERICSTACKITEMTYPE_PTR,
  GENERICSTACKITEMTYPE_ARRAY,
#if GENERICSTACK_HAVE_LONG_LONG
  GENERICSTACKITEMTYPE_LONG_LONG,
#endif
#if GENERICSTACK_HAVE__BOOL
  GENERICSTACKITEMTYPE__BOOL,
#endif
#if GENERICSTACK_HAVE__COMPLEX
  GENERICSTACKITEMTYPE_FLOAT__COMPLEX,
  GENERICSTACKITEMTYPE_DOUBLE__COMPLEX,
  GENERICSTACKITEMTYPE_LONG_DOUBLE__COMPLEX,
#endif
#if GENERICSTACK_HAVE_CUSTOM
  GENERICSTACKITEMTYPE_CUSTOM,
#endif
  GENERICSTACKITEMTYPE_LONG_DOUBLE,
  _GENERICSTACKITEMTYPE_MAX
} genericStackItemType_t;

typedef struct genericStackItemTypeArray {
  void   *p;
  size_t  lengthl;
} genericStackItemTypeArray_t;

typedef struct genericStackItem {
  genericStackItemType_t type;
  union {
    char c;
    short s;
    int i;
    long l;
    float f;
    double d;
    void *p;
    genericStackItemTypeArray_t a;
#if GENERICSTACK_HAVE_LONG_LONG > 0
    long long ll;
#endif
#if GENERICSTACK_HAVE__BOOL > 0
    _Bool b;
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
    float _Complex fc;
    double _Complex dc;
    long double _Complex ldc;
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
    GENERICSTACK_CUSTOM custom;
#endif
    long double ld;
  } u;
} genericStackItem_t;

/* ====================================================================== */
/* Stack definition.                                                      */
/* ====================================================================== */
typedef struct genericStack {
  genericStackItem_t *items;   /* Point to defaultItems or heapItems      */
#if GENERICSTACK_DEFAULT_LENGTH > 0
  genericStackItem_t  defaultItems[GENERICSTACK_DEFAULT_LENGTH];
#endif
  genericStackItem_t *heapItems;
  int                 initialLengthi; /* Initial length                   */
  int                 heapi;   /* Heap length                             */
  int                 lengthi; /* Available length                        */
  int                 usedi;   /* Used length                             */
  int                 errori;  /* True if the stack had an error          */
} genericStack_t;

/* ====================================================================== */
/* "Inline"d functions                                                    */
/*                                                                        */
/* Not that we never assert: we assume that a SIGSEGV will be enough -;   */
/* ====================================================================== */

#ifdef GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES
/* we want to memset items[starti...endi] - no protection on indices because we call it only when we know we need it */
static GENERICSTACK_INLINE void _GENERICSTACK_NA_MEMSET(genericStack_t *stackp, int starti, int endi) {
  int indicei;

  for (indicei = starti; indicei <= endi; indicei++) {
    stackp->items[indicei].type = GENERICSTACKITEMTYPE_NA;
  }
}

#  if GENERICSTACK_DEFAULT_LENGTH > 0
static GENERICSTACK_INLINE short _GENERICSTACK_CREATE_HEAP(genericStack_t *stackp, int heapi) {
  short rcb;

  stackp->heapItems = (genericStackItem_t *) malloc(heapi * sizeof(genericStackItem_t));
  if (GENERICSTACK_UNLIKELY(stackp->heapItems == NULL)) {
    stackp->errori = 1;
    rcb = 0;
  } else {
    stackp->items = stackp->heapItems;
    if (stackp->usedi > 0) {
      memcpy(stackp->items, stackp->defaultItems, stackp->usedi * sizeof(genericStackItem_t));
    }
    stackp->lengthi = stackp->heapi = heapi;
    rcb = 1;
  }

  return rcb;
}
#  else /* GENERICSTACK_DEFAULT_LENGTH > 0 */
static GENERICSTACK_INLINE short _GENERICSTACK_CREATE_HEAP(genericStack_t *stackp, int heapi) {
  short rcb;

  stackp->heapItems = (genericStackItem_t *) malloc(heapi * sizeof(genericStackItem_t));
  if (GENERICSTACK_UNLIKELY(stackp->heapItems == NULL)) {
    stackp->errori = 1;
    rcb = 0;
  } else {
    stackp->items = stackp->heapItems;
    stackp->lengthi = stackp->heapi = heapi;
    rcb = 1;
  }

  return rcb;
}
#  endif /* GENERICSTACK_DEFAULT_LENGTH > 0 */
#else /* GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES */
static GENERICSTACK_INLINE void _GENERICSTACK_NA_MEMSET(genericStack_t *stackp, int starti, int endi) {
  memset(&(stackp->items[starti]), '\0', (endi - starti + 1) * sizeof(genericStackItem_t));
}
#  if GENERICSTACK_DEFAULT_LENGTH > 0
static GENERICSTACK_INLINE short _GENERICSTACK_CREATE_HEAP(genericStack_t *stackp, int heapi) {
  short rcb;

  /* No need to calloc: GENERICSTACK_NA_MEMSET() does the job when needed, and in practice this almost never happens */
  stackp->heapItems = (genericStackItem_t *) malloc(heapi * sizeof(genericStackItem_t));
  if (GENERICSTACK_UNLIKELY(stackp->heapItems == NULL)) {
    stackp->errori = 1;
    rcb = 0;
  } else {
    stackp->items = stackp->heapItems;
    if (stackp->usedi > 0) {
      memcpy(stackp->items, stackp->defaultItems, stackp->usedi * sizeof(genericStackItem_t));
    }
    /* No need to memset */
    stackp->lengthi = stackp->heapi = heapi;
    rcb = 1;
  }

  return rcb;
}
#  else /* GENERICSTACK_DEFAULT_LENGTH > 0 */
static GENERICSTACK_INLINE short _GENERICSTACK_CREATE_HEAP(genericStack_t *stackp, int heapi) {
  short rcb;

  stackp->heapItems = (genericStackItem_t *) malloc(heapi * sizeof(genericStackItem_t));
  if (GENERICSTACK_UNLIKELY(stackp->heapItems == NULL)) {
    stackp->errori = 1;
    rcb = 0;
  } else {
    stackp->items = stackp->heapItems;
    stackp->lengthi = stackp->heapi = heapi;
    rcb = 1;
  }

  return rcb;
}
#  endif /* GENERICSTACK_DEFAULT_LENGTH > 0 */
#endif /* GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES */

static GENERICSTACK_INLINE short _GENERICSTACK_EXTEND_HEAP(genericStack_t *stackp, int heapi) {
  short rcb;

  /* We are already on the heap, so previous value is in items */
  stackp->heapItems = (genericStackItem_t *) realloc(stackp->items, heapi * sizeof(genericStackItem_t));
  if (GENERICSTACK_UNLIKELY(stackp->heapItems == NULL)) {
    stackp->errori = 1;
    stackp->heapItems = stackp->items;
    rcb = 0;
  } else {
    /* Initialize new items to type GENERICSTACK_NA */
    /* Previous length was stackp->heapi: [0..stackp->heapi-1] */
    /* New length is heapi: [0..stackp->heapi.. heapi] */
    stackp->items = stackp->heapItems;
    stackp->lengthi = stackp->heapi = heapi;
    rcb = 1;
  }

  return rcb;
}

static GENERICSTACK_INLINE short _GENERICSTACK_EXTEND(genericStack_t *stackp, int wantedi, int targetIndicei) {
  short rcb;
  
  /* Do we need to go the heap ? */
  if (wantedi <= GENERICSTACK_DEFAULT_LENGTH) {
    rcb = 1;
  } else {
    /* Is heap already large enough ? */
    if (wantedi <= stackp->heapi) {
      rcb = 1;
    } else {
      /* Get the multiple of 2 that is >= wantedi */
      int heapi;
#ifdef GENERICSTACK_PARANOID
      int previousHeapi;
#endif

      /* https://www.geeksforgeeks.org/smallest-power-of-2-greater-than-or-equal-to-n/ */
      if (!(wantedi & (wantedi - 1))) {
        heapi = wantedi;
      } else {
#ifdef GENERICSTACK_PARANOID
        previousHeapi =
#endif
          heapi = 1;
        while (heapi < wantedi) {
          /* We count on compiler to optimize (<<= 1, + twice etc.) */
          heapi *= 2;
#ifdef GENERICSTACK_PARANOID
          if (heapi < previousHeapi) {
            /* Turnaround */
            heapi = 0;
            break;
          }
          previousHeapi = heapi;
#endif
        }
      }

      if (GENERICSTACK_UNLIKELY(heapi == 0)) {
        stackp->errori = 1;
        errno = EINVAL;
        rcb = 0;
      } else {
        rcb = (stackp->heapItems == NULL) ? _GENERICSTACK_CREATE_HEAP(stackp, heapi) : _GENERICSTACK_EXTEND_HEAP(stackp, heapi);
      }
    }
  }

  /* Are we targetting something that is bigger than the next unused indice ? */
  if (targetIndicei > stackp->usedi) {
    /* Current usage is: [0..stackp>usedi-1], user targets [0..stackp->usedi-1..targetIndicei where targetIndicei is bigger than stackp->usedi */
    _GENERICSTACK_NA_MEMSET(stackp, stackp->usedi, targetIndicei - 1);
  }

  return rcb;
}

#if GENERICSTACK_DEFAULT_LENGTH > 0
static GENERICSTACK_INLINE void _GENERICSTACK_INIT(genericStack_t *stackp) {
  stackp->items                                  = stackp->defaultItems;
  stackp->heapItems                              = NULL;
  stackp->lengthi = stackp->initialLengthi       = GENERICSTACK_DEFAULT_LENGTH;
  stackp->errori = stackp->usedi = stackp->heapi = 0;
}
#else /* GENERICSTACK_DEFAULT_LENGTH > 0 */
static GENERICSTACK_INLINE void _GENERICSTACK_INIT(genericStack_t *stackp) {
  stackp->heapItems = stackp->items                                                         = NULL;
  stackp->errori = stackp->usedi = stackp->heapi = stackp->lengthi = stackp->initialLengthi = 0;
}
#endif /* GENERICSTACK_DEFAULT_LENGTH > 0 */

static GENERICSTACK_INLINE short _GENERICSTACK_INIT_SIZED(genericStack_t *stackp, int lengthi) {
  short rcb;

  /* Note that _GENERICSTACK_INIT() never alters stackp->errori */
  _GENERICSTACK_INIT(stackp);
  rcb = _GENERICSTACK_EXTEND(stackp, lengthi, 0);
  if (GENERICSTACK_LIKELY(rcb)) {
    stackp->initialLengthi = lengthi;
  }

  return rcb;
}

static GENERICSTACK_INLINE void _GENERICSTACK_RESET(genericStack_t *stackp) {
  if (stackp != NULL) {
    if (stackp->heapItems != NULL) {
      free(stackp->heapItems);
      stackp->heapItems = NULL;
    }
    stackp->usedi = stackp->heapi = stackp->lengthi = 0;
  }
}

static GENERICSTACK_INLINE void _GENERICSTACK_FREE(genericStack_t *stackp) {
  if (stackp != NULL) {
    if (stackp->heapItems != NULL) {
      free(stackp->heapItems);
    }
    free(stackp);
  }
}

static GENERICSTACK_INLINE genericStack_t *_GENERICSTACK_NEW() {
    genericStack_t *stackp = (genericStack_t *) malloc(sizeof(genericStack_t));

    if (GENERICSTACK_LIKELY(stackp != NULL)) {
      _GENERICSTACK_INIT(stackp);
    }

    return stackp;
}

static GENERICSTACK_INLINE genericStack_t *_GENERICSTACK_NEW_SIZED(int lengthi) {
  genericStack_t *stackp = (genericStack_t *) malloc(sizeof(genericStack_t));

  if (GENERICSTACK_LIKELY(stackp != NULL)) {
    /* Note that _GENERICSTACK_INIT() never alters stackp->errori */
    _GENERICSTACK_INIT(stackp);
    if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, 0))) {
      _GENERICSTACK_FREE(stackp);
      stackp = NULL;
    }
  }
    
  return stackp;
}

static GENERICSTACK_INLINE void _GENERICSTACK_RELAX(genericStack_t *stackp) {
  if (stackp != NULL) {
    stackp->usedi = 0;
  }
}

#ifdef GENERICSTACK_PARANOID
#  define __GENERICSTACK_SET_BY_TYPE(varType, itemType, dst) \
  static GENERICSTACK_INLINE short _GENERICSTACK_SET_##itemType(genericStack_t *stackp, varType var, int indexi) { \
    short rcb;                                                          \
    int lengthi = indexi + 1;                                           \
                                                                        \
    /* Turnaround */                                                    \
    if (GENERICSTACK_UNLIKELY(lengthi < indexi)) {                      \
      stackp->errori = 1;                                               \
      rcb = 0;                                                          \
    } else {                                                            \
      if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, indexi))) { \
        rcb = 0;                                                        \
      } else {                                                          \
        if (stackp->usedi < lengthi) {                                  \
          stackp->usedi = lengthi;                                      \
        }                                                               \
        stackp->items[indexi].type = GENERICSTACKITEMTYPE_##itemType;   \
        stackp->items[indexi].u.dst = var;                              \
        rcb = 1;                                                        \
      }                                                                 \
    }                                                                   \
                                                                        \
    return rcb;                                                         \
}
#else /* GENERICSTACK_PARANOID */
#  define __GENERICSTACK_SET_BY_TYPE(varType, itemType, dst) \
  static GENERICSTACK_INLINE short _GENERICSTACK_SET_##itemType(genericStack_t *stackp, varType var, int indexi) { \
    short rcb;                                                          \
    int lengthi = indexi + 1;                                           \
                                                                        \
    if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, indexi))) { \
      rcb = 0;                                                          \
    } else {                                                            \
      if (stackp->usedi < lengthi) {                                    \
        stackp->usedi = lengthi;                                        \
      }                                                                 \
      stackp->items[indexi].type = GENERICSTACKITEMTYPE_##itemType;     \
      stackp->items[indexi].u.dst = var;                                \
      rcb = 1;                                                          \
    }                                                                   \
                                                                        \
    return rcb;                                                         \
}
#endif /* GENERICSTACK_PARANOID */

#ifdef GENERICSTACK_PARANOID
#  define __GENERICSTACK_SET_BY_TYPEP(varType, itemType, dst) \
  static GENERICSTACK_INLINE short _GENERICSTACK_SET_##itemType##P(genericStack_t *stackp, varType *var, int indexi) { \
    short rcb;                                                          \
    int lengthi = indexi + 1;                                           \
                                                                        \
    /* Turnaround */                                                    \
    if (GENERICSTACK_UNLIKELY(lengthi < indexi)) {                      \
      stackp->errori = 1;                                               \
      rcb = 0;                                                          \
    } else {                                                            \
      if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, indexi))) { \
        rcb = 0;                                                        \
      } else {                                                          \
        if (stackp->usedi < lengthi) {                                  \
          stackp->usedi = lengthi;                                      \
        }                                                               \
        stackp->items[indexi].type = GENERICSTACKITEMTYPE_##itemType;   \
        stackp->items[indexi].u.dst = *var;                             \
        rcb = 1;                                                        \
      }                                                                 \
    }                                                                   \
                                                                        \
    return rcb;                                                         \
}
#else /* GENERICSTACK_PARANOID */
#  define __GENERICSTACK_SET_BY_TYPEP(varType, itemType, dst) \
  static GENERICSTACK_INLINE short _GENERICSTACK_SET_##itemType##P(genericStack_t *stackp, varType *var, int indexi) { \
    short rcb;                                                          \
    int lengthi = indexi + 1;                                           \
                                                                        \
    if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, indexi))) { \
      rcb = 0;                                                          \
    } else {                                                            \
      if (stackp->usedi < lengthi) {                                    \
        stackp->usedi = lengthi;                                        \
      }                                                                 \
      stackp->items[indexi].type = GENERICSTACKITEMTYPE_##itemType;     \
      stackp->items[indexi].u.dst = *var;                               \
      rcb = 1;                                                          \
    }                                                                   \
                                                                        \
    return rcb;                                                         \
}
#endif /* GENERICSTACK_PARANOID */

__GENERICSTACK_SET_BY_TYPE(char, CHAR, c)
__GENERICSTACK_SET_BY_TYPE(short, SHORT, s)
__GENERICSTACK_SET_BY_TYPE(int, INT, i)
__GENERICSTACK_SET_BY_TYPE(long, LONG, l)
__GENERICSTACK_SET_BY_TYPE(long double, LONG_DOUBLE, ld)
__GENERICSTACK_SET_BY_TYPE(float, FLOAT, f)
__GENERICSTACK_SET_BY_TYPE(double, DOUBLE, d)
__GENERICSTACK_SET_BY_TYPE(void *, PTR, p)
__GENERICSTACK_SET_BY_TYPE(genericStackItemTypeArray_t, ARRAY, a)
__GENERICSTACK_SET_BY_TYPEP(genericStackItemTypeArray_t, ARRAY, a)
#if GENERICSTACK_HAVE_LONG_LONG > 0
  __GENERICSTACK_SET_BY_TYPE(long long, LONG_LONG, ll)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
  __GENERICSTACK_SET_BY_TYPE(_Bool, _BOOL, b)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
  __GENERICSTACK_SET_BY_TYPE(float _Complex, FLOAT__COMPLEX, fc)
  __GENERICSTACK_SET_BY_TYPE(double _Complex, DOUBLE__COMPLEX, dc)
  __GENERICSTACK_SET_BY_TYPE(long double _Complex, LONG_DOUBLE__COMPLEX, ldc)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
  __GENERICSTACK_SET_BY_TYPE(GENERICSTACK_CUSTOM, CUSTOM, custom)
  __GENERICSTACK_SET_BY_TYPEP(GENERICSTACK_CUSTOM, CUSTOM, custom)
#endif
/* Special case for N/A: there is no associated data */
static GENERICSTACK_INLINE short _GENERICSTACK_SET_NA(genericStack_t *stackp, int indexi) {
  short rcb;
  int lengthi = indexi + 1;

#ifdef GENERICSTACK_PARANOID
  /* Turnaround */
  if (GENERICSTACK_UNLIKELY(lengthi < indexi)) {
    stackp->errori = 1;
    rcb = 0;
  } else {
#endif
    if (GENERICSTACK_UNLIKELY(! _GENERICSTACK_EXTEND(stackp, lengthi, indexi))) {
      rcb = 0;
    } else {
      if (stackp->usedi < lengthi) {
        stackp->usedi = lengthi;
      }
      stackp->items[indexi].type = GENERICSTACKITEMTYPE_NA;
      rcb = 1;
    }
#ifdef GENERICSTACK_PARANOID
  }
#endif

  return rcb;
}

/* ====================================================================== */
/* Interface.                                                             */
/* ====================================================================== */
#define GENERICSTACK_ERROR(stackp)               (stackp)->errori
#define GENERICSTACK_ERROR_RESET(stackp)         (stackp)->errori = 0
#define GENERICSTACK_INITIAL_LENGTH(stackp)      (stackp)->initialLengthi
#define GENERICSTACK_HEAP_LENGTH(stackp)         (stackp)->heapi
#define GENERICSTACK_LENGTH(stackp)              (stackp)->lengthi
#define GENERICSTACK_USED(stackp)                (stackp)->usedi
#define GENERICSTACK_INIT(stackp)                _GENERICSTACK_INIT(stackp)
#define GENERICSTACK_NEW(stackp)                 (stackp) = _GENERICSTACK_NEW()
#define GENERICSTACK_NEW_SIZED(stackp, lengthi)  (stackp) = _GENERICSTACK_NEW_SIZED(lengthi)
#define GENERICSTACK_INIT_SIZED(stackp, lengthi) _GENERICSTACK_INIT_SIZED(stackp, lengthi)

/* ====================================================================== */
/* GET interface                                                          */
/* ====================================================================== */
#define GENERICSTACK_GET_CHAR(stackp, indexi)                   ((stackp)->items[indexi].u.c)
#define GENERICSTACK_GET_SHORT(stackp, indexi)                  ((stackp)->items[indexi].u.s)
#define GENERICSTACK_GET_INT(stackp, indexi)                    ((stackp)->items[indexi].u.i)
#define GENERICSTACK_GET_LONG(stackp, indexi)                   ((stackp)->items[indexi].u.l)
#define GENERICSTACK_GET_LONG_DOUBLE(stackp, indexi)            ((stackp)->items[indexi].u.ld)
#define GENERICSTACK_GET_FLOAT(stackp, indexi)                  ((stackp)->items[indexi].u.f)
#define GENERICSTACK_GET_DOUBLE(stackp, indexi)                 ((stackp)->items[indexi].u.d)
#define GENERICSTACK_GET_PTR(stackp, indexi)                    ((stackp)->items[indexi].u.p)
#define GENERICSTACK_GET_ARRAY(stackp, indexi)                  ((stackp)->items[indexi].u.a)
#define GENERICSTACK_GET_ARRAYP(stackp, indexi)                 (&((stackp)->items[indexi].u.a))
#if GENERICSTACK_HAVE_LONG_LONG > 0
#  define GENERICSTACK_GET_LONG_LONG(stackp, indexi)            ((stackp)->items[indexi].u.ll)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#  define GENERICSTACK_GET__BOOL(stackp, indexi)                ((stackp)->items[indexi].u.b)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#  define GENERICSTACK_GET_FLOAT__COMPLEX(stackp, indexi)       ((stackp)->items[indexi].u.fc)
#  define GENERICSTACK_GET_DOUBLE__COMPLEX(stackp, indexi)      ((stackp)->items[indexi].u.dc)
#  define GENERICSTACK_GET_LONG_DOUBLE__COMPLEX(stackp, indexi) ((stackp)->items[indexi].u.ldc)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#  define GENERICSTACK_GET_CUSTOM(stackp, indexi)               ((stackp)->items[indexi].u.custom)
#  define GENERICSTACK_GET_CUSTOMP(stackp, indexi)              (&((stackp)->items[indexi].u.custom))
#endif
/* Per def N/A value is undefined - we just have to make sure indexi is processed */
#define GENERICSTACK_GET_NA(stackp, indexi)                     (indexi)

/* ====================================================================== */
/* SET interface                                                          */
/* ====================================================================== */
#define GENERICSTACK_SET_CHAR(stackp, var, index)                   _GENERICSTACK_SET_CHAR(stackp, var, index)
#define GENERICSTACK_SET_SHORT(stackp, var, index)                  _GENERICSTACK_SET_SHORT(stackp, var, index)
#define GENERICSTACK_SET_INT(stackp, var, index)                    _GENERICSTACK_SET_INT(stackp, var, index)
#define GENERICSTACK_SET_LONG(stackp, var, index)                   _GENERICSTACK_SET_LONG(stackp, var, index)
#define GENERICSTACK_SET_LONG_DOUBLE(stackp, var, index)            _GENERICSTACK_SET_LONG_DOUBLE(stackp, var, index)
#define GENERICSTACK_SET_FLOAT(stackp, var, index)                  _GENERICSTACK_SET_FLOAT(stackp, var, index)
#define GENERICSTACK_SET_DOUBLE(stackp, var, index)                 _GENERICSTACK_SET_DOUBLE(stackp, var, index)
#define GENERICSTACK_SET_PTR(stackp, var, index)                    _GENERICSTACK_SET_PTR(stackp, var, index)
#define GENERICSTACK_SET_ARRAY(stackp, var, index)                  _GENERICSTACK_SET_ARRAY(stackp, var, index)
#define GENERICSTACK_SET_ARRAYP(stackp, var, index)                 _GENERICSTACK_SET_ARRAYP(stackp, var, index)
#if GENERICSTACK_HAVE_LONG_LONG > 0
#  define GENERICSTACK_SET_LONG_LONG(stackp, var, index)            _GENERICSTACK_SET_LONG_LONG(stackp, var, index)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#  define GENERICSTACK_SET__BOOL(stackp, var, index)                _GENERICSTACK_SET_BOOL(stackp, var, index)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#  define GENERICSTACK_SET_FLOAT__COMPLEX(stackp, var, index)       _GENERICSTACK_SET_FLOAT__COMPLEX(stackp, var, index)
#  define GENERICSTACK_SET_DOUBLE__COMPLEX(stackp, var, index)      _GENERICSTACK_SET_DOUBLE__COMPLEX(stackp, var, index)
#  define GENERICSTACK_SET_LONG_DOUBLE__COMPLEX(stackp, var, index) _GENERICSTACK_SET_LONG_DOUBLE__COMPLEX(stackp, var, index)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#  define GENERICSTACK_SET_CUSTOM(stackp, var, index)               _GENERICSTACK_SET_CUSTOM(stackp, var, index)
#  define GENERICSTACK_SET_CUSTOMP(stackp, var, index)              _GENERICSTACK_SET_CUSTOMP(stackp, var, index)
#endif
#define GENERICSTACK_SET_NA(stackp, index)                          _GENERICSTACK_SET_NA(stackp, index)

/* ====================================================================== */
/* PUSH interface: built on top of SET                                    */
/* ====================================================================== */
#define GENERICSTACK_PUSH_CHAR(stackp, var)                   GENERICSTACK_SET_CHAR(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_SHORT(stackp, var)                  GENERICSTACK_SET_SHORT(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_INT(stackp, var)                    GENERICSTACK_SET_INT(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_LONG(stackp, var)                   GENERICSTACK_SET_LONG(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_LONG_DOUBLE(stackp, var)            GENERICSTACK_SET_LONG_DOUBLE(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_FLOAT(stackp, var)                  GENERICSTACK_SET_FLOAT(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_DOUBLE(stackp, var)                 GENERICSTACK_SET_DOUBLE(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_PTR(stackp, var)                    GENERICSTACK_SET_PTR(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_ARRAY(stackp, var)                  GENERICSTACK_SET_ARRAY(stackp, var, (stackp)->usedi)
#define GENERICSTACK_PUSH_ARRAYP(stackp, var)                 GENERICSTACK_SET_ARRAYP(stackp, var, (stackp)->usedi)
#if GENERICSTACK_HAVE_LONG_LONG > 0
#  define GENERICSTACK_PUSH_LONG_LONG(stackp, var)            GENERICSTACK_SET_LONG_LONG(stackp, var, (stackp)->usedi)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#  define GENERICSTACK_PUSH__BOOL(stackp, var)                GENERICSTACK_SET__BOOL(stackp, var, (stackp)->usedi)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#  define GENERICSTACK_PUSH_FLOAT__COMPLEX(stackp, var)       GENERICSTACK_SET_FLOAT__COMPLEX(stackp, var, (stackp)->usedi)
#  define GENERICSTACK_PUSH_DOUBLE__COMPLEX(stackp, var)      GENERICSTACK_SET_DOUBLE__COMPLEX(stackp, var, (stackp)->usedi)
#  define GENERICSTACK_PUSH_LONG_DOUBLE__COMPLEX(stackp, var) GENERICSTACK_SET_LONG_DOUBLE__COMPLEX(stackp, var, (stackp)->usedi)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#  define GENERICSTACK_PUSH_CUSTOM(stackp, var)               GENERICSTACK_SET_CUSTOM(stackp, var, (stackp)->usedi)
#  define GENERICSTACK_PUSH_CUSTOMP(stackp, var)              GENERICSTACK_SET_CUSTOMP(stackp, var, (stackp)->usedi)
#endif
#define GENERICSTACK_PUSH_NA(stackp)                          GENERICSTACK_SET_NA(stackp, (stackp)->usedi)

/* ====================================================================== */
/* POP interface: built on top GET                                        */
/* ====================================================================== */
#define GENERICSTACK_POP_CHAR(stackp)                         GENERICSTACK_GET_CHAR(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_SHORT(stackp)                        GENERICSTACK_GET_SHORT(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_INT(stackp)                          GENERICSTACK_GET_INT(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_LONG(stackp)                         GENERICSTACK_GET_LONG(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_LONG_DOUBLE(stackp)                  GENERICSTACK_GET_LONG_DOUBLE(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_FLOAT(stackp)                        GENERICSTACK_GET_FLOAT(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_DOUBLE(stackp)                       GENERICSTACK_GET_DOUBLE(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_PTR(stackp)                          GENERICSTACK_GET_PTR(stackp, --(stackp)->usedi)
#define GENERICSTACK_POP_ARRAY(stackp)                        GENERICSTACK_GET_ARRAY(stackp,--(stackp)->usedi)
#if GENERICSTACK_HAVE_LONG_LONG > 0
#  define GENERICSTACK_POP_LONG_LONG(stackp)                  GENERICSTACK_GET_LONG_LONG(stackp, --(stackp)->usedi)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#  define GENERICSTACK_POP__BOOL(stackp)                      GENERICSTACK_GET__BOOL(stackp, --(stackp)->usedi)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#  define GENERICSTACK_POP_FLOAT__COMPLEX(stackp)             GENERICSTACK_GET_FLOAT__COMPLEX(stackp, --(stackp)->usedi)
#  define GENERICSTACK_POP_DOUBLE__COMPLEX(stackp)            GENERICSTACK_GET_DOUBLE__COMPLEX(stackp, --(stackp)->usedi)
#  define GENERICSTACK_POP_LONG_DOUBLE__COMPLEX(stackp)       GENERICSTACK_GET_LONG_DOUBLE__COMPLEX(stackp, --(stackp)->usedi)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#  define GENERICSTACK_POP_CUSTOM(stackp)                     GENERICSTACK_GET_CUSTOM(stackp, --(stackp)->usedi)
#endif
#define GENERICSTACK_POP_NA(stackp)                           GENERICSTACK_GET_NA(stackp, --(stackp)->usedi)

/* ====================================================================== */
/* Memory release                                                         */
/* We intentionnaly loop on size and not used.                            */
/* ====================================================================== */
#define GENERICSTACK_RESET(stackp) _GENERICSTACK_RESET(stackp)
#define GENERICSTACK_FREE(stackp) _GENERICSTACK_FREE(stackp)
#define GENERICSTACK_RELAX(stackp) _GENERICSTACK_RELAX(stackp)

/* ====================================================================== */
/* In some rare occasions user might want to get the basic type           */
/* from an item type.                                                     */
/* ====================================================================== */
#define GENERICSTACKITEMTYPE(stackp, index) (stackp)->items[index].type

#define GENERICSTACKITEMTYPE2TYPE_CHAR                   char
#define GENERICSTACKITEMTYPE2TYPE_SHORT                  short
#define GENERICSTACKITEMTYPE2TYPE_INT                    int
#define GENERICSTACKITEMTYPE2TYPE_LONG                   long
#define GENERICSTACKITEMTYPE2TYPE_LONG_DOUBLE            long double
#define GENERICSTACKITEMTYPE2TYPE_FLOAT                  float
#define GENERICSTACKITEMTYPE2TYPE_DOUBLE                 double
#define GENERICSTACKITEMTYPE2TYPE_PTR                    void *
#define GENERICSTACKITEMTYPE2TYPE_ARRAY                  genericStackItemTypeArray_t
#define GENERICSTACKITEMTYPE2TYPE_ARRAYP                 genericStackItemTypeArray_t *
#define GENERICSTACK_ARRAY_PTR(a)                        (a).p
#define GENERICSTACK_ARRAYP_PTR(a)                       (a)->p
#define GENERICSTACK_ARRAY_LENGTH(a)                     (a).lengthl
#define GENERICSTACK_ARRAYP_LENGTH(a)                    (a)->lengthl
#if GENERICSTACK_HAVE_LONG_LONG
  #define GENERICSTACKITEMTYPE2TYPE_LONG_LONG            long long
#endif
#if GENERICSTACK_HAVE__BOOL
  #define GENERICSTACKITEMTYPE2TYPE__BOOL                _Bool
#endif
#if GENERICSTACK_HAVE__COMPLEX
  #define GENERICSTACKITEMTYPE2TYPE_FLOAT__COMPLEX       float _Complex
  #define GENERICSTACKITEMTYPE2TYPE_DOUBLE__COMPLEX      double _Complex
  #define GENERICSTACKITEMTYPE2TYPE_LONG_DOUBLE__COMPLEX long double _Complex
#endif
#if GENERICSTACK_HAVE_CUSTOM
  #define GENERICSTACKITEMTYPE2TYPE_CUSTOM               GENERICSTACK_CUSTOM
  #define GENERICSTACKITEMTYPE2TYPE_CUSTOMP              GENERICSTACK_CUSTOM *
#endif

/* ====================================================================== */
/* IS interface                                                           */
/* ====================================================================== */
#define GENERICSTACK_EXISTS(stackp, i) (((stackp) != NULL) && ((stackp)->usedi > i))
#define GENERICSTACK_IS_NA(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_NA))
#define GENERICSTACK_IS_CHAR(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_CHAR))
#define GENERICSTACK_IS_SHORT(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_SHORT))
#define GENERICSTACK_IS_INT(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_INT))
#define GENERICSTACK_IS_LONG(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_LONG))
#define GENERICSTACK_IS_LONG_DOUBLE(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_LONG_DOUBLE))
#define GENERICSTACK_IS_FLOAT(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_FLOAT))
#define GENERICSTACK_IS_DOUBLE(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_DOUBLE))
#define GENERICSTACK_IS_PTR(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_PTR))
#define GENERICSTACK_IS_ARRAY(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_ARRAY))
#if GENERICSTACK_HAVE_LONG_LONG
#define GENERICSTACK_IS_LONG_LONG(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_LONG_LONG))
#endif
#if GENERICSTACK_HAVE__BOOL
#define GENERICSTACK_IS__BOOL(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE__BOOL))
#endif
#if GENERICSTACK_HAVE__COMPLEX
#define GENERICSTACK_IS_FLOAT__COMPLEX(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_FLOAT__COMPLEX))
#define GENERICSTACK_IS_DOUBLE__COMPLEX(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_DOUBLE__COMPLEX))
#define GENERICSTACK_IS_LONG_DOUBLE__COMPLEX(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_LONG_DOUBLE__COMPLEX))
#endif
#if GENERICSTACK_HAVE_CUSTOM
#define GENERICSTACK_IS_CUSTOM(stackp, i) (GENERICSTACK_EXISTS(stackp, i) && (GENERICSTACKITEMTYPE((stackp), (i)) == GENERICSTACKITEMTYPE_CUSTOM))
#endif

/* ====================================================================== */
/* Dump macro for development purpose. Fixed to stderr.                   */
/* ====================================================================== */
#if GENERICSTACK_HAVE_CUSTOM
#define _GENERICSTACK_DUMP_CASE_CUSTOM(stackp,indice) case GENERICSTACKITEMTYPE_CUSTOM: fprintf(stderr, "Element[%3ld/%3ld] type     : CUSTOM\n", (unsigned long) indice, (unsigned long) GENERICSTACK_USED(stackp)); break;
#else
#define _GENERICSTACK_DUMP_CASE_CUSTOM(stackp,indice)
#endif
#define GENERICSTACK_DUMP(stackp) do {                                  \
    int _i_for_dump;							\
    fprintf(stderr, "GENERIC STACK DUMP\n");				\
    fprintf(stderr, "------------------\n");				\
    fprintf(stderr, "Items                     : %p\n", stackp->items); \
    fprintf(stderr, "Heap items                : %p\n", stackp->heapItems); \
    fprintf(stderr, "Initial Length            : %d\n", GENERICSTACK_INITIAL_LENGTH(stackp)); \
    fprintf(stderr, "Heap Length               : %d\n", GENERICSTACK_HEAP_LENGTH(stackp)); \
    fprintf(stderr, "Length                    : %d\n", GENERICSTACK_LENGTH(stackp)); \
    fprintf(stderr, "Used:                     : %d\n", GENERICSTACK_USED(stackp)); \
    fprintf(stderr, "Error?                    : %s\n", GENERICSTACK_ERROR(stackp) ? "yes" : "no"); \
    for (_i_for_dump = 0; _i_for_dump < GENERICSTACK_USED(stackp); _i_for_dump++) { \
      switch(GENERICSTACKITEMTYPE(stackp, _i_for_dump)) {		\
      case GENERICSTACKITEMTYPE_NA:					\
	fprintf(stderr, "Element[%3d/%3d] type     : NA\n", _i_for_dump, GENERICSTACK_USED(stackp));	\
	break;								\
      case GENERICSTACKITEMTYPE_CHAR:					\
	fprintf(stderr, "Element[%3d/%3d] type     : CHAR\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_SHORT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : SHORT\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_INT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : INT\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_LONG:					\
	fprintf(stderr, "Element[%3d/%3d] type     : LONG\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_FLOAT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : FLOAT\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_DOUBLE:					\
	fprintf(stderr, "Element[%3d/%3d] type     : DOUBLE\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_PTR:					\
	fprintf(stderr, "Element[%3d/%3d] type     : PTR\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_ARRAY:					\
	fprintf(stderr, "Element[%3d/%3d] type     : ARRAY\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      case GENERICSTACKITEMTYPE_LONG_DOUBLE:                            \
	fprintf(stderr, "Element[%3d/%3d] type     : LONG DOUBLE\n", _i_for_dump, GENERICSTACK_USED(stackp)); \
	break;								\
      default:								\
	fprintf(stderr, "Element[%3d/%3d] type     : %d\n", _i_for_dump, GENERICSTACK_USED(stackp), GENERICSTACKITEMTYPE(stackp, _i_for_dump)); \
	break;								\
        _GENERICSTACK_DUMP_CASE_CUSTOM(stackp,_i_for_dump)           \
      }									\
    }									\
 } while (0)
     
/* ====================================================================== */
/* Switches two entries                                                   */
/* We support a "negative index", which mean start by far from the end.   */
/* ====================================================================== */
#define GENERICSTACK_SWITCH(stackp, i1, i2) do {                     \
    int _genericStackSwitch_index1 = (int) (i1);                        \
    int _genericStackSwitch_index2 = (int) (i2);                        \
                                                                        \
    if (_genericStackSwitch_index1 < 0) {                               \
      _genericStackSwitch_index1 = (stackp)->usedi + _genericStackSwitch_index1; \
    }                                                                   \
    if (_genericStackSwitch_index2 < 0) {                               \
      _genericStackSwitch_index2 = (stackp)->usedi + _genericStackSwitch_index2; \
    }                                                                   \
                                                                        \
    if (GENERICSTACK_UNLIKELY((_genericStackSwitch_index1 < 0) || ((_genericStackSwitch_index1) >= (stackp)->usedi) || \
                              (_genericStackSwitch_index2 < 0) || ((_genericStackSwitch_index2) >= (stackp)->usedi))) { \
      (stackp)->errori = 1;                                          \
      errno = EINVAL;                                                   \
    } else if (_genericStackSwitch_index1 != _genericStackSwitch_index2) { \
      genericStackItem_t _item = (stackp)->items[_genericStackSwitch_index1]; \
      void *_addr1 = (void *) &((stackp)->items[_genericStackSwitch_index1]); \
      void *_addr2 = (void *) &((stackp)->items[_genericStackSwitch_index2]); \
                                                                        \
      memcpy(_addr1, _addr2,  sizeof(genericStackItem_t));              \
      memcpy(_addr2, &_item,  sizeof(genericStackItem_t));              \
    }                                                                   \
  } while (0)

#define GENERICSTACK_SORT(stackName, callback) qsort((void *) (stackName)->items, (size_t) (stackName)->usedi, sizeof(genericStackItem_t), callback)

#endif /* GENERICSTACK_H */
