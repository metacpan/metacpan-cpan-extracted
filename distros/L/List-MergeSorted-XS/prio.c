#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "prio.h"

lmsxs_prio_ent*
lmsxs_make_ent(SV* sv, IV list_num, IV list_idx)
{
    lmsxs_prio_ent* ent;
    Newxz(ent, 1, lmsxs_prio_ent);
    ent->sv = sv;
    ent->list_num = list_num;
    ent->list_idx = list_idx;
    return ent;
}

void
lmsxs_free_ent(lmsxs_prio_ent* ent)
{
    Safefree(ent);
}
