/* hash.c */

#include "common.h"

#include "buffer.h"
#include "hash.h"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

/* Special value that can be used to represent NULL in a hash to make it
 * distinct from the NULL return when a key isn't present. 
 */
void *hash_NULL = "[hash null]";

/* #define INSTRUMENT */
#ifdef INSTRUMENT
#include <stdio.h>

static struct {
    long n_new;
    long n_delete;
    long n_delete_key;
    long n_put;
    long n_get;
    long n_get_key;
    long n_hash;
    long n_rehash;
    long n_find;
} _stats;

static void _inst_dump( void ) {
    fprintf( stderr, "       hash_new(): %10ld\n", _stats.n_new );
    fprintf( stderr, "    hash_delete(): %10ld\n", _stats.n_delete );
    fprintf( stderr, "hash_delete_key(): %10ld\n", _stats.n_delete_key );
    fprintf( stderr, "       hash_put(): %10ld\n", _stats.n_put );
    fprintf( stderr, "       hash_get(): %10ld\n", _stats.n_get );
    fprintf( stderr, "   hash_get_key(): %10ld\n", _stats.n_get_key );
    fprintf( stderr, "          _hash(): %10ld\n", _stats.n_hash );
    fprintf( stderr, "        _rehash(): %10ld\n", _stats.n_rehash );
    fprintf( stderr, "          _find(): %10ld\n", _stats.n_find );
}

static void _inst_init( void ) {
    static int init_done = 0;
    if ( !init_done ) {
        atexit( _inst_dump );
        init_done = 1;
    }
}

static int _init_done = 0;

#define INST_A(f, c)    do { _stats.n_ ## f += (c); } while (0)
#define INST_I(f)       INST_A(f, 1)
#define INST_INIT()     _inst_init()
#else
#define INST_A(f, c)    (void) 0
#define INST_I(f)       (void) 0
#define INST_INIT()     (void) 0
#endif

#define KEY(sl) ((const void *) ((sl) + 1))
#define EQKEY(sl, key, key_len) \
    ((sl)->key_len == key_len && memcmp(KEY(sl), key, key_len) == 0)

int hash_new( long capacity, hash ** hh ) {
    hash *h;
    int err;
    long s;

    INST_INIT(  );
    INST_I( new );

    if ( capacity <= 0 ) {
        capacity = 1;
    }

    if ( h = malloc( sizeof( hash ) ), !h ) {
        return ERR_Not_Enough_Memory;
    }

    if ( h->slot = malloc( sizeof( hash_slot * ) * capacity ), !h->slot ) {
        free( h );
        return ERR_Not_Enough_Memory;
    }

    h->cap = capacity;
    h->state = 0;
    h->size = 0;
    h->deleted = 0;

    h->cbd = NULL;
    h->cb_add = NULL;
    h->cb_del = NULL;
    h->cb_upd = NULL;

    for ( s = 0; s < h->cap; s++ ) {
        h->slot[s] = -1;
    }

    if ( err = buffer_init( &h->buf, 0, 256 ), ERR_None == err ) {
        *hh = h;
    }

    return err;
}

int hash_set_callbacks( hash * h, void *cbd,
                        int ( *cb_add ) ( hash * h, void *d, void **v ),
                        int ( *cb_del ) ( hash * h, void *d, void *v ),
                        int ( *cb_upd ) ( hash * h, void *d, void *ov,
                                          void **nv ) ) {
    h->cbd = cbd;
    h->cb_add = cb_add;
    h->cb_del = cb_del;
    h->cb_upd = cb_upd;

    return ERR_None;
}

int hash_delete( hash * h ) {
    INST_I( delete );

    if ( !h ) {
        return ERR_None;
    }

    /* If the cb_del callback is defined we need to call
     * it for each of the values the hash contains.
     */
    if ( h->cb_del ) {
        long b, s;
        int err;
        for ( b = 0; b < h->cap; b++ ) {
            for ( s = h->slot[b]; s != -1; ) {
                hash_slot *sl =
                    ( hash_slot * ) ( ( char * )h->buf.buf + s );
                if ( err = h->cb_del( h, h->cbd, sl->v ), ERR_None != err ) {
                    return err;
                }
                s = sl->link;
            }
        }
    }

    buffer_delete( &h->buf );
    free( h->slot );
    free( h );
    return ERR_None;
}

/* Compute the hash for a key */
static unsigned long _hash( const void *k, size_t kl ) {
    unsigned long h = 0;
    const unsigned char *kp = k;
    INST_I( hash );
    while ( kl-- ) {
        h = 31 * h + ( *kp++ );
    }
    return h;
}

static long _find( hash * h, const void *key, size_t key_len,
                   unsigned long hc ) {
    long s = h->slot[hc % h->cap];
    INST_I( find );
    while ( -1 != s ) {
        hash_slot *sl = ( hash_slot * ) ( ( char * )h->buf.buf + s );
        if ( EQKEY( sl, key, key_len ) ) {
            return s;
        }
        s = sl->link;
    }
    return s;
}

/* Change the bucket count of a hash to better suit the number of keys it
 * contains. At the moment this simplemindedly copies the old hash an item at a
 * time into a new hash and then pillages the fields of the new hash to
 * repopulate the old one.
 *
 * A smarter strategy might be to merge all the bucket chains into a single
 * chain - like a hash with just one bucket and then redistribute them into a
 * set of new buckets. That would avoid copying all the keys but wouldn't
 * garbage collect deleted keys.
 *
 * Note that it's theoretically possible that the new hash we create here could
 * decide to recursively rehash itself. The only thing stopping that is the
 * fact that the new hash has enough buckets for all the keys from the outset.
 * Bear that in mind if you decide to tinker with the code. A recursive rehash
 * shouldn't break anything but it's clearly a bit daft.
 */
static int _rehash( hash * h ) {
    const void *key;
    size_t key_len;
    hash *nh;
    hash_iter i;
    int err;

    /* Might as well have plenty of buckets: they're cheap */
    long ncap = NMAX( 10, h->size * 2 );

    INST_I( rehash );

    /* All we do is make a new hash and copy the old one into it...
     */
    if ( err = hash_new( ncap, &nh ), ERR_None != err ) {
        return err;
    }

    /* Iterate through the keys copying entries one at a time. This has the
     * happy side effect of clearing out the garbage left by any deleted keys.
     * Any callbacks that are installed for the original hash won't be in
     * effect on the new hash so there's no need to worry about any side
     * effects they might have. Once the new hash data is moved back into the
     * original hash any callbacks will automatically take effect again.
     */
    key = hash_get_first_key( h, &i, &key_len );
    while ( key ) {
        if ( err =
             hash_put( nh, key, key_len, hash_get( h, key, key_len ) ),
             ERR_None != err ) {
            hash_delete( nh );
            return err;
        }
        key = hash_get_next_key( h, &i, &key_len );
    }

    /* Delete the old contents of the hash and...
     */
    buffer_delete( &h->buf );
    free( h->slot );

    /* ...move various bits of the new hash into it.
     */
    h->buf = nh->buf;
    h->slot = nh->slot;
    h->cap = nh->cap;
    h->size = nh->size;
    h->deleted = 0;

    /* Tweak the buffer's growby field */
    h->buf.growby = NMAX( h->buf.size / 4, 256 );

    /* This definitely represents a change in the hash's state... */
    h->state++;

    /* Destroy the (now empty) header of the new hash.
     */
    free( nh );

    return ERR_None;
}

int hash_delete_key( hash * h, const void *key, size_t key_len ) {
    unsigned int hc = _hash( key, key_len );
    long *sp = &h->slot[hc % h->cap];
    long s = *sp;
    INST_I( delete_key );
    while ( -1 != s ) {
        hash_slot *sl = ( hash_slot * ) ( ( char * )h->buf.buf + s );
        if ( EQKEY( sl, key, key_len ) ) {
            if ( h->cb_del ) {
                int err;
                if ( err = h->cb_del( h, h->cbd, sl->v ), err != ERR_None ) {
                    return err;
                }
            }
            *sp = sl->link;
            h->size--;
            h->deleted++;
            if ( h->deleted > h->size ) {
                return _rehash( h );
            }
            return ERR_None;
        }
        sp = &sl->link;
        s = *sp;
    }

    /* Note that we haven't incremented state because a deletion can't break an
     * iterator. Well, that's the idea anyway.
     * TODO: But deletion /can/ cause a rehash - and that'd definitely break
     * an iterator... Bugger.
     */

    return ERR_None;
}

/* Add/replace a value in the hash. The key is copied into the hash structure
 * but the value is treated as an opaque pointer so the life of the pointed-to
 * object must match the life of the hash.
 */
int hash_put( hash * h, const void *key, size_t key_len, void *val ) {
    unsigned int hc = _hash( key, key_len );
    hash_slot *sl;
    int err;
    long s;
    INST_I( put );

    if ( s = _find( h, key, key_len, hc ), -1 == s ) {
        long sn = hc % h->cap;

        /* Create a new entry which includes the key inline after the
         * hash_slot structure.
         */
        size_t sz = sizeof( hash_slot ) + PAD( key_len );

        /* Grow the buffer. This may cause it to move altogether which is why
         * we don't stash self referential addresses in the hash.
         */
        if ( err = buffer_ensure_free( &h->buf, sz ), ERR_None != err ) {
            return err;
        }

        /* Call any registered callback /before/ we modify the structure so
         * that if it fails the only possible change to the hash is that the
         * buffer will have been expanded.
         */
        if ( h->cb_add ) {
            if ( err = h->cb_add( h, h->cbd, &val ), ERR_None != err ) {
                return err;
            }
        }

        s = h->buf.used;
        sl = ( hash_slot * ) ( ( char * )h->buf.buf + s );
        h->buf.used += sz;
        sl->v = val;
        memcpy( ( void * )KEY( sl ), key, key_len );
        sl->key_len = key_len;
        sl->link = h->slot[sn];
        h->slot[sn] = s;
        h->state++;
        h->size++;

        if ( ( int )h->size > h->cap * 5 ) {
            return _rehash( h );
        }
    }
    else {
        /* Replace an existing entry.
         */
        sl = ( hash_slot * ) ( ( char * )h->buf.buf + s );

        /* If the value is actually changing inform any callbacks */
        if ( sl->v != val ) {
            if ( h->cb_upd ) {
                if ( err =
                     h->cb_upd( h, h->cbd, sl->v, &val ),
                     ERR_None != err ) {
                    /* NULL out the pointer on the assumption that the update function
                     * at least managed to free the old value. If this turns out to be
                     * untrue we'll have leaked a little.
                     */
                    sl->v = NULL;
                    return err;
                }
            }
            else {
                if ( h->cb_del ) {
                    if ( err =
                         h->cb_del( h, h->cbd, sl->v ), ERR_None != err ) {
                        sl->v = NULL;
                        return err;
                    }
                }
                if ( h->cb_add ) {
                    if ( err =
                         h->cb_add( h, h->cbd, &val ), ERR_None != err ) {
                        return err;
                    }
                }
            }
        }

        sl->v = val;
    }

    return ERR_None;
}

void *hash_get( hash * h, const void *key, size_t key_len ) {
    long s = _find( h, key, key_len, _hash( key, key_len ) );
    INST_I( get );

    if ( s == -1 ) {
        return NULL;
    }
    else {
        hash_slot *sl = ( hash_slot * ) ( ( char * )h->buf.buf + s );
        return sl->v;
    }
}

size_t hash_size( hash * h ) {
    return h->size;
}

const void *hash_get_first_key( hash * h, hash_iter * i, size_t * key_len ) {
    i->state = h->state;
    i->bucket = 0;
    i->sl = h->slot[i->bucket];
    return hash_get_next_key( h, i, key_len );
}

const void *hash_get_next_key( hash * h, hash_iter * i, size_t * key_len ) {
    const void *key;
    hash_slot *sl;

    /* Assertion fails if the hash has been updated since this iterator was
     * initialised.
     */
    if ( i->state != h->state ) {
        fprintf( stderr, "Hash modified during iteration\n" );
        exit( 1 );
    }

    while ( i->sl == -1 ) {
        if ( ++i->bucket >= h->cap ) {
            return NULL;
        }
        i->sl = h->slot[i->bucket];
    }

    sl = ( hash_slot * ) ( ( char * )h->buf.buf + i->sl );
    key = KEY( sl );
    i->sl = sl->link;

    if ( key_len ) {
        *key_len = sl->key_len;
    }

    return key;
}
