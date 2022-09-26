/* vi: set ft=c : */

#define padname_is_normal_lexical(pname)  MY_padname_is_normal_lexical(aTHX_ pname)
static bool MY_padname_is_normal_lexical(pTHX_ PADNAME *pname)
{
  /* PAD slots without names are certainly not lexicals */
  if(PadnameIsNULL(pname) || !PadnameLEN(pname))
    return FALSE;

  /* Outer lexical captures are not lexicals */
  if(PadnameOUTER(pname))
    return FALSE;

  /* state variables are not lexicals */
  if(PadnameIsSTATE(pname))
    return FALSE;

  /* Protosubs for closures are not lexicals */
  if(PadnamePV(pname)[0] == '&')
    return FALSE;

  /* anything left is a normal lexical */
  return TRUE;
}

enum {
  CV_COPY_NULL_LEXICALS = (1<<0), /* regular lexicals end up NULL */
};

#define cv_copy_flags(orig, flags)  MY_cv_copy_flags(aTHX_ orig, flags)
static CV *MY_cv_copy_flags(pTHX_ CV *orig, U32 flags)
{
  /* Parts of this code stolen from S_cv_clone() in pad.c
   */
  CV *new = MUTABLE_CV(newSV_type(SVt_PVCV));
  CvFLAGS(new) = CvFLAGS(orig) & ~CVf_CVGV_RC;

  CvFILE(new) = CvDYNFILE(orig) ? savepv(CvFILE(orig)) : CvFILE(orig);
#if HAVE_PERL_VERSION(5, 18, 0)
  if(CvNAMED(orig)) {
    /* Perl core uses CvNAME_HEK_set() here, but that involves a call to a
     * non-public function unshare_hek(). The latter is only needed in the
     * case where an old value needs to be removed, but since we've only just
     * created the CV we know it will be empty, so we can just set the field
     * directly
     */
    ((XPVCV*)MUTABLE_PTR(SvANY(new)))->xcv_gv_u.xcv_hek = share_hek_hek(CvNAME_HEK(orig));
    CvNAMED_on(new);
  }
  else
#endif
    CvGV_set(new, CvGV(orig));

  CvSTASH_set(new, CvSTASH(orig));
  {
    OP_REFCNT_LOCK;
    CvROOT(new) = OpREFCNT_inc(CvROOT(orig));
    OP_REFCNT_UNLOCK;
  }
  CvSTART(new) = CvSTART(orig);
  CvOUTSIDE(new) = MUTABLE_CV(SvREFCNT_inc(CvOUTSIDE(orig)));
  CvOUTSIDE_SEQ(new) = CvOUTSIDE_SEQ(orig);

  /* No need to bother with SvPV slot because that's the prototype, and it's
   * too late for that here
   */
  /* TODO: Consider what to do about SvPVX */

  {
    ENTER_with_name("cv_copy_flags");

    SAVESPTR(PL_compcv);
    PL_compcv = new;

    SAVESPTR(PL_comppad_name);
    PL_comppad_name = PadlistNAMES(CvPADLIST(orig));
    CvPADLIST_set(new, pad_new(padnew_CLONE|padnew_SAVE));
#if HAVE_PERL_VERSION(5, 22, 0)
    CvPADLIST(new)->xpadl_id = CvPADLIST(orig)->xpadl_id;
#endif

    PADNAMELIST *padnames = PadlistNAMES(CvPADLIST(orig));
    const PADOFFSET fnames = PadnamelistMAX(padnames);
    const PADOFFSET fpad = AvFILLp(PadlistARRAY(CvPADLIST(orig))[1]);
    int depth = CvDEPTH(orig);
    if(!depth)
      depth = 1;
    SV **origpad = AvARRAY(PadlistARRAY(CvPADLIST(orig))[depth]);

#if !HAVE_PERL_VERSION(5, 18, 0)
    /* Perls before 5.18.0 didn't copy the padnameslist
     */
    SvREFCNT_dec(PadlistNAMES(CvPADLIST(new)));
    PadlistNAMES(CvPADLIST(new)) = (PADNAMELIST *)SvREFCNT_inc(PadlistNAMES(CvPADLIST(orig)));
#endif

    av_fill(PL_comppad, fpad);
    PL_curpad = AvARRAY(PL_comppad);

    PADNAME **pnames = PadnamelistARRAY(padnames);
    PADOFFSET padix;

    /* TODO: What about padix 0? */

    for(padix = 1; padix <= fpad; padix++) {
      PADNAME *pname = (padix <= fnames) ? pnames[padix] : NULL;
      SV *newval = NULL;

      if(padname_is_normal_lexical(pname)) {
        if(flags & CV_COPY_NULL_LEXICALS)
          continue;

        switch(PadnamePV(pname)[0]) {
          case '$': newval = newSV(0); break;
          case '@': newval = MUTABLE_SV(newAV()); break;
          case '%': newval = MUTABLE_SV(newHV()); break;
          default:
            croak("ARGH unsure how to handle pname=<%s> in cv_copy_flags\n",
              PadnamePV(pname));
            break;
        }
      }
      else if(!origpad[padix])
        newval = NULL;
      else if(SvPADTMP(origpad[padix])) {
        /* We still have to copy the value, in case it is live. Also core perl
        * is known to set SvPADTMP on non-temporaries, like folded constants
        *   https://rt.cpan.org/Ticket/Display.html?id=142468
        */
        newval = newSVsv(origpad[padix]);
        SvPADTMP_on(newval);
      }
      else {
#if !HAVE_PERL_VERSION(5, 18, 0)
        /* Before perl 5.18.0, inner anon subs didn't find the right CvOUTSIDE
         * at runtime, so we'll have to patch them up here
         */
        CV *origproto;
        if(pname && PadnamePV(pname)[0] == '&' && 
           CvOUTSIDE(origproto = MUTABLE_CV(origpad[padix])) == orig) {
          /* quiet any "Variable $FOO is not available" warnings about lexicals
           * yet to be introduced
           */
          ENTER_with_name("find_cv_outside");
          SAVEINT(CvDEPTH(origproto));
          CvDEPTH(origproto) = 1;

          CV *newproto = cv_copy_flags(origproto, flags);
          CvPADLIST_set(newproto, CvPADLIST(origproto));
          CvSTART(newproto) = CvSTART(origproto);

          SvREFCNT_dec(CvOUTSIDE(newproto));
          CvOUTSIDE(newproto) = MUTABLE_CV(SvREFCNT_inc_simple_NN(new));

          LEAVE_with_name("find_cv_outside");

          newval = MUTABLE_SV(newproto);
        }
        else
#endif
        if(origpad[padix])
          newval = SvREFCNT_inc_NN(origpad[padix]);
      }

      PL_curpad[padix] = newval;
    }

    LEAVE_with_name("cv_copy_flags");
  }

  return new;
}
