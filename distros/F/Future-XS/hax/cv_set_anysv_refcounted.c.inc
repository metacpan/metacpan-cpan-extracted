/* vi: set ft=c : */

#if HAVE_PERL_VERSION(5, 26, 0)
#  define XSANY_sv                  XSANY.any_sv
#  define CvXSUBANY_sv(cv)          CvXSUBANY(cv).any_sv
#  define CvXSUBANY_sv_set(cv, sv)  (CvXSUBANY(cv).any_sv = (sv))
#else
   /* Older perls did not have a .any_sv; we'll just cast the .any_ptr pointer */
#  define XSANY_sv          ((SV *)XSANY.any_ptr)
#  define CvXSUBANY_sv(cv)  ((SV *)CvXSUBANY(cv).any_ptr)
#  define CvXSUBANY_sv_set(cv, sv)  (CvXSUBANY(cv).any_ptr = (sv))
#endif

static int free_anysv_refcounted(pTHX_ SV *sv, MAGIC *mg)
{
  SvREFCNT_dec(CvXSUBANY_sv((CV *)sv));
  return 0;
}

static MGVTBL vtbl_anysv_refcounted = {
  .svt_free = &free_anysv_refcounted,
};

#define cv_set_anysv_refcounted(cv, sv)  S_cv_set_anysv_refcounted(aTHX_ cv, sv)
static void S_cv_set_anysv_refcounted(pTHX_ CV *cv, SV *sv)
{
  CvXSUBANY_sv_set(cv, sv);

  sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &vtbl_anysv_refcounted, NULL, 0);
}
