/* list.c */

#include "common.h"
#include "list.h"

#define list_SORTED		(1 << 0)

int list_append( list * l, const list_ITY p ) {
    l->flags &= ~list_SORTED;
    return buffer_append( l, &p, sizeof( p ) );
}

int list_build( list * l, const list_ITY v, size_t sz ) {
    int err;

    if ( err = list_init( l, sz ), ERR_None != err ) {
        return err;
    }

    for ( ; v; v = list_NEXT( v ) ) {
        if ( err = list_append( l, v ), ERR_None != err ) {
            return err;
        }
    }

    return ERR_None;
}

static int list_compare( const void *a, const void *b ) {
    return list_CMP( a, b );
}

void list_sort( list * l ) {
    if ( ( l->flags & list_SORTED ) == 0 ) {
        qsort( l->buf, list_used( l ), list_ISZ, list_compare );
        l->flags |= list_SORTED;
    }
}

long list_true_diff( list * a, list * b, const void *p,
                     list_callback added, list_callback removed ) {
    list_ITY *a_ar;
    list_ITY *b_ar;
    long a_p, b_p, diff;
    size_t a_sz, b_sz;

    list_sort( a );
    list_sort( b );

    a_ar = list_ar( a );
    a_sz = list_used( a );
    a_p = 0;
    b_ar = list_ar( b );
    b_sz = list_used( b );
    b_p = 0;
    diff = 0;

    while ( a_p < a_sz || b_p < b_sz ) {
        while ( a_p < a_sz &&
                ( b_p == b_sz ||
                  list_CMP( &b_ar[b_p], &a_ar[a_p] ) > 0 ) ) {
            if ( removed ) {
                removed( a_ar[a_p], p );
            }
            a_p++;
            diff++;
        }
        while ( b_p < b_sz &&
                ( a_p == a_sz ||
                  list_CMP( &a_ar[a_p], &b_ar[b_p] ) > 0 ) ) {
            if ( added ) {
                added( b_ar[b_p], p );
            }
            b_p++;
            diff++;
        }
        while ( a_p < a_sz && b_p < b_sz &&
                list_CMP( &a_ar[a_p], &b_ar[b_p] ) == 0 ) {
            a_p++;
            b_p++;
        }
    }

    return diff;
}
