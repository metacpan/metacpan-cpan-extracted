/* list.h */

#ifndef __LIST_H
#define __LIST_H

#include "common.h"
#include "buffer.h"

/* Begin type customisation for lists */

#include "EXTERN.h"
#include "perl.h"

/* The type of object handled */
#define list_ITY        SV *
/* The size of list_ITY */
#define list_ISZ        (sizeof (list_ITY))
/* Given a list_ITY how do you find the next one? */
#define list_NEXT(v)    ((list_ITY) SvANY(v))
/* Compare two items to determine ordering; a and b are of type
 * list_ITY *
 */
#define list_CMP(a, b)  (memcmp((a), (b), list_ISZ))

/* End type customisation */

typedef buffer list;

#define list_init(l, sz) \
    buffer_init(l, sz * list_ISZ, 100 * list_ISZ)
#define list_used(l) \
    (buffer_used(l) / list_ISZ)
#define list_size(l) \
    (buffer_size(l) / list_ISZ)
#define list_delete(l) \
    buffer_delete(l)

/* Get pointer to list array */
#define list_ar(l) \
    ((list_ITY *)(l)->buf)

typedef void ( *list_callback ) ( list_ITY v, const void *p );

int list_append( list * l, const list_ITY p );

/* Return the location of the first difference between two lists
 * scanning from the end. The value returned is the offset from
 * the end of each list (i.e. -1 .. -(list size)) of the first
 * difference or 0 if the lists are the same.
 */

#if 0
long list_cmp( const list * a, const list * b );

void list_diff( const list * a, const list * b,
                const void *p,
                list_callback added, list_callback removed );
#endif

int list_build( list * l, const list_ITY v, size_t sz );
void list_sort( list * l );
long list_true_diff( list * a, list * b, const void *p,
                     list_callback added, list_callback removed );

#endif                          /* __LIST_H */
