#ifndef GMEM_H_
#define GMEM_H_

/*
 * A set of macros / functions to allocate and release dynamic memory.
 *
 * When compiling with GMEM_CHECK defined, the macros keep track of all memory
 * allocation and deallocation, and a summary is printed out at the end; when
 * it is undefined, the macros are equivalent to raw calls to malloc / realloc
 * / free, thus incurring no runtime cost; additionally, in this case when
 * freeing, the freed variable is set to zero.
 *
 * Examples for calling the macros:
 *
 *   GMEM_NEW(header, Header*, sizeof(Header))
 *         => header = (Header*) malloc(sizeof(Header))
 *
 *   GMEM_REALLOC(data, Data*, 20, 30)
 *         => data = (Data*) realloc(data, 40), set last 10 elements to 0
 *
 *   GMEM_DEL(header, Header*, sizeof(Header))
 *         => free(header), header = 0
 *
 *   GMEM_NEWARR(data, Data*, 10, sizeof(Data))
 *         => data = (Data*) calloc(40, sizeof(Dasta))
 *
 *   GMEM_DELARR(data, Data*, 10, sizeof(Data))
 *         => free(data), data = 0
 */

#include <stdlib.h>
#include <string.h>

#define _GMEM_NEW(scalar, type, size) \
  do { \
    scalar = (type) malloc(size); \
  } while (0)
#define _GMEM_REALLOC(scalar, type, osize, nsize) \
  do { \
    scalar = (type) realloc(scalar, nsize); \
  } while (0)
#define _GMEM_DEL(scalar, type, size) \
  do { \
    free(scalar); \
    scalar = 0; \
  } while (0)

#if !defined(GMEM_CHECK) || GMEM_CHECK < 1

#define GMEM_NEW(scalar, type, size)             _GMEM_NEW(scalar, type, size)
#define GMEM_REALLOC(scalar, type, osize, nsize) _GMEM_REALLOC(scalar, type, osize, nsize)
#define GMEM_DEL(scalar, type, size)             _GMEM_DEL(scalar, type, size)

#define GMEM_NEWARR(array, type, count, size)  \
  do { \
    array = (type) calloc(count, size); \
  } while (0)
#define GMEM_DELARR(array, type, count, size) \
  do { \
    free(array); \
    array = 0; \
} while (0)

#define GMEM_NEWSTR(tgt, src, len, ret) \
  do { \
    tgt = 0; \
    if (!src) { \
      ret = 0; \
      break; \
    } \
    int l = len <= 0 ? strlen(src) + 1 : len; \
    _GMEM_NEW(tgt, char*, l); \
    memcpy(tgt, src, l); \
    ret = l; \
  } while (0)
#define GMEM_DELSTR(str, len) \
  do { \
    _GMEM_DEL(str, char*, len); \
  } while (0)

#else

#define GMEM_NEW(scalar, type, size) \
  do { \
    _GMEM_NEW(scalar, type, size); \
    gmem_new_called(__FILE__, __LINE__, scalar, 1, size); \
  } while (0)
#define GMEM_REALLOC(scalar, type, osize, nsize) \
  do { \
    gmem_del_called(__FILE__, __LINE__, scalar, 1, osize); \
    _GMEM_REALLOC(scalar, type, osize, nsize); \
    gmem_new_called(__FILE__, __LINE__, scalar, 1, nsize); \
  } while (0)
#define GMEM_DEL(scalar, type, size) \
  do { \
    gmem_del_called(__FILE__, __LINE__, scalar, 1, size); \
    _GMEM_DEL(scalar, type, size); \
  } while (0)
#define GMEM_NEWARR(array, type, count, size) \
  do { \
    array = (type) calloc(count, size); \
    gmem_new_called(__FILE__, __LINE__, array, count, size); \
  } while (0)
#define GMEM_DELARR(array, type, count, size)   \
  do { \
    gmem_del_called(__FILE__, __LINE__, array, count, size); \
    free(array); \
    array = 0; \
  } while (0)
#define GMEM_NEWSTR(tgt, src, len, ret) \
  do { \
    ret = gmem_strnew(__FILE__, __LINE__, &tgt, src, len);   \
  } while (0)
#define GMEM_DELSTR(str, len) \
  do { \
    gmem_strdel(__FILE__, __LINE__, &str, len);   \
  } while (0)


extern long gmem_new;
extern long gmem_del;

int gmem_new_called(const char* file,
                    int line,
                    void* var,
                    int count,
                    long size);
int gmem_del_called(const char* file,
                    int line,
                    void* var,
                    int count,
                    long size);

int gmem_strnew(const char* file,
                int line,
                char** tgt,
                const char* src,
                int len);
int gmem_strdel(const char* file,
                int line,
                char** str,
                int len);

#endif /* #if !defined(GMEM_CHECK) || GMEM_CHECK < 1 */

#endif
