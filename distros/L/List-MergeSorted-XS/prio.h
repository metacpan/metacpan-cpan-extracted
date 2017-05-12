/* entry in a priority queue */

typedef struct _lmsxs_prio_ent {
    SV* sv;       /* the source of this entry */
    IV  list_num; /* index of the list that this value came from */
    IV  list_idx; /* index into that list for the element this value came from */
} lmsxs_prio_ent;

lmsxs_prio_ent* lmsxs_make_ent(SV* sv, IV list_num, IV list_idx);
void lmsxs_free_ent(lmsxs_prio_ent* ent);
