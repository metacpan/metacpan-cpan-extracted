#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#include <mm.h>

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {

    case 'M':
        if (strEQ(name, "MM_LOCK_RD"))
            return MM_LOCK_RD;

        if (strEQ(name, "MM_LOCK_RW"))
            return MM_LOCK_RW;

    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

typedef struct {
	MM *mm;
	void *data;
	size_t size;
} mm_scalar;

mm_scalar *mm_make_scalar(MM *mm)
{
	mm_scalar *scalar;

	scalar = mm_malloc(mm, sizeof(mm_scalar));
	if (!scalar)
		return(0);

	scalar->mm = mm;
	scalar->data = 0;
	scalar->size = 0;

	return(scalar);
}

void mm_free_scalar(mm_scalar *scalar)
{
	if (scalar->data) {
		mm_free(scalar->mm, scalar->data);
		scalar->data = 0;
	}
	mm_free(scalar->mm, scalar);
}


SV *mm_scalar_get_core(mm_scalar *scalar)
{
	if (!scalar->data || !scalar->size)
		return(&PL_sv_undef);

	return(newSVpvn(scalar->data, scalar->size));
}

SV *mm_scalar_get(mm_scalar *scalar)
{
	SV *sv = &PL_sv_undef;
	if (mm_lock(scalar->mm, MM_LOCK_RD)) {
		sv = mm_scalar_get_core(scalar);
		mm_unlock(scalar->mm);
	}
	return(sv);
}

int mm_scalar_set(mm_scalar *scalar, SV *sv)
{
	void *data, *ptr, *oldptr;
	size_t size;

	data = SvPV(sv, size);

	ptr = mm_calloc(scalar->mm, 1, size + 1);
	if (!ptr)
		return(0);

	if (!mm_lock(scalar->mm, MM_LOCK_RW))
		return(0);

	memcpy(ptr, data, size);
	oldptr = scalar->data;
	scalar->data = ptr;
	scalar->size = size;

	mm_unlock(scalar->mm);

	mm_free(scalar->mm, oldptr);

	return(1);
}

struct mm_btree_elt;
typedef struct mm_btree_elt mm_btree_elt;

typedef struct {
	MM *mm;
	int (*func)(const void *, const void *);
	int nelts;
	struct mm_btree_elt *root;
} mm_btree;

struct mm_btree_elt {
	struct mm_btree_elt *parent;
	struct mm_btree_elt *prev;
	void *curr;
	struct mm_btree_elt *next;
};

mm_btree *mm_make_btree(MM *mm, int (*func)(const void *, const void *))
{
	mm_btree *btree;

	btree = mm_calloc(mm, 1, sizeof(mm_btree));
	if (!btree)
		return(0);

	btree->mm = mm;
	btree->func = func;

	return(btree);
}

void mm_free_btree(mm_btree *btree)
{
	mm_free(btree->mm, btree);
}

mm_btree_elt *mm_btree_get_core(mm_btree *btree, mm_btree_elt *elt, void *key)
{
	mm_btree_elt *res = 0;

	if (elt) {
		int rc;
		rc = btree->func(key, elt->curr);
		if (rc == 0)
			res = elt;
		else if (rc < 0)
			res = mm_btree_get_core(btree, elt->prev, key);
		else
			res = mm_btree_get_core(btree, elt->next, key);
	}

	return(res);
}

void *mm_btree_get(mm_btree *btree, void *key)
{
	mm_btree_elt *elt;
	elt = mm_btree_get_core(btree, btree->root, key);
	return((elt) ? elt->curr : 0);
}

void mm_btree_insert_core(mm_btree *btree, mm_btree_elt *elt, mm_btree_elt *key)
{
	int rc;
	rc = btree->func(key->curr, elt->curr);
	if (rc < 0) {
		if (elt->prev) {
			mm_btree_insert_core(btree, elt->prev, key);
		} else {
			key->parent = elt;
			elt->prev = key;
			btree->nelts++;
		}
	} else if (rc > 0) {
		if (elt->next) {
			mm_btree_insert_core(btree, elt->next, key);
		} else {
			key->parent = elt;
			elt->next = key;
			btree->nelts++;
		}
	}
}

void mm_btree_insert(mm_btree *btree, mm_btree_elt *key)
{
	if (btree->root) {
		mm_btree_insert_core(btree, btree->root, key);
	} else {
		key->parent = 0;
		btree->root = key;
		btree->nelts++;
	}
}

void mm_btree_remove(mm_btree *btree, mm_btree_elt *key)
{
	if (key->parent) {
		if (key->parent->prev == key) {
			key->parent->prev = 0;
		} else if (key->parent->next == key) {
			key->parent->next = 0;
		}
	} else {
		btree->root = 0;
	}
	if (key->prev)
		mm_btree_insert(btree, key->prev);
	if (key->next)
		mm_btree_insert(btree, key->next);
	btree->nelts--;
}

typedef struct {
	char *key;
	mm_scalar *val;
} table_entry;

int btree_table_compare(const void *pa, const void *pb)
{
	table_entry *a, *b;
	a = (table_entry *) pa;
	b = (table_entry *) pb;
	return(strcmp(a->key, b->key));
}

mm_btree *mm_make_btree_table(MM *mm)
{
	return(mm_make_btree(mm, btree_table_compare));
}

void mm_free_btree_table_elt(mm_btree *btree, mm_btree_elt *elt)
{
	table_entry *telt;
	telt = elt->curr;
	if (telt) {
		if (telt->key) mm_free(btree->mm, telt->key);
		if (telt->val) mm_free_scalar(telt->val);
		mm_free(btree->mm, telt);
	}
	mm_free(btree->mm, elt);
}

void mm_clear_btree_table_core(mm_btree *btree, mm_btree_elt *elt)
{
	if (elt->prev)
		mm_clear_btree_table_core(btree, elt->prev);
	if (elt->next)
		mm_clear_btree_table_core(btree, elt->next);
	mm_free_btree_table_elt(btree, elt);
}

void mm_clear_btree_table(mm_btree *btree)
{
	mm_btree_elt *root = 0;

	if (mm_lock(btree->mm, MM_LOCK_RW)) {
		root = btree->root;
		btree->root = 0;
		mm_unlock(btree->mm);
	}

	if (root)
		mm_clear_btree_table_core(btree, root);
}

void mm_free_btree_table(mm_btree *btree)
{
	mm_clear_btree_table(btree);
	mm_free_btree(btree);
}

SV *mm_btree_table_get_core(mm_btree *btree, char *key)
{
	table_entry elt, *match;
	elt.key = key;
	elt.val = 0;
	match = mm_btree_get(btree, &elt);
	return((match && match->val) ? mm_scalar_get_core(match->val) : &PL_sv_undef);
}

SV *mm_btree_table_get(mm_btree *btree, char *key)
{
	SV *ret = &PL_sv_undef;
	if (mm_lock(btree->mm, MM_LOCK_RD)) {
		ret = mm_btree_table_get_core(btree, key);
		mm_unlock(btree->mm);
	}
	return(ret);
}

int mm_btree_table_insert(mm_btree *btree, char *key, SV *val)
{
	mm_scalar *scalar;
	table_entry *telt;
	mm_btree_elt *belt, *old = 0;
	int rc;

	scalar = mm_make_scalar(btree->mm);
	if (!scalar)
		return(0);

	rc = mm_scalar_set(scalar, val);
	if (!rc)
		return(0);

	telt = mm_malloc(btree->mm, sizeof(table_entry));
	if (!telt)
		return(0);
	telt->key = mm_strdup(btree->mm, key);
	if (!telt->key)
		return(0);
	telt->val = scalar;

	belt = mm_calloc(btree->mm, 1, sizeof(mm_btree_elt));
	if (!belt)
		return(0);
	belt->curr = telt;

	if (mm_lock(btree->mm, MM_LOCK_RW)) {
		old = mm_btree_get_core(btree, btree->root, telt);
		if (old)
			mm_btree_remove(btree, old);
		mm_btree_insert(btree, belt);
		mm_unlock(btree->mm);
	}

	if (old)
		mm_free_btree_table_elt(btree, old);

	return(1);
}

SV *mm_btree_table_delete(mm_btree *btree, char *key)
{
	SV *ret = &PL_sv_undef;
	mm_btree_elt *old = 0;
	if (mm_lock(btree->mm, MM_LOCK_RW)) {
		table_entry elt;
		elt.key = key;
		elt.val = 0;
		old = mm_btree_get_core(btree, btree->root, &elt);
		if (old)
			mm_btree_remove(btree, old);
		mm_unlock(btree->mm);
	}
	if (old) {
		table_entry *elt;
		elt = old->curr;
		if (elt && elt->val)
			ret = mm_scalar_get_core(elt->val);
		mm_free_btree_table_elt(btree, old);
	}
	return(ret);
}

SV *
mm_btree_table_exists(mm_btree *btree, char *key)
{
	SV *ret = &PL_sv_undef;
	if (mm_lock(btree->mm, MM_LOCK_RD)) {
		table_entry elt;
		elt.key = key;
		elt.val = 0;
		ret = (mm_btree_get_core(btree, btree->root, &elt)) ? &PL_sv_yes : &PL_sv_no;
		mm_unlock(btree->mm);
	}
	return(ret);
}

SV *mm_btree_table_first_key_core(mm_btree *btree, mm_btree_elt *elt)
{
	table_entry *telt;
	if (elt->prev)
		return(mm_btree_table_first_key_core(btree, elt->prev));
	telt = elt->curr;
	return((telt && telt->key) ? newSVpv(telt->key, 0) : &PL_sv_undef);
}

SV *mm_btree_table_first_key(mm_btree *btree)
{
	SV *ret = &PL_sv_undef;
	if (mm_lock(btree->mm, MM_LOCK_RD)) {
		if (btree->root)
			ret = mm_btree_table_first_key_core(btree, btree->root);
		mm_unlock(btree->mm);
	}
	return(ret);
}

SV *mm_btree_table_next_key_core(mm_btree *btree, mm_btree_elt *elt)
{
	if (elt->parent && elt->parent->prev == elt) {
		table_entry *telt;
		telt = elt->parent->curr;
		return((telt && telt->key) ? newSVpv(telt->key, 0) : &PL_sv_undef);
	} else if (elt->parent && elt->parent->next == elt) {
		return(mm_btree_table_next_key_core(btree, elt->parent));
	} else {
		return(&PL_sv_undef);
	}
}

SV *mm_btree_table_next_key(mm_btree *btree, char *key)
{
	SV *ret = &PL_sv_undef;
	if (mm_lock(btree->mm, MM_LOCK_RD)) {
		mm_btree_elt *elt;
		table_entry telt;
		telt.key = key;
		telt.val = 0;
		elt = mm_btree_get_core(btree, btree->root, &telt);
		if (elt) {
			if (elt->next)
				ret = mm_btree_table_first_key_core(btree, elt->next);
			else
				ret = mm_btree_table_next_key_core(btree, elt);
		}
		mm_unlock(btree->mm);
	}
	return(ret);
}


/* ==================================================================

   A hash implementation using mm.

   ==================================================================
*/

#define HASHSIZE 101

/* hash */
struct mm_hash_elt;
typedef struct mm_hash_elt mm_hash_elt;

typedef struct {
	MM *mm;
	mm_hash_elt *hashtab[HASHSIZE];
} mm_hash;

/* hash element */
struct mm_hash_elt {
	struct mm_hash_elt *next;
	char *key;
	char *val;
	size_t val_len;
};

/* The hashing function uses perl's hashing function. */
#define MM_HASH(hash,str,len) \
	PERL_HASH(hash,str,len); \
	hash %= HASHSIZE;


/* ---------------------------------------------------------------------
   mm_make_hash

   Initializes a new hash.
   ---------------------------------------------------------------------
*/

mm_hash *mm_make_hash(MM *mm)
{
	mm_hash *hash;

	hash = mm_calloc(mm, 1, sizeof(mm_hash));
	if (!hash)
		return(0);

	hash->mm = mm;

	return(hash);
}

/* ---------------------------------------------------------------------
   mm_hash_get

   Returns the hash_elt pointer of a specified key in a hash.
   For internal use only.
   ---------------------------------------------------------------------
*/

mm_hash_elt *mm_hash_get(mm_hash *hash, void *key)
{
	mm_hash_elt *elt;
	unsigned int idx;

	MM_HASH(idx, key, strlen(key));

	for (elt = hash->hashtab[idx]; elt != NULL; elt = elt->next)
		if (strcmp(key, elt->key) == 0)
			return elt;

	return NULL;
}

/* ---------------------------------------------------------------------
   mm_hash_get_value

   Returns the value of a specified hash element.
   ---------------------------------------------------------------------
*/

SV *mm_hash_get_value(mm_hash *hash, char *key)
{
	mm_hash_elt *elt;
	SV *ret = &PL_sv_undef;

	if (mm_lock(hash->mm, MM_LOCK_RD)) {
		elt = mm_hash_get(hash, key);
		if ((elt != NULL) && (elt->val != NULL))
			ret = newSVpv(elt->val, elt->val_len);
		mm_unlock(hash->mm);
	}
	return (ret);
}

/* ---------------------------------------------------------------------
   mm_hash_exists

   Returns whether a specified key exists in a hash.
   ---------------------------------------------------------------------
*/

SV *mm_hash_exists(mm_hash *hash, char *key)
{
	mm_hash_elt *elt;
	SV *ret = &PL_sv_no;

	if (mm_lock(hash->mm, MM_LOCK_RD)) {
		elt = mm_hash_get(hash, key);
		if (elt != NULL)
			ret = &PL_sv_yes;
		mm_unlock(hash->mm);
	}

	return (ret);
}

/* ---------------------------------------------------------------------
   mm_hash_remove

   Removes an element from a hash.
   For internal use only.
   ---------------------------------------------------------------------
*/

void mm_hash_remove(mm_hash *hash, void *key)
{
	mm_hash_elt *elt, *prev;
	unsigned int idx;

	MM_HASH(idx, key, strlen(key));

	for (elt = hash->hashtab[idx], prev = NULL; elt != NULL;
	     prev = elt, elt = elt->next)

		if (strcmp(key, elt->key) == 0) {

			if (prev == NULL) {
				hash->hashtab[idx] = elt->next;
			} else {
				prev->next = elt->next;
			}

			mm_free(hash->mm, elt->val);
			mm_free(hash->mm, elt->key);
			mm_free(hash->mm, elt);
			break;
		}

	return;
}

/* ---------------------------------------------------------------------
   mm_hash_insert

   Inserts an element into a hash.
   ---------------------------------------------------------------------
*/

int mm_hash_insert(mm_hash *hash, char *key, SV *val)
{
	mm_hash_elt *elt;
	unsigned int idx;
	void *data;

	elt = mm_calloc(hash->mm, 1, sizeof(mm_hash_elt));
	if (!elt)
		return(0);

	elt->key = mm_strdup(hash->mm, key);
	if (!elt->key) {
		mm_free(hash->mm, elt);
		return(0);
	}

	data = SvPV(val, elt->val_len);
	/* elt->val = mm_strdup(hash->mm, data); */
	elt->val = mm_malloc(hash->mm, elt->val_len);
	if (!elt->val) {
		mm_free(hash->mm, elt->key);
		mm_free(hash->mm, elt);
		return(0);
	}
	memcpy(elt->val, data, elt->val_len);


	if (mm_lock(hash->mm, MM_LOCK_RW)) {

		mm_hash_remove(hash, key);

		MM_HASH(idx, key, strlen(key));
		elt->next = hash->hashtab[idx];
		hash->hashtab[idx] = elt;
		mm_unlock(hash->mm);
	}

	return(1);
}

/* ---------------------------------------------------------------------
   mm_hash_delete

   Deletes an element from a hash.
   ---------------------------------------------------------------------
*/

SV *mm_hash_delete(mm_hash *hash, char *key)
{
	SV *ret = &PL_sv_undef;

	if (mm_lock(hash->mm, MM_LOCK_RW)) {
		mm_hash_remove(hash, key);
		mm_unlock(hash->mm);
	}
	return(ret); /* XXX */
}

/* ---------------------------------------------------------------------
   mm_hash_clear

   Deletes all elements in a hash.
   ---------------------------------------------------------------------
*/

void mm_hash_clear(mm_hash *hash)
{
	mm_hash_elt *elt, *elt_next;
	unsigned int idx;

	if (mm_lock(hash->mm, MM_LOCK_RW)) {

		for (idx = 0; idx < HASHSIZE; idx++) {

			for (elt = hash->hashtab[idx]; elt != NULL;
			     elt = elt_next) {

				elt_next = elt->next;
				mm_free(hash->mm, elt->val);
				mm_free(hash->mm, elt->key);
				mm_free(hash->mm, elt);
			}

			hash->hashtab[idx] = NULL;
		}

		mm_unlock(hash->mm);
	}
	return;
}

/* ---------------------------------------------------------------------
   mm_hash_first_key

   Returns the first key in a hash.
   ---------------------------------------------------------------------
*/

SV *mm_hash_first_key(mm_hash *hash)
{
	SV *ret = &PL_sv_undef;
	unsigned int idx;

	if (mm_lock(hash->mm, MM_LOCK_RD)) {

		for (idx = 0; idx < HASHSIZE; idx++)

			if (hash->hashtab[idx] != NULL) {
				ret = newSVpv(hash->hashtab[idx]->key, 0);
				break;
			}

		mm_unlock(hash->mm);
	}
	return(ret);
}

/* ---------------------------------------------------------------------
   mm_hash_next_key

   Returns next key in a hash.
   ---------------------------------------------------------------------
*/

SV *mm_hash_next_key(mm_hash *hash, char *key)
{
	mm_hash_elt *elt;
	unsigned int idx;
	int found;

	SV *ret = &PL_sv_undef;

	if (mm_lock(hash->mm, MM_LOCK_RD)) {

		MM_HASH(idx, key, strlen(key));

		found = 0;
		for (; idx < HASHSIZE; idx++) {

			for (elt = hash->hashtab[idx]; elt != NULL;
			     elt = elt->next) {

				if (found) {
					ret = newSVpv(elt->key, 0);
					break;
				} else if (strcmp(key, elt->key) == 0) {

					if (elt->next != NULL) {
						ret = newSVpv(elt->next->key, 0);
						break;
					}
					found = 1;
				}
			}

			if (ret != &PL_sv_undef)
				break;
		}

		mm_unlock(hash->mm);
	}

	return(ret);
}

/* ---------------------------------------------------------------------
   mm_free_hash

   Frees all the memory used by the hash.
   ---------------------------------------------------------------------
*/

void mm_free_hash(mm_hash *hash)
{
	mm_hash_clear(hash);
	mm_free(hash->mm, hash);
}



MODULE = IPC::MM		PACKAGE = IPC::MM		


double
constant(name,arg)
	char *		name
	int		arg


MM *
mm_create(size, file)
	size_t size
	char *file

int
mm_permission(mm, mode, owner, group)
	MM *mm
	int mode
	int owner
	int group

void
mm_destroy(mm)
	MM *mm

mm_scalar *
mm_make_scalar(mm)
	MM *mm

void
mm_free_scalar(scalar)
	mm_scalar *scalar

SV *
mm_scalar_get(scalar)
	mm_scalar *scalar

int
mm_scalar_set(scalar, sv)
	mm_scalar *scalar
	SV *sv

mm_btree *
mm_make_btree_table(mm)
	MM *mm

void
mm_clear_btree_table(btree)
	mm_btree *btree

void
mm_free_btree_table(btree)
	mm_btree *btree

SV *
mm_btree_table_get(btree, key)
	mm_btree *btree
	char *key

int
mm_btree_table_insert(btree, key, val)
	mm_btree *btree
	char *key
	SV *val

SV *
mm_btree_table_delete(btree, key)
	mm_btree *btree
	char *key

SV *
mm_btree_table_exists(btree, key)
	mm_btree *btree
	char *key

SV *
mm_btree_table_first_key(btree)
	mm_btree *btree

SV *
mm_btree_table_next_key(btree, key)
	mm_btree *btree
	char *key

size_t
mm_maxsize()

size_t
mm_available(mm)
	MM *mm

char *
mm_error()

void
mm_display_info(mm)
	MM *mm


mm_hash *
mm_make_hash(mm)
	MM *mm

void
mm_free_hash(hash)
	mm_hash *hash

void
mm_hash_clear(hash)
	mm_hash *hash

SV *
mm_hash_get_value(hash, key)
	mm_hash *hash
	char *key

int
mm_hash_insert(hash, key, val)
	mm_hash *hash
	char *key
	SV *val

SV *
mm_hash_delete(hash, key)
	mm_hash *hash
	char *key

SV *
mm_hash_exists(hash, key)
	mm_hash *hash
	char *key

SV *
mm_hash_first_key(hash)
	mm_hash *hash

SV *
mm_hash_next_key(hash, key)
	mm_hash *hash
	char *key

int
mm_lock(mm, mode)
	MM *mm
	mm_lock_mode mode

int
mm_unlock(mm)
	MM *mm
