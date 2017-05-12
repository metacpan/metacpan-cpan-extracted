/* hash.h */

#ifndef __hash_h
#define __hash_h

#include "buffer.h"

typedef struct _hash_slot hash_slot;

/* A key in the hash. The key data follows it
 * inline.
 */
struct _hash_slot {
    long link;                  /* Offset of next link in chain */
    size_t key_len;             /* Length of key (key data is inline after this) */
    void *v;                    /* Value pointer */
};

struct _hash;

typedef int ( *hash_cb_kc ) ( struct _hash * h, void *d, const char *k,
                              void *v );

/* A hash */
typedef struct _hash {
    buffer buf;                 /* Buffer for keys */
    long *slot;                 /* Array of buckets */
    long cap;                   /* Size of bucket array */
    long state;                 /* Incremented every time the hash's state changes so that we
                                 * can spot the case where an iterator gets out of sync with
                                 * the hash it's iterating over.
                                 */
    size_t size;
    size_t deleted;

    /* Optional callbacks for value addition, deletion */
    void *cbd;
    int ( *cb_add ) ( struct _hash * h, void *d, void **v );
    int ( *cb_del ) ( struct _hash * h, void *d, void *v );
    int ( *cb_upd ) ( struct _hash * h, void *d, void *ov, void **nv );

} hash;

typedef struct {
    long state;
    long bucket;
    long sl;
} hash_iter;

extern void *hash_NULL;
#define hash_PUTNULL(p) ((p) ? (p) : hash_NULL)
#define hash_GETNULL(p) ((p) == hash_NULL ? NULL : p)

int hash_new( long capacity, hash ** hh );
int hash_set_callbacks( hash * h, void *cbd,
                        int ( *cb_add ) ( hash * h, void *d, void **v ),
                        int ( *cb_del ) ( hash * h, void *d, void *v ),
                        int ( *cb_upd ) ( struct _hash * h, void *d,
                                          void *ov, void **nv ) );
int hash_delete( hash * h );
int hash_put( hash * h, const void *key, size_t key_len, void *val );
int hash_delete_key( hash * h, const void *key, size_t key_len );
void *hash_get( hash * h, const void *key, size_t key_len );
size_t hash_size( hash * h );
const void *hash_get_first_key( hash * h, hash_iter * i,
                                size_t * key_len );
const void *hash_get_next_key( hash * h, hash_iter * i, size_t * key_len );

#endif                          /* __hash_h */
