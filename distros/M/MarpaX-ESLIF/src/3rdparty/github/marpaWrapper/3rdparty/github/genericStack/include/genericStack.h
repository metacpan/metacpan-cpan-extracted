#ifndef GENERICSTACK_H
#define GENERICSTACK_H

#include <stdlib.h>       /* For malloc, free */
#include <string.h>       /* For memcpy */

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
/* Stack general rules are:                                               */
/* - a PUSH always increases the stack size if necessary                  */
/* - a POP  always decreases the stack size if possible                   */
/* - a SET  always increases the stack size if necessary                  */
/* - a GET  never changes stack size                                      */
/* ---------------------------------------------------------------------- */

/* ====================================================================== */
/* Stack default length.                                                  */
/* ====================================================================== */
#ifndef GENERICSTACK_DEFAULT_LENGTH
#define GENERICSTACK_DEFAULT_LENGTH 128 /* Subjective number */
#endif
#if GENERICSTACK_DEFAULT_LENGTH > 0
const static int __genericStack_max_initial_indice = GENERICSTACK_DEFAULT_LENGTH - 1;
#else
const static int __genericStack_max_initial_indice = -1; /* Not used */
#endif

/* ====================================================================== */
/* Setting values to zero integer. I do not know any system where a zero  */
/* is not represented by zero bytes. Nevertheless, if that is your case   */
/* you should define GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES              */
/* ====================================================================== */
#ifdef GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES
#define _GENERICSTACK_CALLOC(memsetflag, dst, nmemb, size) do {		\
    memsetflag = 1;							\
    dst = malloc(nmemb * size);						\
  } while (0)
#define _GENERICSTACK_MALLOC(memsetflag, size) memsetflag=1, malloc(size)
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define _GENERICSTACK_NA_MEMSET(stackName, indiceStart, indiceEnd) do {	\
    if (indiceStart <= indiceEnd) {					\
      if (indiceStart <= __genericStack_max_initial_indice) {		\
	int _i_for_memset;						\
	int _i_for_memset_max = (indiceEnd >= __genericStack_max_initial_indice) ? __genericStack_max_initial_indice : indiceEnd; \
	for (_i_for_memset = indiceStart;				\
	     _i_for_memset <= _i_for_memset_max;			\
	     _i_for_extend++) {						\
	  stackName->initialItems[_i_for_extend].type = GENERICSTACKITEMTYPE_NA; \
	}								\
      }									\
      if (indiceEnd > __genericStack_max_initial_indice) {		\
	int _i_for_memset_min = (indiceStart <= __genericStack_max_initial_indice) ? 0 : indiceStart - __genericStack_max_initial_indice - 1; \
	int _i_for_memset_max = indiceEnd - __genericStack_max_initial_indice - 1; \
	for (_i_for_memset = _i_for_memset_min;				\
	     _i_for_memset <= _i_for_memset_max;			\
	     _i_for_extend++) {						\
	  stackName->heapItems[_i_for_extend].type = GENERICSTACKITEMTYPE_NA; \
	}								\
      }									\
    }									\
  } while (0)
#else /* GENERICSTACK_DEFAULT_LENGTH > 0 */
#define _GENERICSTACK_NA_MEMSET(stackName, indiceStart, indiceEnd) do {	\
    if (indiceStart <= indiceEnd) {					\
      for (_i_for_memset = indiceStart;					\
	   _i_for_memset <= indiceEnd;					\
	   _i_for_extend++) {						\
	stackName->heapItems[_i_for_extend].type = GENERICSTACKITEMTYPE_NA; \
      }									\
    }									\
  } while (0)
#endif /* GENERICSTACK_DEFAULT_LENGTH */
#else /* GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES */
#define _GENERICSTACK_CALLOC(memsetflag, dst, nmemb, size) do {		\
    memsetflag = 0;							\
    dst = calloc(nmemb, size);						\
  } while (0)
#define _GENERICSTACK_MALLOC(memsetflag, size) memsetflag=0, malloc(size)
#if GENERICSTACK_DEFAULT_LENGTH > 0
#define _GENERICSTACK_NA_MEMSET(stackName, indiceStart, indiceEnd) do {	\
    if (indiceStart <= indiceEnd) {					\
      if (indiceStart <= __genericStack_max_initial_indice) {		\
	int _i_for_memset_max = (indiceEnd >= __genericStack_max_initial_indice) ? __genericStack_max_initial_indice : indiceEnd; \
	int _full_length;						\
									\
	_full_length = _i_for_memset_max;				\
	_full_length -= indiceStart;					\
	memset(&(stackName->initialItems[indiceStart]), '\0', ++_full_length * sizeof(genericStackItem_t)); \
      }									\
      if (indiceEnd > __genericStack_max_initial_indice) {		\
	int _i_for_memset_min = (indiceStart <= __genericStack_max_initial_indice) ? 0 : indiceStart - __genericStack_max_initial_indice - 1; \
	int _i_for_memset_max = indiceEnd - __genericStack_max_initial_indice - 1; \
	int _full_length = _i_for_memset_max - _i_for_memset_min + 1;	\
									\
	memset(&(stackName->heapItems[_i_for_memset_min]), '\0', _full_length * sizeof(genericStackItem_t)); \
      }									\
    }									\
  } while (0)
#else /* GENERICSTACK_DEFAULT_LENGTH */
#define _GENERICSTACK_NA_MEMSET(stackName, indiceStart, indiceEnd) do {	\
    if (indiceStart <= indiceEnd) {					\
      int _full_length = indiceEnd - indiceStart + 1;			\
									\
      memset(&(stackName->heapItems[indiceStart]), '\0', _full_length * sizeof(genericStackItem_t)); \
    }									\
  } while (0)
#endif /* GENERICSTACK_DEFAULT_LENGTH */
#endif

#if GENERICSTACK_DEFAULT_LENGTH > 0
#define _GENERICSTACK_DECLARE_INITIAL_ITEMS()			\
  genericStackItem_t  defaultItems[GENERICSTACK_DEFAULT_LENGTH];	\
  genericStackItem_t *initialItems
#ifdef GENERICSTACK_ZERO_INT_IS_NOT_ZERO_BYTES
#define _GENERICSTACK_INIT_INITIAL_ITEMS(stackName)	\
  stackName->initialItems = stackName->defaultItems;	\
  memset(stackName->defaultItems, 0, GENERICSTACK_DEFAULT_LENGTH)
#else
#define _GENERICSTACK_INIT_INITIAL_ITEMS(stackName)	\
  stackName->initialItems = stackName->defaultItems;
#endif
#else
#define _GENERICSTACK_DECLARE_INITIAL_ITEMS()	\
  genericStackItem_t *initialItems
#define _GENERICSTACK_INIT_INITIAL_ITEMS(stackName)	\
  stackName->initialItems = NULL;
#endif

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
#ifdef GENERICSTACK_CUSTOM
#  undef GENERICSTACK_HAVE_CUSTOM
#  define GENERICSTACK_HAVE_CUSTOM 1
#else
#  ifndef GENERICSTACK_HAVE_CUSTOM
#    define GENERICSTACK_HAVE_CUSTOM 0
#  endif
#endif

typedef void *(*genericStackClone_t)(void *p);
typedef void  (*genericStackFree_t)(void *p);
typedef struct genericStackItemTypeArray {
  void   *p;
  size_t lengthl;
} genericStackItemTypeArray_t;

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

typedef struct genericStack {
  int heapLength;
  int used;
  genericStackItem_t *heapItems;
  short  error;
  int tmpIndex;
  int tmpSize;
  genericStackItem_t *tmpItems;
  _GENERICSTACK_DECLARE_INITIAL_ITEMS();
} genericStack_t;

/* General note: parameters for internal macros are not enclosed in ()    */
/* because this operation is done on external macros.                     */

/* ====================================================================== */
/* Error detection and reset                                              */
/* ====================================================================== */
#define GENERICSTACK_ERROR(stackName) (((stackName) == NULL) || ((stackName)->error != 0))
#define GENERICSTACK_ERROR_RESET(stackName) do {			\
    if ((stackName) != NULL) {						\
      (stackName)->error = 0;						\
    }									\
  } while (0)

/* ====================================================================== */
/* Give an index, return the item union                                   */
/* ====================================================================== */
#define _GENERICSTACK_ITEM_ADDR(stackName, index) (((stackName->tmpIndex = index) >= GENERICSTACK_DEFAULT_LENGTH) ? &(stackName->heapItems[stackName->tmpIndex - GENERICSTACK_DEFAULT_LENGTH]) : &(stackName->initialItems[stackName->tmpIndex]))
#define _GENERICSTACK_ITEM(stackName, index) (((stackName->tmpIndex = index) >= GENERICSTACK_DEFAULT_LENGTH) ? stackName->heapItems[stackName->tmpIndex - GENERICSTACK_DEFAULT_LENGTH] : stackName->initialItems[stackName->tmpIndex])
#define _GENERICSTACK_ITEM_DST(stackName, index, what) (((stackName->tmpIndex = index) >= GENERICSTACK_DEFAULT_LENGTH) ? stackName->heapItems[stackName->tmpIndex - GENERICSTACK_DEFAULT_LENGTH].what : stackName->initialItems[stackName->tmpIndex].what)
#define _GENERICSTACK_ITEM_DST_ADDR(stackName, index, what) (((stackName->tmpIndex = index) >= GENERICSTACK_DEFAULT_LENGTH) ? &(stackName->heapItems[stackName->tmpIndex - GENERICSTACK_DEFAULT_LENGTH].what) : &(stackName->initialItems[stackName->tmpIndex].what))
#define _GENERICSTACK_ITEM_DST_SET(stackName, index, what, val) do {	\
    int _tmpIndex = index;						\
    if (_tmpIndex >= GENERICSTACK_DEFAULT_LENGTH) {			\
      stackName->heapItems[_tmpIndex - GENERICSTACK_DEFAULT_LENGTH].what = val; \
    } else {								\
      stackName->initialItems[_tmpIndex].what = val;			\
    }									\
  } while (0)

/* ====================================================================== */
/* Return the total number of initial available items (!= used items)     */
/* ====================================================================== */
#define GENERICSTACK_INITIAL_LENGTH(stackName) GENERICSTACK_DEFAULT_LENGTH

/* ====================================================================== */
/* Return the total number of heap available items (!= used items)        */
/* ====================================================================== */
#define GENERICSTACK_HEAP_LENGTH(stackName) (stackName)->heapLength

/* ====================================================================== */
/* Return the total number of available items (!= used items)             */
/* ====================================================================== */
#define GENERICSTACK_LENGTH(stackName) (GENERICSTACK_INITIAL_LENGTH(stackName) + GENERICSTACK_HEAP_LENGTH(stackName))

/* ====================================================================== */
/* Used size                                                              */
/* ====================================================================== */
#define GENERICSTACK_USED(stackName) (stackName)->used

/* ====================================================================== */
/* Size management, internal macro                                        */
/* We check for int turnaround heuristically.                             */
/* ====================================================================== */
#define _GENERICSTACK_EXTEND(stackName, wantedLength) do {		\
    int _genericStackExtend_wantedLength = wantedLength;		\
    int _genericStackExtend_currentLength = GENERICSTACK_LENGTH(stackName); \
    if ((_genericStackExtend_wantedLength > GENERICSTACK_DEFAULT_LENGTH) &&	\
	(_genericStackExtend_wantedLength > _genericStackExtend_currentLength)) { \
      int _genericStackExtend_wantedHeapLength = _genericStackExtend_wantedLength - GENERICSTACK_DEFAULT_LENGTH; \
      int _genericStackExtend_currentHeapLength = _genericStackExtend_currentLength - GENERICSTACK_DEFAULT_LENGTH; \
      int _genericStackExtend_newHeapLength;				\
      genericStackItem_t *_genericStackExtend_heapItems = stackName->heapItems; \
      short _genericStackExtend_memsetb;				\
                                                                        \
      if (_genericStackExtend_currentHeapLength <= 0) {			\
        _genericStackExtend_newHeapLength = _genericStackExtend_wantedHeapLength; \
      } else {                                                          \
        _genericStackExtend_newHeapLength = _genericStackExtend_currentHeapLength * 2; \
        if ((_genericStackExtend_newHeapLength < _genericStackExtend_currentHeapLength) || \
	    (_genericStackExtend_newHeapLength < _genericStackExtend_wantedHeapLength)) { \
          _genericStackExtend_newHeapLength = _genericStackExtend_wantedHeapLength; \
        }                                                               \
      }                                                                 \
      if (_genericStackExtend_heapItems == NULL) {			\
	_GENERICSTACK_CALLOC(_genericStackExtend_memsetb, _genericStackExtend_heapItems, _genericStackExtend_newHeapLength, sizeof(genericStackItem_t)); \
      } else {								\
	_genericStackExtend_memsetb = 1;							\
	_genericStackExtend_heapItems = (genericStackItem_t *) realloc(_genericStackExtend_heapItems, sizeof(genericStackItem_t) * _genericStackExtend_newHeapLength); \
      }									\
      if (_genericStackExtend_heapItems == NULL) {			\
	stackName->error = 1;						\
      } else {								\
	stackName->heapItems = _genericStackExtend_heapItems;		\
	if (_genericStackExtend_memsetb != 0) {                         \
	  _GENERICSTACK_NA_MEMSET(stackName, GENERICSTACK_DEFAULT_LENGTH + stackName->heapLength, GENERICSTACK_DEFAULT_LENGTH + _genericStackExtend_newHeapLength - 1);	\
	}								\
	stackName->heapLength = _genericStackExtend_newHeapLength;	\
      }									\
    }									\
    if ((GENERICSTACK_DEFAULT_LENGTH > 0) && (_genericStackExtend_wantedLength > GENERICSTACK_DEFAULT_LENGTH)) { \
      if (GENERICSTACK_USED(stackName) < GENERICSTACK_DEFAULT_LENGTH) { \
	if (GENERICSTACK_USED(stackName) <= 0) { \
	  _GENERICSTACK_NA_MEMSET(stackName, 0, __genericStack_max_initial_indice); \
	} else {							\
	  _GENERICSTACK_NA_MEMSET(stackName, GENERICSTACK_USED(stackName), __genericStack_max_initial_indice); \
	}								\
      }									\
    }									\
  } while (0)

/* ====================================================================== */
/* Initialization                                                         */
/* ====================================================================== */
#define GENERICSTACK_INIT(stackName) do {                               \
    if ((stackName) != NULL) {						\
      _GENERICSTACK_INIT_INITIAL_ITEMS(stackName);			\
      (stackName)->heapItems = NULL;					\
      (stackName)->heapLength = 0;					\
      (stackName)->used = 0;						\
      (stackName)->error = 0;						\
    }									\
  } while (0)

#define GENERICSTACK_NEW(stackName) do {				\
    (stackName) = malloc(sizeof(genericStack_t));			\
    GENERICSTACK_INIT((stackName));					\
  } while (0)

#define GENERICSTACK_NEW_SIZED(stackName, wantedLength) do {		\
    GENERICSTACK_NEW((stackName));					\
    if (! GENERICSTACK_ERROR(stackName)) {				\
      _GENERICSTACK_EXTEND((stackName), (wantedLength));		\
    }									\
  } while (0)

#define GENERICSTACK_INIT_SIZED(stackName, wantedLength) do {		\
    GENERICSTACK_INIT((stackName));					\
    if (! GENERICSTACK_ERROR(stackName)) {				\
      _GENERICSTACK_EXTEND((stackName), (wantedLength));		\
    }									\
  } while (0)

/* ====================================================================== */
/* SET interface: Stack is extended on demand, gap is eventually filled   */
/* ====================================================================== */
/* stackName is expected to an identifier                                 */
/* index is used more than once, so it has to be cached                   */
#define _GENERICSTACK_SET_BY_TYPE(stackName, varType, var, itemType, dst, index) do { \
    int _genericStackSetByType_indexForSet = index;			\
    int _genericStackSetByType_wantedLength = _genericStackSetByType_indexForSet + 1; \
									\
    if (_genericStackSetByType_wantedLength > GENERICSTACK_LENGTH(stackName)) { \
                                                                        \
      _GENERICSTACK_EXTEND(stackName, _genericStackSetByType_wantedLength); \
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    } else if (_genericStackSetByType_wantedLength > GENERICSTACK_USED(stackName)) { \
      									\
      if (_genericStackSetByType_indexForSet > GENERICSTACK_USED(stackName)) { \
	if (GENERICSTACK_USED(stackName) <= 0) {			\
	  _GENERICSTACK_NA_MEMSET(stackName, 0, _genericStackSetByType_indexForSet - 1); \
	} else {							\
	  _GENERICSTACK_NA_MEMSET(stackName, GENERICSTACK_USED(stackName), _genericStackSetByType_indexForSet - 1); \
	}								\
      }									\
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    }									\
    if (! GENERICSTACK_ERROR(stackName)) {				\
      genericStackItem_t *_item = _GENERICSTACK_ITEM_ADDR(stackName, _genericStackSetByType_indexForSet); \
      _item->type = itemType;						\
      _item->u.dst = (varType) var;					\
    }									\
  } while (0)

/* It appears that come compilers (like cl) does not like some casts */
#define _GENERICSTACK_SET_BY_TYPE_NOCAST(stackName, var, itemType, dst, index) do { \
    int _genericStackSetByType_indexForSet = index;			\
    int _genericStackSetByType_wantedLength = _genericStackSetByType_indexForSet + 1; \
									\
    if (_genericStackSetByType_wantedLength > GENERICSTACK_LENGTH(stackName)) { \
                                                                        \
      _GENERICSTACK_EXTEND(stackName, _genericStackSetByType_wantedLength); \
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    } else if (_genericStackSetByType_wantedLength > GENERICSTACK_USED(stackName)) { \
									\
      if (_genericStackSetByType_indexForSet > GENERICSTACK_USED(stackName)) { \
	if (GENERICSTACK_USED(stackName) <= 0) {			\
	  _GENERICSTACK_NA_MEMSET(stackName, 0, _genericStackSetByType_indexForSet - 1); \
	} else {							\
	  _GENERICSTACK_NA_MEMSET(stackName, GENERICSTACK_USED(stackName), _genericStackSetByType_indexForSet - 1); \
	}								\
      }									\
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    }									\
    if (! GENERICSTACK_ERROR(stackName)) {				\
      genericStackItem_t *_item = _GENERICSTACK_ITEM_ADDR(stackName, _genericStackSetByType_indexForSet); \
      _item->type = itemType;						\
      _item->u.dst = var;						\
    }									\
  } while (0)

#define GENERICSTACK_SET_CHAR(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), char,   (var), GENERICSTACKITEMTYPE_CHAR, c, (index))
#define GENERICSTACK_SET_SHORT(stackName, var, index)  _GENERICSTACK_SET_BY_TYPE((stackName), short,  (var), GENERICSTACKITEMTYPE_SHORT, s, (index))
#define GENERICSTACK_SET_INT(stackName, var, index)    _GENERICSTACK_SET_BY_TYPE((stackName), int,    (var), GENERICSTACKITEMTYPE_INT, i, (index))
#define GENERICSTACK_SET_LONG(stackName, var, index)   _GENERICSTACK_SET_BY_TYPE((stackName), long,   (var), GENERICSTACKITEMTYPE_LONG, l, (index))
#define GENERICSTACK_SET_LONG_DOUBLE(stackName, var, index)   _GENERICSTACK_SET_BY_TYPE((stackName), long double,   (var), GENERICSTACKITEMTYPE_LONG, ld, (index))
#define GENERICSTACK_SET_FLOAT(stackName, var, index)  _GENERICSTACK_SET_BY_TYPE((stackName), float,  (var), GENERICSTACKITEMTYPE_FLOAT, f, (index))
#define GENERICSTACK_SET_DOUBLE(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), double, (var), GENERICSTACKITEMTYPE_DOUBLE, d, (index))
#define GENERICSTACK_SET_PTR(stackName, var, index)    _GENERICSTACK_SET_BY_TYPE((stackName), void *, (var), GENERICSTACKITEMTYPE_PTR, p, (index))
#define GENERICSTACK_SET_ARRAY(stackName, var, index)  _GENERICSTACK_SET_BY_TYPE_NOCAST((stackName), (var), GENERICSTACKITEMTYPE_ARRAY, a, (index))
#define GENERICSTACK_SET_ARRAYP(stackName, var, index)  _GENERICSTACK_SET_BY_TYPE_NOCAST((stackName), *(var), GENERICSTACKITEMTYPE_ARRAY, a, (index))
#if GENERICSTACK_HAVE_LONG_LONG > 0
#define GENERICSTACK_SET_LONG_LONG(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), long long, (var), GENERICSTACKITEMTYPE_LONG_LONG, ll, (index))
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#define GENERICSTACK_SET__BOOL(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), _Bool, (var), GENERICSTACKITEMTYPE_LONG_LONG, b, (index))
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#define GENERICSTACK_SET_FLOAT__COMPLEX(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), float _Complex, (var), GENERICSTACKITEMTYPE_LONG_LONG, fc, (index))
#define GENERICSTACK_SET_DOUBLE__COMPLEX(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), double _Complex, (var), GENERICSTACKITEMTYPE_LONG_LONG, dc, (index))
#define GENERICSTACK_SET_LONG_DOUBLE__COMPLEX(stackName, var, index) _GENERICSTACK_SET_BY_TYPE((stackName), long double _Complex, (var), GENERICSTACKITEMTYPE_LONG_LONG, ldc, (index))
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#define GENERICSTACK_SET_CUSTOM(stackName, var, index) _GENERICSTACK_SET_BY_TYPE_NOCAST((stackName), (var), GENERICSTACKITEMTYPE_CUSTOM, custom, (index))
#define GENERICSTACK_SET_CUSTOMP(stackName, var, index) _GENERICSTACK_SET_BY_TYPE_NOCAST((stackName), *(var), GENERICSTACKITEMTYPE_CUSTOM, custom, (index))
#endif

/* Special case for NA: there is not associated data */
#define GENERICSTACK_SET_NA(stackName, index) do {			\
    int _genericStackSetByType_indexForSet = index;			\
    int _genericStackSetByType_wantedLength = _genericStackSetByType_indexForSet + 1; \
									\
    if (_genericStackSetByType_wantedLength > GENERICSTACK_LENGTH(stackName)) { \
                                                                        \
      _GENERICSTACK_EXTEND(stackName, _genericStackSetByType_wantedLength); \
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    } else if (_genericStackSetByType_wantedLength > GENERICSTACK_USED(stackName)) { \
									\
      if (_genericStackSetByType_indexForSet > GENERICSTACK_USED(stackName)) { \
	if (GENERICSTACK_USED(stackName) <= 0) {			\
	  _GENERICSTACK_NA_MEMSET(stackName, 0, _genericStackSetByType_indexForSet - 1); \
	} else {							\
	  _GENERICSTACK_NA_MEMSET(stackName, GENERICSTACK_USED(stackName), _genericStackSetByType_indexForSet - 1); \
	}								\
      }									\
      GENERICSTACK_USED(stackName) = _genericStackSetByType_wantedLength; \
									\
    }									\
    if (! GENERICSTACK_ERROR(stackName)) {				\
      _GENERICSTACK_ITEM_DST_SET(stackName, _genericStackSetByType_indexForSet, type, GENERICSTACKITEMTYPE_NA); \
    }									\
  } while (0)

/* ====================================================================== */
/* Internal reduce of size before a GET that decrements stackName->use.   */
/* It is used with the GET interface, so have to fit in a single line     */
/* ====================================================================== */
#define _GENERICSTACK_REDUCE_LENGTH(stackName)				\
  (stackName->used > GENERICSTACK_DEFAULT_LENGTH) ?			\
  (									\
   ((stackName->used - GENERICSTACK_DEFAULT_LENGTH) <= (stackName->tmpSize = (stackName->heapLength / 2))) ? \
   (									\
    ((stackName->tmpItems = (genericStackItem_t *) realloc(stackName->heapItems, stackName->tmpSize * sizeof(genericStackItem_t))) != NULL) ? \
    (									\
     (void)(stackName->heapItems = stackName->tmpItems, stackName->heapLength = stackName->tmpSize) \
									) \
    :									\
    (void)0								\
									) \
   :									\
   (void)0								\
									) \
  :									\
  (void)(								\
   (stackName->heapItems != NULL) ? free(stackName->heapItems) : (void)0, stackName->heapItems = NULL, stackName->heapLength = 0 \
   )

/* ====================================================================== */
/* GET interface                                                          */
/* Last executed statement in the () is its return value                  */
/* ====================================================================== */
#define GENERICSTACK_GET_CHAR(stackName, index)   _GENERICSTACK_ITEM_DST((stackName), (index), u.c)
#define GENERICSTACK_GET_SHORT(stackName, index)  _GENERICSTACK_ITEM_DST((stackName), (index), u.s)
#define GENERICSTACK_GET_INT(stackName, index)    _GENERICSTACK_ITEM_DST((stackName), (index), u.i)
#define GENERICSTACK_GET_LONG(stackName, index)   _GENERICSTACK_ITEM_DST((stackName), (index), u.l)
#define GENERICSTACK_GET_LONG_DOUBLE(stackName, index)   _GENERICSTACK_ITEM_DST((stackName), (index), u.ld)
#define GENERICSTACK_GET_FLOAT(stackName, index)  _GENERICSTACK_ITEM_DST((stackName), (index), u.f)
#define GENERICSTACK_GET_DOUBLE(stackName, index) _GENERICSTACK_ITEM_DST((stackName), (index), u.d)
#define GENERICSTACK_GET_PTR(stackName, index)    _GENERICSTACK_ITEM_DST((stackName), (index), u.p)
#define GENERICSTACK_GET_ARRAY(stackName, index)  _GENERICSTACK_ITEM_DST((stackName), (index), u.a)
#define GENERICSTACK_GET_ARRAYP(stackName, index) _GENERICSTACK_ITEM_DST_ADDR((stackName), (index), u.a)
#if GENERICSTACK_HAVE_LONG_LONG > 0
#define GENERICSTACK_GET_LONG_LONG(stackName, index) _GENERICSTACK_ITEM_DST((stackName), (index), u.ll)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#define GENERICSTACK_GET__BOOL(stackName, index)  _GENERICSTACK_ITEM_DST((stackName), (index), u.b)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#define GENERICSTACK_GET_FLOAT__COMPLEX(stackName, index)       _GENERICSTACK_ITEM_DST((stackName), (index), u.fc)
#define GENERICSTACK_GET_DOUBLE__COMPLEX(stackName, index)      _GENERICSTACK_ITEM_DST((stackName), (index), u.dc)
#define GENERICSTACK_GET_LONG_DOUBLE__COMPLEX(stackName, index) _GENERICSTACK_ITEM_DST((stackName), (index), u.ldc)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#define GENERICSTACK_GET_CUSTOM(stackName, index)  _GENERICSTACK_ITEM_DST((stackName), (index), u.custom)
#define GENERICSTACK_GET_CUSTOMP(stackName, index)  _GENERICSTACK_ITEM_DST_ADDR((stackName), (index), u.custom)
#endif
/* Per def N/A value is undefined - we just have to make */
/* sure index is processed (c.f. POP operations)         */
#define GENERICSTACK_GET_NA(stackName, index) index

/* ====================================================================== */
/* PUSH interface: built on top of SET                                    */
/* ====================================================================== */
#define GENERICSTACK_PUSH_CHAR(stackName, var)   GENERICSTACK_SET_CHAR((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_SHORT(stackName, var)  GENERICSTACK_SET_SHORT((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_INT(stackName, var)    GENERICSTACK_SET_INT((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_LONG(stackName, var)   GENERICSTACK_SET_LONG((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_LONG_DOUBLE(stackName, var)   GENERICSTACK_SET_LONG_DOUBLE((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_FLOAT(stackName, var)  GENERICSTACK_SET_FLOAT((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_DOUBLE(stackName, var) GENERICSTACK_SET_DOUBLE((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_PTR(stackName, var)    GENERICSTACK_SET_PTR((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_ARRAY(stackName, var)  GENERICSTACK_SET_ARRAY((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_ARRAYP(stackName, var) GENERICSTACK_SET_ARRAYP((stackName), (var), (stackName)->used)
#if GENERICSTACK_HAVE_LONG_LONG > 0
#define GENERICSTACK_PUSH_LONG_LONG(stackName, var) GENERICSTACK_SET_LONG_LONG((stackName), (var), (stackName)->used)
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#define GENERICSTACK_PUSH__BOOL(stackName, var) GENERICSTACK_SET__BOOL((stackName), (var), (stackName)->used)
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#define GENERICSTACK_PUSH_FLOAT__COMPLEX(stackName, var) GENERICSTACK_SET_FLOAT__COMPLEX((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_DOUBLE__COMPLEX(stackName, var) GENERICSTACK_SET_DOUBLE__COMPLEX((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_LONG_DOUBLE__COMPLEX(stackName, var) GENERICSTACK_SET_LONG_DOUBLE__COMPLEX((stackName), (var), (stackName)->used)
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#define GENERICSTACK_PUSH_CUSTOM(stackName, var) GENERICSTACK_SET_CUSTOM((stackName), (var), (stackName)->used)
#define GENERICSTACK_PUSH_CUSTOMP(stackName, var) GENERICSTACK_SET_CUSTOMP((stackName), (var), (stackName)->used)
#endif
#define GENERICSTACK_PUSH_NA(stackName) GENERICSTACK_SET_NA((stackName), (stackName)->used)

/* ====================================================================== */
/* POP interface: built on top GET                                        */
/* ====================================================================== */
#define GENERICSTACK_POP_CHAR(stackName)   (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_CHAR((stackName),   --(stackName)->used))
#define GENERICSTACK_POP_SHORT(stackName)  (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_SHORT((stackName),  --(stackName)->used))
#define GENERICSTACK_POP_INT(stackName)    (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_INT((stackName),    --(stackName)->used))
#define GENERICSTACK_POP_LONG(stackName)   (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_LONG((stackName),   --(stackName)->used))
#define GENERICSTACK_POP_LONG_DOUBLE(stackName)   (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_LONG_DOUBLE((stackName),   --(stackName)->used))
#define GENERICSTACK_POP_FLOAT(stackName)  (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_FLOAT((stackName),  --(stackName)->used))
#define GENERICSTACK_POP_DOUBLE(stackName) (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_DOUBLE((stackName), --(stackName)->used))
#define GENERICSTACK_POP_PTR(stackName)    (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_PTR((stackName),    --(stackName)->used))
#define GENERICSTACK_POP_ARRAY(stackName)  (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_ARRAY((stackName),  --(stackName)->used))
#if GENERICSTACK_HAVE_LONG_LONG > 0
#define GENERICSTACK_POP_LONG_LONG(stackName)    (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_LONG_LONG((stackName), --(stackName)->used))
#endif
#if GENERICSTACK_HAVE__BOOL > 0
#define GENERICSTACK_POP__BOOL(stackName)  (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET__BOOL((stackName), --(stackName)->used))
#endif
#if GENERICSTACK_HAVE__COMPLEX > 0
#define GENERICSTACK_POP_FLOAT__COMPLEX(stackName)       (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_FLOAT__COMPLEX((stackName),       --(stackName)->used))
#define GENERICSTACK_POP_DOUBLE__COMPLEX(stackName)      (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_DOUBLE__COMPLEX((stackName),      --(stackName)->used))
#define GENERICSTACK_POP_LONG_DOUBLE__COMPLEX(stackName) (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_LONG_DOUBLE__COMPLEX((stackName), --(stackName)->used))
#endif
#if GENERICSTACK_HAVE_CUSTOM > 0
#define GENERICSTACK_POP_CUSTOM(stackName)  (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_CUSTOM((stackName), --(stackName)->used))
#endif
#define GENERICSTACK_POP_NA(stackName) (_GENERICSTACK_REDUCE_LENGTH((stackName)), GENERICSTACK_GET_NA((stackName), --(stackName)->used))

/* ====================================================================== */
/* Memory release                                                         */
/* We intentionnaly loop on size and not used.                            */
/* ====================================================================== */
#define GENERICSTACK_FREE(stackName) do {				\
    if ((stackName) != NULL) {						\
      if ((stackName)->heapItems != NULL) {				\
        free((stackName)->heapItems);					\
      }									\
      free((stackName));						\
      (stackName) = NULL;						\
    }									\
  } while (0)

#define GENERICSTACK_RESET(stackName) do {				\
    if ((stackName) != NULL) {						\
      if ((stackName)->heapItems != NULL) {				\
        free((stackName)->heapItems);					\
        (stackName)->heapItems = NULL;					\
      }									\
      (stackName)->heapLength = 0;					\
      (stackName)->used = 0;						\
    }									\
  } while (0)

/* ====================================================================== */
/* In some rare occasions user might want to get the basic type           */
/* from an item type.                                                     */
/* ====================================================================== */
#define GENERICSTACKITEMTYPE(stackName, index) _GENERICSTACK_ITEM((stackName), (index)).type

#define GENERICSTACKITEMTYPE2TYPE_CHAR   char
#define GENERICSTACKITEMTYPE2TYPE_SHORT  short
#define GENERICSTACKITEMTYPE2TYPE_INT    int
#define GENERICSTACKITEMTYPE2TYPE_LONG   long
#define GENERICSTACKITEMTYPE2TYPE_LONG_DOUBLE   long double
#define GENERICSTACKITEMTYPE2TYPE_FLOAT  float
#define GENERICSTACKITEMTYPE2TYPE_DOUBLE double
#define GENERICSTACKITEMTYPE2TYPE_PTR    void *
#define GENERICSTACKITEMTYPE2TYPE_ARRAY  genericStackItemTypeArray_t
#define GENERICSTACKITEMTYPE2TYPE_ARRAYP  genericStackItemTypeArray_t *
#define GENERICSTACK_ARRAY_PTR(a) (a).p
#define GENERICSTACK_ARRAYP_PTR(a) (a)->p
#define GENERICSTACK_ARRAY_LENGTH(a) (a).lengthl
#define GENERICSTACK_ARRAYP_LENGTH(a) (a)->lengthl
#if GENERICSTACK_HAVE_LONG_LONG
  #define GENERICSTACKITEMTYPE2TYPE_LONG_LONG long long
#endif
#if GENERICSTACK_HAVE__BOOL
  #define GENERICSTACKITEMTYPE2TYPE__BOOL _Bool
#endif
#if GENERICSTACK_HAVE__COMPLEX
  #define GENERICSTACKITEMTYPE2TYPE_FLOAT__COMPLEX       float _Complex
  #define GENERICSTACKITEMTYPE2TYPE_DOUBLE__COMPLEX      double _Complex
  #define GENERICSTACKITEMTYPE2TYPE_LONG_DOUBLE__COMPLEX long double _Complex
#endif
#if GENERICSTACK_HAVE_CUSTOM
  #define GENERICSTACKITEMTYPE2TYPE_CUSTOM GENERICSTACK_CUSTOM
  #define GENERICSTACKITEMTYPE2TYPE_CUSTOMP GENERICSTACK_CUSTOM *
#endif

/* ====================================================================== */
/* Switches two entries                                                   */
/* We support a "negative index", which mean start by far from the end.   */
/* ====================================================================== */
#define GENERICSTACK_SWITCH(stackName, i1, i2) do {                     \
    int _genericStackSwitch_index1 = (int) (i1);                        \
    int _genericStackSwitch_index2 = (int) (i2);                        \
                                                                        \
    if (_genericStackSwitch_index1 < 0) {                               \
      _genericStackSwitch_index1 = (stackName)->used + _genericStackSwitch_index1; \
    }                                                                   \
    if (_genericStackSwitch_index2 < 0) {                               \
      _genericStackSwitch_index2 = (stackName)->used + _genericStackSwitch_index2; \
    }                                                                   \
                                                                        \
    if ((_genericStackSwitch_index1 < 0) || ((_genericStackSwitch_index1) >= (stackName)->used) || \
        (_genericStackSwitch_index2 < 0) || ((_genericStackSwitch_index2) >= (stackName)->used)) { \
      (stackName)->error = 1;                                             \
    } else if (_genericStackSwitch_index1 != _genericStackSwitch_index2) { \
      genericStackItem_t _item = _GENERICSTACK_ITEM((stackName), _genericStackSwitch_index1); \
      memcpy(_GENERICSTACK_ITEM_ADDR((stackName), _genericStackSwitch_index1), _GENERICSTACK_ITEM_ADDR((stackName), _genericStackSwitch_index2),  sizeof(genericStackItem_t)); \
      memcpy(_GENERICSTACK_ITEM_ADDR((stackName), _genericStackSwitch_index2), &_item,  sizeof(genericStackItem_t)); \
    }                                                                   \
  } while (0)

/* ====================================================================== */
/* More easy macros                                                       */
/* ====================================================================== */
#define GENERICSTACK_EXISTS(stackName, i) (((stackName) != NULL) && ((stackName)->used > (i)))
#define GENERICSTACK_IS_NA(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_NA))
#define GENERICSTACK_IS_CHAR(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_CHAR))
#define GENERICSTACK_IS_SHORT(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_SHORT))
#define GENERICSTACK_IS_INT(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_INT))
#define GENERICSTACK_IS_LONG(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_LONG))
#define GENERICSTACK_IS_LONG_DOUBLE(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_LONG_DOUBLE))
#define GENERICSTACK_IS_FLOAT(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_FLOAT))
#define GENERICSTACK_IS_DOUBLE(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_DOUBLE))
#define GENERICSTACK_IS_PTR(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_PTR))
#define GENERICSTACK_IS_ARRAY(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_ARRAY))
#if GENERICSTACK_HAVE_LONG_LONG
#define GENERICSTACK_IS_LONG_LONG(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_LONG_LONG))
#endif
#if GENERICSTACK_HAVE__BOOL
#define GENERICSTACK_IS__BOOL(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE__BOOL))
#endif
#if GENERICSTACK_HAVE__COMPLEX
#define GENERICSTACK_IS_FLOAT__COMPLEX(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_FLOAT__COMPLEX))
#define GENERICSTACK_IS_DOUBLE__COMPLEX(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_DOUBLE__COMPLEX))
#define GENERICSTACK_IS_LONG_DOUBLE__COMPLEX(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_LONG_DOUBLE__COMPLEX))
#endif
#if GENERICSTACK_HAVE_CUSTOM
#define GENERICSTACK_IS_CUSTOM(stackName, i) (GENERICSTACK_EXISTS(stackName, i) && (GENERICSTACKITEMTYPE((stackName), (i)) == GENERICSTACKITEMTYPE_CUSTOM))
#endif

/* ====================================================================== */
/* Dump macro for development purpose. Fixed to stderr.                   */
/* ====================================================================== */
#if GENERICSTACK_HAVE_CUSTOM
#define _GENERICSTACK_DUMP_CASE_CUSTOM(stackName,indice) case GENERICSTACKITEMTYPE_CUSTOM: fprintf(stderr, "Element[%3d/%3d] type     : CUSTOM\n", indice, GENERICSTACK_USED(stackName)); break;
#else
#define _GENERICSTACK_DUMP_CASE_CUSTOM(stackName,indice)
#endif
#define GENERICSTACK_DUMP(stackName) do {				\
    int _i_for_dump;							\
    fprintf(stderr, "GENERIC STACK DUMP\n");				\
    fprintf(stderr, "------------------\n");				\
    fprintf(stderr, "Initial available Length  : %d\n", GENERICSTACK_INITIAL_LENGTH(stackName)); \
    fprintf(stderr, "Heap available Length     : %d\n", GENERICSTACK_HEAP_LENGTH(stackName)); \
    fprintf(stderr, "Total available Length    : %d\n", GENERICSTACK_LENGTH(stackName)); \
    fprintf(stderr, "Usage:                    : %d\n", GENERICSTACK_USED(stackName)); \
    for (_i_for_dump = 0; _i_for_dump < GENERICSTACK_USED(stackName); _i_for_dump++) { \
      switch(GENERICSTACKITEMTYPE(stackName, _i_for_dump)) {		\
      case GENERICSTACKITEMTYPE_NA:					\
	fprintf(stderr, "Element[%3d/%3d] type     : NA\n", _i_for_dump, GENERICSTACK_USED(stackName));	\
	break;								\
      case GENERICSTACKITEMTYPE_CHAR:					\
	fprintf(stderr, "Element[%3d/%3d] type     : CHAR\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_SHORT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : SHORT\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_INT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : INT\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_LONG:					\
	fprintf(stderr, "Element[%3d/%3d] type     : LONG\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_FLOAT:					\
	fprintf(stderr, "Element[%3d/%3d] type     : FLOAT\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_DOUBLE:					\
	fprintf(stderr, "Element[%3d/%3d] type     : DOUBLE\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_PTR:					\
	fprintf(stderr, "Element[%3d/%3d] type     : PTR\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_ARRAY:					\
	fprintf(stderr, "Element[%3d/%3d] type     : ARRAY\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      case GENERICSTACKITEMTYPE_LONG_DOUBLE:                            \
	fprintf(stderr, "Element[%3d/%3d] type     : LONG DOUBLE\n", _i_for_dump, GENERICSTACK_USED(stackName)); \
	break;								\
      default:								\
	fprintf(stderr, "Element[%3d/%3d] type     : %d\n", _i_for_dump, GENERICSTACK_USED(stackName), GENERICSTACKITEMTYPE(stackName, _i_for_dump)); \
	break;								\
        _GENERICSTACK_DUMP_CASE_CUSTOM(stackName,_i_for_dump)           \
      }									\
    }									\
 } while (0)
     
#endif /* GENERICSTACK_H */
