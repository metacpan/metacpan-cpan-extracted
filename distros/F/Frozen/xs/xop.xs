MODULE = Frozen    PACKAGE = Frozen    PREFIX = fzx_

void
fzx__xop_stats(...)
    PPCODE:
        EXTEND(SP, 3);
        mPUSHi(fz_xop_hook);
        mPUSHi(fz_xop_hits);
        mPUSHi(fz_xop_miss);

void
fzx__xop_reset(...)
    CODE:
        fz_xop_hits = fz_xop_miss = 0;

MODULE = Frozen    PACKAGE = Frozen

BOOT:
{
    fz_stash   = gv_stashpv("Frozen", GV_ADD);
    fz_cv_get  = get_cv("Frozen::get",  0);
    fz_cv_find = get_cv("Frozen::find", 0);
    fz_cv_root = get_cv("Frozen::root", 0);
    fz_cv_fetch  = get_cv("Frozen::fetch",  0);
    fz_cv_child  = get_cv("Frozen::child",  0);
    fz_cv_exists = get_cv("Frozen::exists", 0);
    fz_cv_at     = get_cv("Frozen::at",     0);
    fz_cv_count  = get_cv("Frozen::count",  0);
    fz_cv_value  = get_cv("Frozen::value",  0);
    fz_cv_kind   = get_cv("Frozen::kind",   0);

    if (PL_check[OP_ENTERSUB] != fz_ck_entersub) {
        fz_prev_ck_entersub  = PL_check[OP_ENTERSUB];
        PL_check[OP_ENTERSUB] = fz_ck_entersub;
    }
}
