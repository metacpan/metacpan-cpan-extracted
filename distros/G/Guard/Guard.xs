#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "patchlevel.h"

#define PERL_VERSION_ATLEAST(a,b,c)                             \
  (PERL_REVISION > (a)                                          \
   || (PERL_REVISION == (a)                                     \
       && (PERL_VERSION > (b)                                   \
           || (PERL_VERSION == (b) && PERL_SUBVERSION >= (c)))))

/* apparently < 5.8.8 */
#ifndef SvSTASH_set
# define SvSTASH_set(x,a) SvSTASH(x) = (a)
#endif

#ifndef PERL_MAGIC_ext
# define PERL_MAGIC_ext '~'
#endif

static HV *guard_stash;

static SV *
guard_get_cv (pTHX_ SV *cb_sv)
{
  HV *st;
  GV *gvp;
  CV *cv = sv_2cv (cb_sv, &st, &gvp, 0);

  if (!cv)
    croak ("expected a CODE reference for guard");

  return (SV *)cv;
}

static void
exec_guard_cb (pTHX_ SV *cb)
{
  dSP;
  SV *saveerr = SvOK (ERRSV) ? sv_mortalcopy (ERRSV) : 0;
  SV *savedie = PL_diehook;

  PL_diehook = 0;

  PUSHSTACKi (PERLSI_DESTROY);

  PUSHMARK (SP);
  PUTBACK;
  call_sv (cb, G_VOID | G_DISCARD | G_EVAL);

  if (SvTRUE (ERRSV))
    {
      SPAGAIN;

      PUSHMARK (SP);
      PUTBACK;
      call_sv (get_sv ("Guard::DIED", 1), G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);

      sv_setpvn (ERRSV, "", 0);
    }

  if (saveerr)
    sv_setsv (ERRSV, saveerr);

  {
    SV *oldhook = PL_diehook;
    PL_diehook = savedie;
    SvREFCNT_dec (oldhook);
  }

  POPSTACK;
}

static void
scope_guard_cb (pTHX_ void *cv)
{
  exec_guard_cb (aTHX_ sv_2mortal ((SV *)cv));
}

static int
guard_free (pTHX_ SV *cv, MAGIC *mg)
{
  exec_guard_cb (aTHX_ mg->mg_obj);

  return 0;
}

static MGVTBL guard_vtbl = {
  0, 0, 0, 0,
  guard_free
};

MODULE = Guard		PACKAGE = Guard

BOOT:
	guard_stash = gv_stashpv ("Guard", 1);
        CvNODEBUG_on (get_cv ("Guard::scope_guard", 0)); /* otherwise calling scope can be the debugger */

void
scope_guard (SV *block)
	PROTOTYPE: &
        CODE:
        LEAVE; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */
        SAVEDESTRUCTOR_X (scope_guard_cb, (void *)SvREFCNT_inc (guard_get_cv (aTHX_ block)));
        ENTER; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */

SV *
guard (SV *block)
	PROTOTYPE: &
        CODE:
{
	SV *cv = guard_get_cv (aTHX_ block);
        SV *guard = NEWSV (0, 0);
        SvUPGRADE (guard, SVt_PVMG);
        sv_magicext (guard, cv, PERL_MAGIC_ext, &guard_vtbl, 0, 0);
        RETVAL = newRV_noinc (guard);
        SvOBJECT_on (guard);
#if !PERL_VERSION_ATLEAST(5,18,0)
        ++PL_sv_objcount;
#endif
        SvSTASH_set (guard, (HV*)SvREFCNT_inc ((SV *)guard_stash));
}
	OUTPUT:
        RETVAL

void
cancel (SV *guard)
	PROTOTYPE: $
        CODE:
{
  	MAGIC *mg;
        if (!SvROK (guard)
            || !(mg = mg_find (SvRV (guard), PERL_MAGIC_ext))
            || mg->mg_virtual != &guard_vtbl)
          croak ("Guard::cancel called on a non-guard object");

        SvREFCNT_dec (mg->mg_obj);
        mg->mg_obj     = 0;
        mg->mg_virtual = 0;
}
