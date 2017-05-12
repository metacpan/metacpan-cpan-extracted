#ifndef GENERICSPARSEARRAY_H
#define GENERICSPARSEARRAY_H

/* Our sparse array is built on top of genericHash */

#include <stdlib.h>
#include <genericHash.h>

typedef genericHash_t genericSparseArray_t;

#define GENERICSPARSEARRAY_NEW(sparseArrayName, keyIndFunctionp) \
  GENERICHASH_NEW(sparseArrayName, keyIndFunctionp)

#define GENERICSPARSEARRAY_NEW_ALL(sparseArrayName, keyIndFunctionp, valCopyFunctionp, valFreeFunctionp, wantedSize, wantedSubSize) \
  GENERICHASH_NEW_ALL(sparseArrayName, keyIndFunctionp, NULL, NULL, NULL, valCopyFunctionp, valFreeFunctionp, wantedSize, wantedSubSize)

#define GENERICSPARSEARRAY_INIT(sparseArrayName, keyIndFunctionp) \
  GENERICHASH_INIT(sparseArrayName, keyIndFunctionp)

#define GENERICSPARSEARRAY_INIT_ALL(sparseArrayName, keyIndFunctionp, valCopyFunctionp, valFreeFunctionp, wantedSize, wantedSubSize) \
  GENERICHASH_INIT_ALL(sparseArrayName, keyIndFunctionp, NULL, NULL, NULL, valCopyFunctionp, valFreeFunctionp, wantedSize, wantedSubSize)

#define GENERICSPARSEARRAY_VALCOPYFUNCTION(sparseArrayName) \
  GENERICHASH_VALCOPYFUNCTION(sparseArrayName)
  
#define GENERICSPARSEARRAY_VALFREEFUNCTION(sparseArrayName) \
  GENERICHASH_VALFREEFUNCTION(sparseArrayName)

#define GENERICSPARSEARRAY_SET(sparseArrayName, userDatavp, indice, valType, valVal) do { \
    int keyVal = indice;						\
    GENERICHASH_SET(sparseArrayName, userDatavp, INT, keyVal, valType, valVal);	\
  } while (0)

#define GENERICSPARSEARRAY_FIND(sparseArrayName, userDatavp, indice, valType, valValp, findResult) do {	\
    int keyVal = indice;						\
    GENERICHASH_FIND(sparseArrayName, userDatavp, INT, keyVal, valType, valValp, findResult); \
  } while (0)

#define GENERICSPARSEARRAY_REMOVE(sparseArrayName, userDatavp, indice, valType, valValp, findResult) do { \
    int keyVal = indice;						\
    GENERICHASH_REMOVE(sparseArrayName, userDatavp, INT, keyVal, valType, valValp, findResult);	\
  } while (0)

#define GENERICSPARSEARRAY_FREE(sparseArrayName, userDatavp) \
  GENERICHASH_FREE(sparseArrayName, userDatavp)
  
#define GENERICSPARSEARRAY_USED(sparseArrayName) \
  GENERICHASH_USED(sparseArrayName)
  
#define GENERICSPARSEARRAY_RESET(sparseArrayName, userDatavp) \
  GENERICHASH_RESET(sparseArrayName, userDatavp)
  
#define GENERICSPARSEARRAY_RELAX(sparseArrayName, userDatavp) \
  GENERICHASH_RELAX(sparseArrayName, userDatavp)
  
#define GENERICSPARSEARRAY_ERROR(sparseArrayName) \
  GENERICHASH_ERROR(sparseArrayName)

#endif /* GENERICSPARSEARRAY_H */
