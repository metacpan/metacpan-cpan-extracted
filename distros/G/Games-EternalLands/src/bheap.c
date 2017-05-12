/*** Binary Heap Implementation ***/
/*
 *   Shane Saunders
 */
/* This implementation stores the binary heap in a 1 dimensional array. */
#include <stdlib.h>
#include <stdio.h>
#include "bheap.h"



/*** Prototypes for functions internal to the implementation. ***/

void bh_siftup(bheap_t *h, int p, int q);



/*** Definitions for visible functions. ***/

void bh_dump(bheap_t *h) {
    int i;

    printf("Heap: \n");
    for(i = 1; i <= h->n; i++) printf(" %d(%ld)", h->a[i].item, h->a[i].key);
    printf("\n");
    
    for(i = 2; i <= h->n; i++) {
        if(h->a[i].key < h->a[i/2].key) {
            printf("key error at entry %d, value %ld\n", i, h->a[i].key);
            exit(1);
        }
    }
    for(i = 1; i <= h->n; i++) {
        if(h->p[h->a[i].item] != i) {
            printf("indexing error at entry %d", i); exit(1);
        }
    }    
}

/* bh_alloc() allocates space for a binary heap of size n and initialises it.
 * Returns a pointer to the binary heap.
 */
bheap_t *bh_alloc(int n)
{
    bheap_t *h;

    /* Create the binary heap. */
    h = malloc(sizeof(bheap_t));
    
    /* For the purpose of indexing the binary heap, we require n+1 elements in
     * a[] since the indexing used does not use a[0].
     */
    h->a = calloc(n+1, sizeof(bheap_item_t));
    h->p = calloc(n, sizeof(int));
    h->n = 0;
    h->key_comps = 0;

    return h;
}


/* bh_free() frees the space taken up by the binary heap pointed to by h.
 */
void bh_free(bheap_t *h)
{
    free(h->a);
    free(h->p);
    free(h);
}


/* bh_min() returns the item with the minimum key in the binary heap pointed to
 * by h.
 */
int bh_min(bheap_t *h)
{
    /* The item at the top of the binary heap has the minimum key value. */
    return h->a[1].item;
}


/* bh_insert() inserts an item and its key value into the binary heap pointed
 * to by h.
 */
void bh_insert(bheap_t *h, int item, long key)
{
    /* i - insertion point
     * j - parent of i
     * y - parent's entry in the heap.
     */
    int i, j;
    bheap_item_t y;

    /* i initially indexes the new entry at the bottom of the heap. */
    i = ++(h->n);

    /* Stop if the insertion point reaches the top of the heap. */
    while(i >= 2) {
        /* j indexes the parent of i.  y is the parent's entry. */
        j = i / 2;
        y = h->a[j];

        /* We have the correct insertion point when the item's key is >= parent
         * Otherwise we move the parent down and insertion point up.
         */
	h->key_comps++;
        if(key >= y.key) break;

        h->a[i] = y;
        h->p[y.item] = i;
        i = j;
    }

    /* Insert the new item at the insertion point found. */
    h->a[i].item = item;
    h->a[i].key = key;
    h->p[item] = i;
}


/* bh_delete() deletes an item from the binary heap pointed to by h.
 */
void bh_delete(bheap_t *h, int item)
{
    int n;
    int p;

    /* Decrease the number of entries in the heap and record the position of
     * the item to be deleted.
     */
    n = --(h->n);
    p = h->p[item];

    /* Heap needs adjusting if the position of the deleted item was not at the
     * end of the heap.
     */
    if(p <= n) {
        /* We put the item at the end of the heap in the place of the deleted
         * item and sift-up or sift-down to relocate it in the correct place in
         * the heap.
         */
	h->key_comps++;
        if(h->a[p].key <= h->a[n + 1].key) {
            h->a[p] = h->a[n + 1];
            h->p[h->a[p].item] = p;
            bh_siftup(h, p, n);
        }
        else {
            /* Use insert to sift-down, temporarily adjusting the size of the
             * heap for the call to insert.
             */
            h->n = p - 1;
            bh_insert(h, h->a[n + 1].item, h->a[n+1].key);
            h->n = n;
        }
    }
}


/* bh_decrease_key() decreases the value of 'item's key and then performs
 * sift-down until 'item' has been relocated to the correct position in the
 * binary heap.
 */
void bh_decrease_key(bheap_t *h, int item, long new_key)
{
    int n;

    n = h->n;
    h->n = h->p[item] - 1;

    bh_insert(h, item, new_key);

    h->n = n;
}



/*** Definitions for internal functions ***/

/* siftup() considers the sub-tree rooted at p that ends at q and moves
 * the root down, sifting up the minimum child until it is located in the
 * correct part of the binary heap.
 */
void bh_siftup(bheap_t *h, int p, int q)
{
    /* y - the heap entry of the root.
     * j - the current insertion point for the root.
     * k - the child of the insertion point.
     * z - heap entry of the child of the insertion point.
     */
    int j, k;
    bheap_item_t y, z;

    /* Get the value of the root and initialise the insertion point and child.
     */
    y = h->a[p];
    j = p;
    k = 2 * p;

    /* sift-up only if there is a child of the insertion point. */
    while(k <= q) {

        /* Choose the minimum child unless there is only one. */
        z = h->a[k];
        if(k < q) {
	    h->key_comps++;
            if(z.key > h->a[k + 1].key) z = h->a[++k];
        }

        /* We stop if the insertion point for the root is in the correct place.
         * Otherwise the child goes up and the root goes down.  (i.e. swap)
         */
        if(y.key <= z.key) break;
        h->a[j] = z;
        h->p[z.item] = j;
        j = k;
        k = 2 * j;
    }

    /* Insert the root in the correct place in the heap. */
    h->a[j] = y;
    h->p[y.item] = j;
}




/*** Implement the universal heap structure type ***/

/* Binary heap wrapper functions. */

int _bh_delete_min(void *h) {
    int v;
    v = bh_min((bheap_t *)h);
    bh_delete((bheap_t *)h, v);
    return v;
}

void _bh_insert(void *h, int v, long k) {
    bh_insert((bheap_t *)h, v, k);
}

void _bh_decrease_key(void *h, int v, long k) {
    bh_decrease_key((bheap_t *)h, v, k);
}

int _bh_n(void *h) {
    return ((bheap_t *)h)->n;
}

long _bh_key_comps(void *h) {
    return ((bheap_t *)h)->key_comps;
}

void *_bh_alloc(int n) {
    return bh_alloc(n);
}

void _bh_free(void *h) {
    bh_free((bheap_t *)h);
}

void _bh_dump(void *h) {
    bh_dump((bheap_t *)h);
}

/* Binary heap info. */
const heap_info_t BHEAP_info = {
    _bh_delete_min,
    _bh_insert,
    _bh_decrease_key,
    _bh_n,
    _bh_key_comps,
    _bh_alloc,
    _bh_free,
    _bh_dump
};
