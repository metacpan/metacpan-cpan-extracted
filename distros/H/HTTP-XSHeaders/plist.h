#ifndef PLIST_H_
#define PLIST_H_

/*
 * A list of values (PNodes), each of which has just a pointer, since we are
 * storing Perl SVs in here.
 */

/* when we first allocate a chunk of values, this is the size we use */
#define PLIST_INITIAL_SIZE 2 /* 16 */

typedef struct PNode {
  const void* ptr;        /* the pointer we are storing; we claim NO OWNERSHIP on it */
} PNode;

typedef struct PList {
  PNode* data;            /* a chunk of values */
  unsigned short alen;    /* allocated size of chunk */
  unsigned short ulen;    /* actual used size in chunk */
} PList;

/*
 * Create a new PList object.
 */
PList* plist_create(void);

/*
 * Destroy a given PList object.
 */
void plist_destroy(PList* plist);

/*
 * Clone a given PList object.
 */
PList* plist_clone(PList* plist);

/*
 * Initialise a given PList object, leaving it as newly created.
 */
void plist_init(PList* plist);

/*
 * Clear all data from a given PList object, leaving it as newly created
 * (maybe with room already allocated).
 */
void plist_clear(PList* plist);

/*
 * Return the number of elements in a given PList object.
 */
int plist_size(const PList* plist);

/*
 * Add a void* value to the PList.
 */
PNode* plist_add(PList* plist, const void* obj);

/*
 * Dump PList object to an output stream.
 */
void plist_dump(const PList* plist, FILE* fp);

#endif
