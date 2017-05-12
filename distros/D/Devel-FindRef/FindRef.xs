#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_ATLEAST(a,b,c)                             \
  (PERL_REVISION > (a)                                          \
   || (PERL_REVISION == (a)                                     \
       && (PERL_VERSION > (b)                                   \
           || (PERL_VERSION == (b) && PERLSUBVERSION >= (c)))))

#if !PERL_VERSION_ATLEAST (5,8,9)
# define SVt_LAST 16
#endif

#if !PERL_VERSION_ATLEAST (5,10,0)
# define SvPAD_OUR(dummy) 0
#endif

/* pre-5.10 perls always succeed, with 5.10, we have to check first apparently */
#ifndef GvNAME_HEK
# define GvNAME_HEK(sv) 1
#endif

#ifndef PadARRAY
# define PadARRAY(pad)    AvARRAY (pad)
# define PadlistARRAY(pl) ((PAD **)AvARRAY (pl))
#endif


#define res_pair(text)						\
  do {								\
    AV *av = newAV ();						\
    av_push (av, newSVpv (text, 0));				\
    if (rmagical) SvRMAGICAL_on (sv);				\
    av_push (av, sv_rvweaken (newRV_inc (sv)));			\
    if (rmagical) SvRMAGICAL_off (sv);				\
    av_push (about, newRV_noinc ((SV *)av));			\
  } while (0)

#define res_text(text)						\
  do {								\
    AV *av = newAV ();						\
    av_push (av, newSVpv (text, 0));				\
    av_push (about, newRV_noinc ((SV *)av));			\
  } while (0)

#define res_gv(sigil)						\
  res_text (form ("the global %c%s::%.*s", sigil,		\
                  HvNAME (GvSTASH (sv)),			\
                  GvNAME_HEK (sv) ? GvNAMELEN (sv) : 11,	\
                  GvNAME_HEK (sv) ? GvNAME    (sv) : "<anonymous>"))

MODULE = Devel::FindRef		PACKAGE = Devel::FindRef		

PROTOTYPES: ENABLE

void
find_ (SV *target_ref)
	PPCODE:
{
  	SV *arena, *targ;
        U32 rmagical;
        int i;
        AV *about = newAV ();
        AV *excl  = newAV ();

  	if (!SvROK (target_ref))
          croak ("find expects a reference to a perl value");

        targ = SvRV (target_ref);

        if (SvIMMORTAL (targ))
          {
            if (targ == &PL_sv_undef)
              res_text ("the immortal 'undef' value");
            else if (targ == &PL_sv_yes)
              res_text ("the immortal 'yes' value");
            else if (targ == &PL_sv_no)
              res_text ("the immortal 'no' value");
            else if (targ == &PL_sv_placeholder)
              res_text ("the immortal placeholder value");
            else
              res_text ("some unknown immortal");
          }
        else
          {
	    for (arena = PL_sv_arenaroot; arena; arena = SvANY (arena))
              {
                UV idx = SvREFCNT (arena);

                /* Remember that the zeroth slot is used as the pointer onwards, so don't
                   include it. */
                while (--idx > 0)
                  {
                    SV *sv = &arena [idx];

                    if (SvTYPE (sv) >= SVt_LAST)
                      continue;

                    /* temporarily disable RMAGICAL, it can easily interfere with us */
                    if ((rmagical = SvRMAGICAL (sv)))
                      SvRMAGICAL_off (sv);

                    if (SvTYPE (sv) >= SVt_PVMG)
                      {
                        if (SvTYPE (sv) == SVt_PVMG && SvPAD_OUR (sv))
                          {
                            /* I have no clue what this is */
                            /* maybe some placeholder for our variables for eval? */
                            /* it doesn't seem to reference anything, so we should be able to ignore it */
                          }
                        else if (SvMAGICAL (sv)) /* name-pads use SvMAGIC for other purposes */
                          {
                            MAGIC *mg = SvMAGIC (sv);

                            while (mg)
                              {
                                if (mg->mg_obj == targ && mg->mg_flags & MGf_REFCOUNTED)
                                  res_pair (form ("referenced (in mg_obj) by '%c' type magic attached to", mg->mg_type));

                                if ((SV *)mg->mg_ptr == targ)
                                  res_pair (form ("%sreferenced (in mg_ptr) by '%c' type magic attached to",
                                                  mg->mg_len == HEf_SVKEY ? "" : "possibly ",
                                                  mg->mg_type));

                                mg = mg->mg_moremagic;
                              }
                          }
                      }

                    if (SvROK (sv))
                      {
                        if (SvRV (sv) == targ && !SvWEAKREF (sv) && sv != target_ref)
                          res_pair ("referenced by");
                      }
                    else
                      switch (SvTYPE (sv))
                        {
                          case SVt_PVAV:
                            if (AvREAL (sv))
                              for (i = AvFILLp (sv) + 1; i--; )
                                if (AvARRAY (sv)[i] == targ)
                                  res_pair (form ("the array element %d of", i));

                            break;

                          case SVt_PVHV:
                            if (hv_iterinit ((HV *)sv))
                              {
                                HE *he;

                                while ((he = hv_iternext ((HV *)sv)))
                                  if (HeVAL (he) == targ)
                                    res_pair (form ("the hash member '%.*s' of", HeKLEN (he), HeKEY (he)));
                              }

                            break;

                          case SVt_PVCV:
                            {
                              PADLIST *padlist = CvPADLIST (sv);

                              if (padlist)
                                {
                                  int depth = CvDEPTH (sv);

                                /* Anonymous subs have a padlist but zero depth */
                                /* some hacks switch CvANON off, so we just blindly assume a minimum of 1 */
                                  if (!depth)
                                    depth = 1;

                                  while (depth)
                                    {
                                      PAD *pad = PadlistARRAY (padlist)[depth];

                                      av_push (excl, newSVuv (PTR2UV (pad))); /* exclude pads themselves from being found */

                                      /* The 0th pad slot is @_ */
                                      if (PadARRAY (pad)[0] == targ)
                                        res_pair ("the argument array for");

                                      for (i = AvFILLp (pad) + 1; --i; )
                                        if (AvARRAY (pad)[i] == targ)
                                          {
                                            /* Values from constant functions are stored in the pad without any name */
                                            SV *name_sv = PadARRAY (PadlistARRAY (padlist)[0])[i];

                                            if (name_sv && SvPOK (name_sv))
                                              res_pair (form ("the lexical '%s' in", SvPVX (name_sv)));
                                            else
                                              res_pair ("an unnamed lexical in");
                                          }

                                      --depth;
                                    }
                                }

                              if (CvCONST (sv) && (SV*)CvXSUBANY (sv).any_ptr == targ)
                                res_pair ("the constant value of");

                              if (!CvWEAKOUTSIDE (sv) && (SV*)CvOUTSIDE (sv) == targ)
                                res_pair ("the containing scope for");

                              if (sv == targ && CvANON (sv))
                                if (CvSTART (sv)
                                    && CvSTART (sv)->op_type == OP_NEXTSTATE
                                    && CopLINE ((COP *)CvSTART (sv)))
                                  res_text (form ("the closure created at %s:%d",
                                                  CopFILE ((COP *)CvSTART (sv)) ? CopFILE ((COP *)CvSTART (sv)) : "<unknown>",
                                                  CopLINE ((COP *)CvSTART (sv))));
                                else
                                  res_text (form ("the closure created somewhere in file %s (PLEASE REPORT!)",
                                                  CvFILE (sv) ? CvFILE (sv) : "<unknown>"));
                            }

                            break;

                          case SVt_PVGV:
                            if (GvGP (sv))
                              {
                                if (GvSV (sv) == (SV *)targ) res_gv ('$');
                                if (GvAV (sv) == (AV *)targ) res_gv ('@');
                                if (GvHV (sv) == (HV *)targ) res_gv ('%');
                                if (GvCV (sv) == (CV *)targ) res_gv ('&');
                              }

                            break;

                          case SVt_PVLV:
                            if (LvTARG (sv) == targ)
                              {
                                if (LvTYPE (sv) == 'y')
                                  {
                                    MAGIC *mg = mg_find (sv, PERL_MAGIC_defelem);

                                    if (mg && mg->mg_obj)
                                      res_pair (form ("the target for the lvalue hash element '%.*s',",
                                                      (int)SvCUR (mg->mg_obj), SvPV_nolen (mg->mg_obj)));
                                    else
                                      res_pair (form ("the target for the lvalue array element #%d,", LvTARGOFF (sv)));
                                  }
                                else
                                  res_pair (form ("an lvalue reference target (type '%c', ofs %d, len %d),",
                                                  LvTYPE (sv), LvTARGOFF (sv), LvTARGLEN (sv)));
                              }

                            break;
                        }

                    if (rmagical)
                      SvRMAGICAL_on (sv);
                  }
              }

            /* look at the mortalise stack of the current coroutine */
            for (i = 0; i <= PL_tmps_ix; ++i)
              if (PL_tmps_stack [i] == targ)
                res_text ("a temporary on the stack");

            if (targ == (SV*)PL_main_cv)
              res_text ("the main body of the program");
          }

        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newRV_noinc ((SV *)about)));
        PUSHs (sv_2mortal (newRV_noinc ((SV *)excl)));
}

SV *
ptr2ref (UV ptr)
	CODE:
        RETVAL = newRV_inc (INT2PTR (SV *, ptr));
	OUTPUT:
        RETVAL

UV
ref2ptr (SV *rv)
	CODE:
        if (!SvROK (rv))
	  croak ("argument to Devel::FindRef::ref2ptr must be a reference");
        RETVAL = PTR2UV (SvRV (rv));
	OUTPUT:
        RETVAL

U32
_refcnt (SV *rv)
	CODE:
        if (!SvROK (rv))
	  croak ("argument to Devel::FindRef::_refcnt must be a reference");
        RETVAL = SvREFCNT (SvRV (rv));
	OUTPUT:
        RETVAL
