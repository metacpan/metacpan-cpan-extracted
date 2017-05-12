#ifndef HLIST_H_
#define HLIST_H_

/*
 * A list of headers (HNodes), each of which has header info (Header*) and
 * values (Plist*).
 */

/*
 * Some possible improvements:
 *
 * Forget about ':foo'. Fuck that.
 *
 * Add two flags per HList: comparison is case sensitive (default 0), consider
 * '_' and '-' as distinct (default 0).
 *
 * Add a last HNode, update it when getting and adding, try it first when searching.
 */

/* when we first allocate a chunk of headers, this is the size we use */
#define HLIST_INITIAL_SIZE   4 /* 16 */

#define HLIST_FLAGS_SORTED    0x01
#define HLIST_FLAGS_SENSITIVE 0x02  /* Still unused */
#define HLIST_FLAGS_U_EQ_D    0x04  /* Still unused */

#define HLIST_FLAG_GET(h, f) (h->flags &   f)
#define HLIST_FLAG_SET(h, f)  h->flags |=  f
#define HLIST_FLAG_CLR(h, f)  h->flags &= ~f

typedef struct HNode {
  struct Header* header;  /* the header name and proper sorting order */
  struct PList* values;   /* the list of values associated with this header */
} HNode;

typedef struct HList {
  HNode* data;            /* a chunk of headers (with their respective values) */
  unsigned short alen;    /* allocated size of chunk */
  unsigned short ulen;    /* actual used size in chunk */
  unsigned long flags;    /* flags for this list of headers */
} HList;

/*
 * Create a new HList object.
 */
HList* hlist_create();

/*
 * Destroy a given HList object.
 */
void hlist_destroy(HList* hlist);

/*
 * Clone a given HList object.
 */
HList* hlist_clone(HList* hlist);

/*
 * Initialise a given HList object, leaving it as newly created.
 */
void hlist_init(HList* hlist);

/*
 * Clear all data from a given HList object, leaving it as newly created
 * (maybe with room already allocated).
 */
void hlist_clear(HList* hlist);

/*
 * Return the number of elements in a given HList object.
 */
int hlist_size(const HList* hlist);

/*
 * Get the HNode (or zero) associated with a given name.
 */
HNode* hlist_get(HList* hlist, const char* name);

/*
 * Find (or create) the HNode associated with a given name and add a void*
 * value to it.
 */
HNode* hlist_add(HList* hlist, const char* name, const void* obj);

/*
 * Delete the HNode (if any) associated with a given name.
 */
void hlist_del(HList* hlist, const char* name);

/*
 * Sort a given HList object by the names of its HNode contents.
 */
void hlist_sort(HList* hlist);

/*
 * Dump HList object to an output stream.
 */
void hlist_dump(const HList* hlist, FILE* fp);

/*
 * Transfer the header from an HList object to another HList, without creating
 * or destroying any memory in the process.
 */
void hlist_transfer_header(HList* from, int pos, HList* to);

#endif
