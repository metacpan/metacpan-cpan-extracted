#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "list.h"

lmsxs_ll_ent*
lmsxs_ll_make_ent(IV key, SV* sv, IV list_num, IV list_idx)
{
    lmsxs_ll_ent* ent;
    Newxz(ent, 1, lmsxs_ll_ent);
    ent->key = key;
    ent->sv = sv;
    ent->list_num = list_num;
    ent->list_idx = list_idx;
    ent->next = NULL;
    return ent;
}

void
lmsxs_ll_free_ent(lmsxs_ll_ent* ent)
{
    Safefree(ent);
}

void
lmsxs_ll_insert_ent(lmsxs_ll_ent** list, lmsxs_ll_ent* new_ent)
{
    lmsxs_ll_ent* cur;
    lmsxs_ll_ent** ptr_to_cur;

    if (!*list) {
        /* list is empty */
        *list = new_ent;
        return;
    }

    for (
        ptr_to_cur = list, cur = *list;
        cur;
        ptr_to_cur = &((*ptr_to_cur)->next), cur = cur->next
    ) {
        if (new_ent->key < cur->key) {
            new_ent->next = cur;
            *ptr_to_cur = new_ent;
            return;
        }
    }

    /* insert at end */
    *ptr_to_cur = new_ent;
}

lmsxs_ll_ent*
lmsxs_ll_pop_ent(lmsxs_ll_ent** list)
{
    lmsxs_ll_ent* first = *list;
    if (!first)
        return NULL;
    *list = first->next;
    first->next = NULL;
    return first;
}
