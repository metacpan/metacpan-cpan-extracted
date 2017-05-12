/* buffer.c */

/* Manage auto-extending buffers */

#include "common.h"
#include "buffer.h"

#include <stdlib.h>
#include <string.h>

int buffer_init( buffer * b, size_t initsize, size_t growby ) {
    if ( initsize > 0 ) {
        if ( b->buf = malloc( initsize ), !b->buf ) {
            return ERR_Not_Enough_Memory;
        }
    }
    else {
        b->buf = NULL;
    }
    b->size = initsize;
    b->used = 0;
    b->growby = growby;
    b->flags = 0;

    return ERR_None;
}

int buffer_delete( buffer * b ) {
    free( b->buf );

    b->buf = NULL;
    b->size = 0;
    b->used = 0;
    b->growby = 0;
    b->flags = 0;

    return ERR_None;
}

int buffer_ensure( buffer * b, size_t minsize ) {
    if ( b->size < minsize ) {
        size_t nsize = NMAX( b->size + b->growby, minsize );
        /* Could realloc here but malloc() / free() works better
           with our debug memory manager. */
        void *nbuf = malloc( nsize );
        if ( !nbuf ) {
            return ERR_Not_Enough_Memory;
        }
        if ( b->buf ) {
            memcpy( nbuf, b->buf, b->used );
            free( b->buf );
        }
        b->buf = nbuf;
        b->size = nsize;
    }

    return ERR_None;
}

int buffer_ensure_free( buffer * b, size_t minfree ) {
    return buffer_ensure( b, b->used + minfree );
}

int buffer_append( buffer * b, const void *m, size_t len ) {
    int err;

    if ( err = buffer_ensure_free( b, len ), ERR_None != err ) {
        return err;
    }

    memcpy( ( char * )b->buf + b->used, m, len );
    b->used += len;
    return ERR_None;
}

int buffer_set_used( buffer * b, size_t used ) {
    int err;

    if ( used > b->used ) {
        if ( err =
             buffer_ensure_free( b, used - b->used ), ERR_None != err ) {
            return err;
        }
    }

    b->used = used;
    return ERR_None;
}
