/* vi: set ft=c inde=: */

#ifndef save_clearpadrange

#define save_clearpadrange(padix, count)  S_save_clearpadrange(aTHX_ padix, count)

static void S_save_clearpadrange(pTHX_ PADOFFSET padix, U32 count)
{
  /* Code stolen from PP(pp_padrange) in pp_hot.c */
  const UV payload = (UV)(
                (padix << (OPpPADRANGE_COUNTSHIFT + SAVE_TIGHT_SHIFT))
              | (count << SAVE_TIGHT_SHIFT)
              | SAVEt_CLEARPADRANGE);
  dSS_ADD;
  SS_ADD_UV(payload);
  SS_ADD_END(1);
}

#endif
