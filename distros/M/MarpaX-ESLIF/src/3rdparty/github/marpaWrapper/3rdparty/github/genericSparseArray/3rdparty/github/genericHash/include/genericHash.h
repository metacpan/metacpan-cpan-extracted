#ifndef GENERICHASH_H
#define GENERICHASH_H

#include <stdio.h>
#include <errno.h>
#include <genericStack.h>
#include <genericHash/cloak.h>

/* A hash is nothing else but a generic stack of generic stacks */

typedef int    (*genericHashKeyIndFunction_t)(void *userDatavp, genericStackItemType_t itemType, void **pp);
typedef short  (*genericHashKeyCmpFunction_t)(void *userDatavp, void **pp1, void **pp2);
typedef void  *(*genericHashKeyCopyFunction_t)(void *userDatavp, void **pp);
typedef void   (*genericHashKeyFreeFunction_t)(void *userDatavp, void **pp);
typedef void  *(*genericHashValCopyFunction_t)(void *userDatavp, void **pp);
typedef void   (*genericHashValFreeFunction_t)(void *userDatavp, void **pp);

typedef struct genericHash {
  int                          wantedSubSize;
  genericHashKeyIndFunction_t  keyIndFunctionp;
  genericHashKeyCmpFunction_t  keyCmpFunctionp;
  genericHashKeyCopyFunction_t keyCopyFunctionp;
  genericHashKeyFreeFunction_t keyFreeFunctionp;
  genericHashValCopyFunction_t valCopyFunctionp;
  genericHashValFreeFunction_t valFreeFunctionp;
  /* keyStackp and valStackp leave in parallel */
  genericStack_t               keyStack;
  genericStack_t              *keyStackp;
  genericStack_t               valStack;
  genericStack_t              *valStackp;
  int                          used;
  short                        error;
} genericHash_t;


/* ====================================================================== */
/* Error detection                                                        */
/* ====================================================================== */
#define GENERICHASH_ERROR(hashName) ((hashName == NULL) || (hashName->error != 0))

/* ====================================================================== */
/* For getters and setters                                                */
/* ====================================================================== */
#define GENERICHASH_KEYCMPFUNCTION(hashName) hashName->keyCmpFunctionp
#define GENERICHASH_KEYCOPYFUNCTION(hashName) hashName->keyCopyFunctionp
#define GENERICHASH_KEYFREEFUNCTION(hashName) hashName->keyFreeFunctionp
#define GENERICHASH_VALCOPYFUNCTION(hashName) hashName->valCopyFunctionp
#define GENERICHASH_VALFREEFUNCTION(hashName) hashName->valFreeFunctionp

/* ====================================================================== */
/* Initialization                                                         */
/*                                                                        */
/* wantedSize is an estimated number of rows in the hash                  */
/* index and comparison function pointers are mandatory.                  */
/* thisWantedSize is an estimated number of rows in every hash's row      */
/* ====================================================================== */
#define GENERICHASH_NEW_ALL(hashName, thisKeyIndFunctionp, thisKeyCmpFunctionp, thisKeyCopyFunctionp, thisKeyFreeFunctionp, thisValCopyFunctionp, thisValFreeFunctionp, wantedSize, thisWantedSubSize) do { \
    genericHashKeyIndFunction_t  _keyIndFunctionp  = (genericHashKeyIndFunction_t)  (thisKeyIndFunctionp); \
    genericHashKeyCmpFunction_t  _keyCmpFunctionp  = (genericHashKeyCmpFunction_t)  (thisKeyCmpFunctionp); \
    genericHashKeyCopyFunction_t _keyCopyFunctionp = (genericHashKeyCopyFunction_t) (thisKeyCopyFunctionp); \
    genericHashKeyFreeFunction_t _keyFreeFunctionp = (genericHashKeyFreeFunction_t) (thisKeyFreeFunctionp); \
    genericHashValCopyFunction_t _valCopyFunctionp = (genericHashValCopyFunction_t) (thisValCopyFunctionp); \
    genericHashValFreeFunction_t _valFreeFunctionp = (genericHashValFreeFunction_t) (thisValFreeFunctionp); \
    									\
    if (_keyIndFunctionp == NULL) {                                     \
      hashName = NULL;                                                  \
    } else {                                                            \
      hashName = malloc(sizeof(genericHash_t));				\
      if (hashName != NULL) {						\
        hashName->wantedSubSize    = (thisWantedSubSize);               \
        hashName->keyIndFunctionp  = _keyIndFunctionp;			\
        hashName->keyCmpFunctionp  = _keyCmpFunctionp;			\
        hashName->keyCopyFunctionp = _keyCopyFunctionp;			\
        hashName->keyFreeFunctionp = _keyFreeFunctionp;			\
        hashName->valCopyFunctionp = _valCopyFunctionp;			\
        hashName->valFreeFunctionp = _valFreeFunctionp;			\
        hashName->error = 0;						\
        hashName->used = 0;						\
									\
        hashName->keyStackp = &(hashName->keyStack);			\
        GENERICSTACK_INIT_SIZED(hashName->keyStackp, wantedSize);	\
        if (GENERICSTACK_ERROR(hashName->keyStackp)) {			\
          free(hashName);                                               \
          hashName = NULL;						\
        } else {							\
	  hashName->valStackp = &(hashName->valStack);			\
	  GENERICSTACK_INIT_SIZED(hashName->valStackp, wantedSize);	\
	  if (GENERICSTACK_ERROR(hashName->valStackp)) {		\
	    GENERICSTACK_RESET(hashName->keyStackp);			\
	    free(hashName);						\
	    hashName = NULL;						\
	  }								\
        }                                                               \
      }									\
    }                                                                   \
  } while (0)

#define GENERICHASH_INIT_ALL(hashName, thisKeyIndFunctionp, thisKeyCmpFunctionp, thisKeyCopyFunctionp, thisKeyFreeFunctionp, thisValCopyFunctionp, thisValFreeFunctionp, wantedSize, thisWantedSubSize) do { \
    genericHashKeyIndFunction_t  _keyIndFunctionp  = (genericHashKeyIndFunction_t)  (thisKeyIndFunctionp); \
    genericHashKeyCmpFunction_t  _keyCmpFunctionp  = (genericHashKeyCmpFunction_t)  (thisKeyCmpFunctionp); \
    genericHashKeyCopyFunction_t _keyCopyFunctionp = (genericHashKeyCopyFunction_t) (thisKeyCopyFunctionp); \
    genericHashKeyFreeFunction_t _keyFreeFunctionp = (genericHashKeyFreeFunction_t) (thisKeyFreeFunctionp); \
    genericHashValCopyFunction_t _valCopyFunctionp = (genericHashValCopyFunction_t) (thisValCopyFunctionp); \
    genericHashValFreeFunction_t _valFreeFunctionp = (genericHashValFreeFunction_t) (thisValFreeFunctionp); \
    									\
    hashName->error = 0;						\
    hashName->used = 0;							\
    									\
    if (_keyIndFunctionp == NULL) {                                     \
      hashName->error = 1;						\
    } else {                                                            \
      hashName->wantedSubSize    = (thisWantedSubSize);			\
      hashName->keyIndFunctionp  = _keyIndFunctionp;			\
      hashName->keyCmpFunctionp  = _keyCmpFunctionp;			\
      hashName->keyCopyFunctionp = _keyCopyFunctionp;			\
      hashName->keyFreeFunctionp = _keyFreeFunctionp;			\
      hashName->valCopyFunctionp = _valCopyFunctionp;			\
      hashName->valFreeFunctionp = _valFreeFunctionp;			\
									\
      hashName->keyStackp = &(hashName->keyStack);			\
      GENERICSTACK_INIT_SIZED(hashName->keyStackp, wantedSize);		\
      if (GENERICSTACK_ERROR(hashName->keyStackp)) {			\
	hashName->error = 1;						\
      } else {								\
        hashName->valStackp = &(hashName->valStack);			\
        GENERICSTACK_INIT_SIZED(hashName->valStackp, wantedSize);	\
        if (GENERICSTACK_ERROR(hashName->valStackp)) {			\
          GENERICSTACK_RESET(hashName->keyStackp);			\
	  hashName->error = 1;						\
        }                                                               \
      }									\
    }                                                                   \
  } while (0)

#define GENERICHASH_NEW(hashName, thisKeyIndFunctionp) GENERICHASH_NEW_ALL(hashName, thisKeyIndFunctionp, NULL, NULL, NULL, NULL, NULL, 0, 0)
#define GENERICHASH_INIT(hashName, thisKeyIndFunctionp) GENERICHASH_INIT_ALL(hashName, thisKeyIndFunctionp, NULL, NULL, NULL, NULL, NULL, 0, 0)

/* ====================================================================== */
/* Usage. Take care alos this is an lvalue, this must never be modified.  */
/* ====================================================================== */
#define GENERICHASH_USED(hashName) (hashName)->used

/* ====================================================================== */
/* Copy key/value to internal variables                                   */
/* ====================================================================== */
/* We use the cloak hacks to prevent unnecessary code generation */
#define GENERICHASH_COMPARE_PTR(x) x

#define _GENERICHASH_COPY(hashName, userDatavp, keyType, keyVal, keyValCopy, valType, valVal, valValCopy) do { \
									\
    GENERICHASH_IIF(GENERICHASH_EQUAL(keyType, PTR)) (                  \
      if (hashName->keyCopyFunctionp != NULL) {                         \
        GENERICSTACKITEMTYPE2TYPE_##keyType _keyValForCopy = (keyVal);  \
        GENERICSTACKITEMTYPE2TYPE_##keyType _p = hashName->keyCopyFunctionp((void *) userDatavp, &_keyValForCopy); \
        if ((_keyValForCopy != NULL) && (_p == NULL)) {			\
          hashName->error = 1;						\
        } else {                                                        \
          keyValCopy = _p;                                              \
        }                                                               \
      } else {								\
        keyValCopy = keyVal;						\
      }                                                                 \
      ,                                                                 \
      keyValCopy = keyVal;						\
    )                                                                   \
    GENERICHASH_IIF(GENERICHASH_EQUAL(valType, PTR)) (                  \
      if (hashName->valCopyFunctionp != NULL) {                         \
        GENERICSTACKITEMTYPE2TYPE_##valType _valValForCopy = (valVal);  \
        GENERICSTACKITEMTYPE2TYPE_##valType _p = hashName->valCopyFunctionp((void *) userDatavp, &_valValForCopy); \
        if ((_valValForCopy != NULL) && (_p == NULL)) {                 \
          hashName->error = 1;						\
        } else {                                                        \
          valValCopy = _p;                                              \
        }                                                               \
      } else {								\
        valValCopy = valVal;						\
      }                                                                 \
      ,                                                                 \
      valValCopy = valVal;						\
    )                                                                   \
  } while (0)

/* ====================================================================== */
/* Push internal variables in the hash                                    */
/* ====================================================================== */
#define _GENERICHASH_PUSH(hashName, userDatavp, keyType, keyVal, valType, valVal, subKeyStackp, subValStackp) do { \
    GENERICSTACKITEMTYPE2TYPE_##keyType _keyValCopy;			\
    GENERICSTACKITEMTYPE2TYPE_##valType _valValCopy;			\
									\
    _GENERICHASH_COPY(hashName, userDatavp, keyType, keyVal, _keyValCopy, valType, valVal, _valValCopy); \
    if (hashName->error == 0) {						\
      GENERICSTACK_PUSH_##keyType(subKeyStackp, _keyValCopy);		\
      GENERICSTACK_PUSH_##valType(subValStackp, _valValCopy);		\
      if (GENERICSTACK_ERROR(subKeyStackp) || GENERICSTACK_ERROR(subValStackp)) { \
	hashName->error = 1;						\
      } else {								\
	hashName->used++;						\
      }									\
    }									\
  } while (0)

/* ====================================================================== */
/* Set internal variables in the hash                                     */
/* ====================================================================== */
#define _GENERICHASH_SET(hashName, userDatavp, keyType, keyVal, valType, valVal, subKeyStackp, subValStackp, index) do { \
    GENERICSTACKITEMTYPE2TYPE_##keyType _keyValCopy;			\
    GENERICSTACKITEMTYPE2TYPE_##valType _valValCopy;			\
									\
    _GENERICHASH_COPY(hashName, userDatavp, keyType, keyVal, _keyValCopy, valType, valVal, _valValCopy); \
    if (hashName->error == 0) {						\
      GENERICSTACK_SET_##keyType(subKeyStackp, _keyValCopy, index);	\
      GENERICSTACK_SET_##valType(subValStackp, _valValCopy, index);	\
      if (GENERICSTACK_ERROR(subKeyStackp) || GENERICSTACK_ERROR(subValStackp)) { \
	hashName->error = 1;						\
      }									\
    }									\
  } while (0)

/* ====================================================================== */
/* Set external variables in the hash                                     */
/* ====================================================================== */
#define GENERICHASH_SET(hashName, userDatavp, keyType, keyVal, valType, valVal) do { \
    GENERICSTACKITEMTYPE2TYPE_##keyType _keyVal = (GENERICSTACKITEMTYPE2TYPE_##keyType) (keyVal); \
    int _subStackIndex = hashName->keyIndFunctionp((void *) userDatavp, GENERICSTACKITEMTYPE_##keyType, (void **) &_keyVal); \
									\
    GENERICHASH_SET_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valVal, _subStackIndex); \
  } while (0)

#define GENERICHASH_SET_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valVal, subStackIndex) do { \
    GENERICSTACKITEMTYPE2TYPE_##keyType _keyVal = (GENERICSTACKITEMTYPE2TYPE_##keyType) (keyVal); \
    hashName->error = 0;						\
									\
    if (subStackIndex < 0 ) {                                           \
      errno = EINVAL;							\
      hashName->error = 1;						\
    } else {								\
      GENERICSTACKITEMTYPE2TYPE_##valType _valVal = (GENERICSTACKITEMTYPE2TYPE_##valType) (valVal); \
      if ((subStackIndex >= GENERICSTACK_USED(hashName->keyStackp)) || \
	  (subStackIndex >= GENERICSTACK_USED(hashName->valStackp)) ||	\
	  (GENERICSTACKITEMTYPE(hashName->keyStackp, subStackIndex) != GENERICSTACKITEMTYPE_PTR) || \
	  (GENERICSTACKITEMTYPE(hashName->valStackp, subStackIndex) != GENERICSTACKITEMTYPE_PTR)) { \
	genericStack_t *_subKeyStackp;					\
	genericStack_t *_subValStackp;					\
									\
	GENERICSTACK_NEW_SIZED(_subKeyStackp, hashName->wantedSubSize); \
	GENERICSTACK_NEW_SIZED(_subValStackp, hashName->wantedSubSize); \
	if (GENERICSTACK_ERROR(_subKeyStackp) || GENERICSTACK_ERROR(_subValStackp)) { \
	  GENERICSTACK_FREE(_subKeyStackp);				\
	  GENERICSTACK_FREE(_subValStackp);				\
	  hashName->error = 1;						\
	} else {							\
	  GENERICSTACK_SET_PTR(hashName->keyStackp, _subKeyStackp, subStackIndex); \
	  GENERICSTACK_SET_PTR(hashName->valStackp, _subValStackp, subStackIndex); \
	  if (GENERICSTACK_ERROR(hashName->keyStackp) || GENERICSTACK_ERROR(hashName->valStackp)) { \
	    GENERICSTACK_FREE(_subKeyStackp);				\
	    GENERICSTACK_FREE(_subValStackp);				\
	    GENERICSTACK_SET_NA(hashName->keyStackp, subStackIndex);	\
	    GENERICSTACK_SET_NA(hashName->valStackp, subStackIndex);	\
	    hashName->error = 1;					\
	  } else {							\
	    _GENERICHASH_PUSH(hashName, userDatavp, keyType, _keyVal, valType, _valVal, _subKeyStackp, _subValStackp); \
	  }								\
	}								\
      } else {								\
	genericStack_t *_subKeyStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->keyStackp, subStackIndex); \
	genericStack_t *_subValStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->valStackp, subStackIndex); \
	int             _subStackused = GENERICSTACK_USED(_subKeyStackp); \
	int             _i;						\
									\
	for (_i = 0; _i < _subStackused; _i++) {			\
	  GENERICSTACKITEMTYPE2TYPE_##keyType _gotKeyVal;		\
	  if ((GENERICSTACKITEMTYPE(_subKeyStackp, _i) != GENERICSTACKITEMTYPE_##keyType)) { \
	    continue;							\
	  }								\
									\
	  _gotKeyVal = GENERICSTACK_GET_##keyType(_subKeyStackp, _i);	\
          GENERICHASH_IIF(GENERICHASH_EQUAL(keyType, PTR)) (            \
            if (hashName->keyCmpFunctionp != NULL) {                    \
              if (! hashName->keyCmpFunctionp((void *) userDatavp, &_keyVal, &_gotKeyVal)) { \
                continue;                                               \
              }								\
            } else {							\
              if (_keyVal != _gotKeyVal) {				\
                continue;                                               \
              }								\
            }                                                           \
            ,                                                           \
	    if (_keyVal != _gotKeyVal) {				\
	      continue;							\
	    }								\
          )                                                             \
									\
          GENERICHASH_IIF(GENERICHASH_EQUAL(keyType, PTR)) (            \
            if ((_gotKeyVal != NULL) && (hashName->keyFreeFunctionp != NULL)) { \
              hashName->keyFreeFunctionp((void *) userDatavp, &_gotKeyVal); \
            }								\
            ,                                                           \
          )                                                             \
	  if ((GENERICSTACKITEMTYPE(_subValStackp, _i) == GENERICSTACKITEMTYPE_PTR)) { \
	    GENERICSTACKITEMTYPE2TYPE_PTR _gotValVal = GENERICSTACK_GET_PTR(_subValStackp, _i); \
	    if ((_gotValVal != NULL) && (hashName->valFreeFunctionp != NULL)) { \
	      hashName->valFreeFunctionp((void *) userDatavp, &_gotValVal); \
	    }								\
	  }								\
		    							\
	  _GENERICHASH_SET(hashName, userDatavp, keyType, _keyVal, valType, _valVal, _subKeyStackp, _subValStackp, _i); \
	  break;							\
	}								\
	if (_i >= _subStackused) {					\
	  _GENERICHASH_PUSH(hashName, userDatavp, keyType, _keyVal, valType, _valVal, _subKeyStackp, _subValStackp); \
	}								\
      }									\
    }									\
  } while (0)

/* ====================================================================== */
/* Find and eventually remove in the hash                                 */
/* ====================================================================== */
#define _GENERICHASH_FIND_REMOVE(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, remove) do { \
									\
    if (hashName->keyIndFunctionp == NULL) {				\
      errno = EINVAL;							\
      hashName->error = 1;						\
    } else {								\
      int _subStackIndex = hashName->keyIndFunctionp((void *) userDatavp, GENERICSTACKITEMTYPE_##keyType, (void **) &keyVal); \
      _GENERICHASH_FIND_REMOVE_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, _subStackIndex, remove); \
    }									\
  } while (0)

#define _GENERICHASH_FIND_REMOVE_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, _subStackIndex, remove) do { \
									\
    if (_subStackIndex < 0) {						\
      errno = EINVAL;							\
      hashName->error = 1;						\
    } else {								\
      findResult = 0;                                                   \
									\
      if ((_subStackIndex < GENERICSTACK_USED(hashName->keyStackp))	\
	  &&								\
	  (GENERICSTACKITEMTYPE(hashName->keyStackp, _subStackIndex) == GENERICSTACKITEMTYPE_PTR)) { \
	genericStack_t *_subKeyStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->keyStackp, _subStackIndex); \
	genericStack_t *_subValStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->valStackp, _subStackIndex); \
	int             _subStackused = GENERICSTACK_USED(_subKeyStackp); \
	int _i;								\
									\
	for (_i = 0; _i < _subStackused; _i++) {			\
	  GENERICSTACKITEMTYPE2TYPE_##keyType _gotKeyVal;		\
									\
	  if ((GENERICSTACKITEMTYPE(_subKeyStackp, _i) != GENERICSTACKITEMTYPE_##keyType)) { \
	    continue;							\
	  }								\
									\
	  _gotKeyVal = GENERICSTACK_GET_##keyType(_subKeyStackp, _i);	\
          GENERICHASH_IIF(GENERICHASH_EQUAL(keyType, PTR)) (            \
            if ((GENERICSTACKITEMTYPE_##keyType == GENERICSTACKITEMTYPE_PTR) && (hashName->keyCmpFunctionp != NULL)) { \
              if (! hashName->keyCmpFunctionp((void *) userDatavp, (void **) &keyVal, (void **) &_gotKeyVal)) { \
                continue;                                               \
              }								\
            } else {							\
              if (keyVal != _gotKeyVal) {                               \
                continue;                                               \
              }								\
            }                                                           \
            ,                                                           \
	    if (keyVal != _gotKeyVal) {					\
	      continue;							\
	    }								\
          )                                                             \
	  findResult = 1;						\
                                                                        \
	  if ((valValp) != NULL) {					\
	    GENERICSTACKITEMTYPE2TYPE_##valType *_valValp = (GENERICSTACKITEMTYPE2TYPE_##valType *) (valValp); \
	    *_valValp = GENERICSTACK_GET_##valType(_subValStackp, _i);	\
	  }								\
	  if (remove) {							\
            GENERICHASH_IIF(GENERICHASH_EQUAL(keyType, PTR)) (          \
	      if ((_gotKeyVal != NULL) && (hashName->keyFreeFunctionp != NULL)) { \
                hashName->keyFreeFunctionp((void *) userDatavp, &_gotKeyVal); \
              }								\
              ,                                                         \
            )                                                           \
	    GENERICSTACK_SET_NA(_subKeyStackp, _i);			\
	    GENERICSTACK_SWITCH(_subKeyStackp, _i, -1);			\
	    GENERICSTACK_POP_NA(_subKeyStackp);				\
									\
	    if ((valValp) == NULL) {					\
	      if ((GENERICSTACKITEMTYPE(_subValStackp, _i) == GENERICSTACKITEMTYPE_PTR) && (hashName->valFreeFunctionp == NULL)) { \
		GENERICSTACKITEMTYPE2TYPE_PTR _valVal = GENERICSTACK_GET_PTR(_subValStackp, _i); \
		if (_valVal != NULL) {					\
		  hashName->valFreeFunctionp((void *) userDatavp, &_valVal); \
		}							\
	      }								\
	    }								\
	    GENERICSTACK_SET_NA(_subValStackp, _i);			\
	    GENERICSTACK_SWITCH(_subValStackp, _i, -1);			\
	    GENERICSTACK_POP_NA(_subValStackp);				\
	    hashName->used--;						\
	  }								\
	  break;							\
        }								\
      }									\
    }									\
} while (0)

#define GENERICHASH_FIND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult)   _GENERICHASH_FIND_REMOVE(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, 0)
#define GENERICHASH_REMOVE(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult) _GENERICHASH_FIND_REMOVE(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, 1)

#define GENERICHASH_FIND_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, index) _GENERICHASH_FIND_REMOVE_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, index, 0)
#define GENERICHASH_REMOVE_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, index) _GENERICHASH_FIND_REMOVE_BY_IND(hashName, userDatavp, keyType, keyVal, valType, valValp, findResult, index, 1)

/* ====================================================================== */
/* Memory release                                                         */
/* ====================================================================== */
#define _GENERICHASH_INTERNAL_RESET(hashName, userDatavp, resetmode) do {	\
    int _usedl  = GENERICSTACK_USED(hashName->keyStackp);		\
    int _i;								\
    for (_i = 0; _i < _usedl; _i++) {					\
      if ((GENERICSTACKITEMTYPE(hashName->keyStackp, _i) == GENERICSTACKITEMTYPE_PTR) && \
	  (GENERICSTACKITEMTYPE(hashName->valStackp, _i) == GENERICSTACKITEMTYPE_PTR)) { \
	genericStack_t *_subKeyStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->keyStackp, _i); \
	genericStack_t *_subValStackp = (genericStack_t *) GENERICSTACK_GET_PTR(hashName->valStackp, _i); \
	int             _subStackused = GENERICSTACK_USED(_subKeyStackp); \
	int             _j;						\
                                                                        \
	for (_j = 0; _j < _subStackused; _j++) {			\
	  if ((GENERICSTACKITEMTYPE(_subKeyStackp, _j) == GENERICSTACKITEMTYPE_PTR) && (hashName->keyFreeFunctionp != NULL)) { \
	    GENERICSTACKITEMTYPE2TYPE_PTR _keyValp = GENERICSTACK_GET_PTR(_subKeyStackp, _j); \
	    if (_keyValp != NULL) {					\
	      hashName->keyFreeFunctionp(userDatavp, &_keyValp);        \
	    }								\
	  }								\
	  if ((GENERICSTACKITEMTYPE(_subValStackp, _j) == GENERICSTACKITEMTYPE_PTR) && (hashName->valFreeFunctionp != NULL)) { \
	    GENERICSTACKITEMTYPE2TYPE_PTR _valValp = GENERICSTACK_GET_PTR(_subValStackp, _j); \
	    if (_valValp != NULL) {					\
	      hashName->valFreeFunctionp(userDatavp, &_valValp);        \
	    }								\
	  }								\
	}								\
	GENERICSTACK_FREE(_subKeyStackp);				\
	GENERICSTACK_FREE(_subValStackp);				\
      }									\
    }									\
    if (resetmode) {							\
      GENERICSTACK_RESET(hashName->keyStackp);				\
      GENERICSTACK_RESET(hashName->valStackp);				\
    } else {								\
      GENERICSTACK_USED(hashName->keyStackp) = 0;			\
      GENERICSTACK_USED(hashName->valStackp) = 0;			\
    }									\
    									\
    hashName->error = 0;						\
    hashName->used = 0;							\
  } while (0)

#define GENERICHASH_RESET(hashName, userDatavp) _GENERICHASH_INTERNAL_RESET(hashName, userDatavp, 1)
#define GENERICHASH_RELAX(hashName, userDatavp) _GENERICHASH_INTERNAL_RESET(hashName, userDatavp, 0)

#define GENERICHASH_FREE(hashName, userDatavp) do {                     \
    if (hashName != NULL) {						\
      GENERICHASH_RESET(hashName, userDatavp);				\
      free(hashName);							\
      hashName = NULL;							\
    }									\
  } while (0)

#endif /* GENERICHASH_H */
