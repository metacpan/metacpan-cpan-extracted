#ifndef _PMISCDEF_H
#define _PMISCDEF_H	1

#include <string.h>

/* snprintf MS VC++ support;
 * thanks to Viacheslav Sheveliov <slavash@aha.ru>
 */
#ifdef _MSC_VER
#  define snprintf _snprintf
#endif

/* printf ptrdiff_t format modifier */
#if __STDC_VERSION__ >= 199901L
# define TO_PTRDIFF_T(X) (X)
# define MOD_TD "%td"
#elif defined _MSC_VER
# define TO_PTRDIFF_T(X) (X)
# define MOD_TD "%Id"
#else
# define TO_PTRDIFF_T(X) ((long) (X))
# define MOD_TD "%ld"
#endif

#if ! defined HAVE_STRDUP && ! defined strdup
# if defined HAVE__STRDUP
#  define strdup _strdup
# else
#  define strdup(str) strcpy(malloc(strlen(str) + 1), str)
# endif
#endif

#define COMPILE_TIME_ASSERT(x) \
void __cta_proto__(int __cta_foo__[(x) ? 1 : -1])

#ifdef __GNUC__
#define FORMAT_PRINTF(X,Y) __attribute__ ((__format__ (__printf__, X, Y)))
#else
#define FORMAT_PRINTF(X,Y)
#endif

#if defined(__GNUC__) && !(defined(PEDANTIC))
#define INLINE inline
#else /* !__GNUC__ */
#define INLINE 
#endif /* __GNUC__ */


/* C89 compatible flexible array
struct header {
  size_t len;
  unsigned char data[FLEXIBLE_SIZE];
};
struct header *my_header = malloc(SIZEOF_FLEXIBLE(struct header, data, n));
 
expands to 
   = malloc(offsetof(struct header, data) + n * sizeof my_header->data);

Setting FLEXIBLE_SIZE to SIZE_MAX almost ensures this will fail :
struct header *my_header = malloc(sizeof *my_header);
*/
#define FLEXIBLE_SIZE SIZE_MAX /* or whatever maximum length for an array */
#define SIZEOF_FLEXIBLE(type, member, length) \
  ( offsetof(type, member) + (length) * sizeof ((type *)0)->member[0] )

#endif /* pmiscdef.h */

/*
 * Local Variables:
 * mode: c
 * End:
 */
