/* entry in the linked-list implementation of a priority q */

typedef struct _lmsxs_ll_ent {
    SV* sv;       /* the source of this entry */
    IV  list_num; /* index of the list that this value came from */
    IV  list_idx; /* index into that list for the element this value came from */
    IV  key;
    struct _lmsxs_ll_ent* next;
} lmsxs_ll_ent;

lmsxs_ll_ent* lmsxs_ll_make_ent(IV key, SV* sv, IV list_num, IV list_idx);
void lmsxs_ll_free_ent(lmsxs_ll_ent* ent);
void lmsxs_ll_insert_ent(lmsxs_ll_ent** list, lmsxs_ll_ent* new_ent);
lmsxs_ll_ent* lmsxs_ll_pop_ent(lmsxs_ll_ent** list);
