/* buffer.h */

#ifndef __buffer_h
#define __buffer_h

#include <stddef.h>

typedef struct {
    void *buf;
    size_t used;
    size_t size;
    size_t growby;
    unsigned long flags;        /* Unused here - available for user apps */
} buffer;

int buffer_init( buffer * b, size_t initsize, size_t growby );
int buffer_delete( buffer * b );
int buffer_ensure( buffer * b, size_t minsize );
int buffer_ensure_free( buffer * b, size_t minfree );
int buffer_append( buffer * b, const void *m, size_t len );
int buffer_set_used( buffer * b, size_t used );

#define buffer_used(b) ((b)->used)
#define buffer_size(b) ((b)->size)

#endif                          /* __buffer_h */
