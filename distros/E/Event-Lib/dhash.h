#ifndef __DHASH_H__
#define __DHASH_H__

typedef unsigned int hash_t;

typedef struct {
    int flags;
    struct event_args *ev;
} dhash_val_t;

typedef struct {
    int size;
    int count;
    dhash_val_t *ary;
} dhash_t;

dhash_val_t EMPTY = { 0, NULL };

#define dhash_init(h)			\
{					\
    Newz(0, (h)->ary, 4, dhash_val_t);	\
    (h)->size = 4;			\
    (h)->count = 0;			\
}

inline hash_t HASH(register hash_t k) {
    k += (k << 12);
    k ^= (k >> 22);
    k += (k << 4);
    k ^= (k >> 9);
    k += (k << 10);
    k ^= (k >> 2);
    k += (k << 7);
    k ^= (k >> 12);
    return k;
}

void dhash_insert(dhash_t *h, dhash_val_t val, hash_t hash) {
    while (h->ary[hash].ev && h->ary[hash].ev != val.ev) 
	hash = ++hash % h->size;
    if (h->ary[hash].ev != val.ev)
	h->count++;
    h->ary[hash] = val;
}

void dhash_resize(dhash_t *h) {
    
    dhash_val_t *old;
    register int i;
    register hash_t hash;
    
    New(0, old, h->size, dhash_val_t);
    Copy(h->ary, old, h->size, dhash_val_t);
    
    h->size <<= 1;
    h->count = 0;
    Newz(0, h->ary, h->size, dhash_val_t);
    
    for (i = 0; i < h->size>>1; i++) {
	if (!old[i].ev)
	    continue;
	hash = HASH(PTR2IV(old[i].ev)) % h->size;
	dhash_insert(h, old[i], hash);
    }
    Safefree(old);
}

void dhash_store(dhash_t *h, dhash_val_t val) {
    hash_t hash;
    if (h->count / h->size > 0.8)
	dhash_resize(h);
    hash = HASH(PTR2IV(val.ev)) & h->size;
    dhash_insert(h, val, hash);
}

dhash_val_t * dhash_find(dhash_t *h, struct event_args *ev) {
    hash_t hash = HASH(PTR2IV(ev)) % h->size;
    hash_t stop = hash;
    
    register int i;

    while (h->ary[hash].ev != ev) {
	hash = (hash + 1) % h->size;
	if (hash == stop)
	    goto NOT_FOUND;
    }

    return &h->ary[hash];
NOT_FOUND:
    return NULL;
}
    
void dhash_delete(dhash_t *h, struct event_args *ev) {
    hash_t hash = HASH(PTR2IV(ev)) % h->size;
    dhash_val_t *found;

    if (found = dhash_find(h, ev)) {
	*found = EMPTY;
	h->count--;
    }
}

#endif
