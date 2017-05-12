/* based on perl 5.18 pointer table */

#include "smptr_tbl.h"

struct smptr_tbl_arena {
    struct smptr_tbl_arena *next;
    struct smptr_tbl_ent array[1023/3]; /* as ptr_tbl_ent has 3 pointers.  */
};

/* create a new pointer-mapping table */

SMPTR_TBL_t *
smptr_table_new(pTHX)
{
    SMPTR_TBL_t *tbl;
    PERL_UNUSED_CONTEXT;

    Newx(tbl, 1, SMPTR_TBL_t);
    tbl->tbl_max	= 511;
    tbl->tbl_items	= 0;
    tbl->tbl_arena	= NULL;
    tbl->tbl_arena_next	= NULL;
    tbl->tbl_arena_end	= NULL;
    Newxz(tbl->tbl_ary, tbl->tbl_max + 1, SMPTR_TBL_ENT_t*);
    return tbl;
}

#define SMPTR_TABLE_HASH(ptr) \
  ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))

/* map an existing pointer using a table */

STATIC SMPTR_TBL_ENT_t *
smptr_table_find(SMPTR_TBL_t *const tbl, const void *const sv)
{
    SMPTR_TBL_ENT_t *tblent;
    const UV hash = SMPTR_TABLE_HASH(sv);

    tblent = tbl->tbl_ary[hash & tbl->tbl_max];
    for (; tblent; tblent = tblent->next) {
	if (tblent->oldval == sv)
	    return tblent;
    }
    return NULL;
}

void *
smptr_table_fetch(pTHX_ SMPTR_TBL_t *const tbl, const void *const sv)
{
    SMPTR_TBL_ENT_t const *const tblent = smptr_table_find(tbl, sv);

    PERL_UNUSED_CONTEXT;

    return tblent ? tblent->newval : NULL;
}

/* double the hash bucket size of an existing ptr table */

void
smptr_table_split(pTHX_ SMPTR_TBL_t *const tbl)
{
    SMPTR_TBL_ENT_t **ary = tbl->tbl_ary;
    const UV oldsize = tbl->tbl_max + 1;
    UV newsize = oldsize * 2;
    UV i;

    if (tbl->tbl_split_disabled) {
        tbl->tbl_split_needed = TRUE;
        return;
    }
    tbl->tbl_split_needed = FALSE;

    PERL_UNUSED_CONTEXT;

    Renew(ary, newsize, SMPTR_TBL_ENT_t*);
    Zero(&ary[oldsize], newsize-oldsize, SMPTR_TBL_ENT_t*);
    tbl->tbl_max = --newsize;
    tbl->tbl_ary = ary;
    for (i=0; i < oldsize; i++, ary++) {
	SMPTR_TBL_ENT_t **entp = ary;
	SMPTR_TBL_ENT_t *ent = *ary;
	SMPTR_TBL_ENT_t **curentp;
	if (!ent)
	    continue;
	curentp = ary + oldsize;
	do {
	    if ((newsize & SMPTR_TABLE_HASH(ent->oldval)) != i) {
		*entp = ent->next;
		ent->next = *curentp;
		*curentp = ent;
	    }
	    else
		entp = &ent->next;
	    ent = *entp;
	} while (ent);
    }
}

/* add a new entry to a pointer-mapping table */

void
smptr_table_store(pTHX_ SMPTR_TBL_t *const tbl, const void *const oldsv, void *const newsv)
{
    SMPTR_TBL_ENT_t *tblent = smptr_table_find(tbl, oldsv);

    PERL_UNUSED_CONTEXT;

    if (tblent) {
	tblent->newval = newsv;
    } else {
	const UV entry = SMPTR_TABLE_HASH(oldsv) & tbl->tbl_max;

	if (tbl->tbl_arena_next == tbl->tbl_arena_end) {
	    struct smptr_tbl_arena *new_arena;

	    Newx(new_arena, 1, struct smptr_tbl_arena);
	    new_arena->next = tbl->tbl_arena;
	    tbl->tbl_arena = new_arena;
	    tbl->tbl_arena_next = new_arena->array;
	    tbl->tbl_arena_end = new_arena->array
		+ sizeof(new_arena->array) / sizeof(new_arena->array[0]);
	}

	tblent = tbl->tbl_arena_next++;

	tblent->oldval = oldsv;
	tblent->newval = newsv;
	tblent->next = tbl->tbl_ary[entry];
	tbl->tbl_ary[entry] = tblent;
	tbl->tbl_items++;
	if (tblent->next && tbl->tbl_items > tbl->tbl_max)
            smptr_table_split(aTHX_ tbl);
    }
}

/* remove all the entries from a ptr table */
/* Deprecated - will be removed post 5.14 */

void
smptr_table_clear(pTHX_ SMPTR_TBL_t *const tbl)
{
    if (tbl && tbl->tbl_items) {
	struct smptr_tbl_arena *arena = tbl->tbl_arena;

	Zero(tbl->tbl_ary, tbl->tbl_max + 1, struct smptr_tbl_ent **);

	while (arena) {
	    struct smptr_tbl_arena *next = arena->next;

	    Safefree(arena);
	    arena = next;
	};

	tbl->tbl_items = 0;
	tbl->tbl_arena = NULL;
	tbl->tbl_arena_next = NULL;
	tbl->tbl_arena_end = NULL;
    }
}

/* clear and free a ptr table */

void
smptr_table_free(pTHX_ SMPTR_TBL_t *const tbl)
{
    struct smptr_tbl_arena *arena;

    if (!tbl) {
        return;
    }

    arena = tbl->tbl_arena;

    while (arena) {
	struct smptr_tbl_arena *next = arena->next;

	Safefree(arena);
	arena = next;
    }

    Safefree(tbl->tbl_ary);
    Safefree(tbl);
}
