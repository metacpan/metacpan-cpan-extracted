#ifndef __FUTURE_ASYNCAWAIT_H__
#define __FUTURE_ASYNCAWAIT_H__

#include "perl.h"

#define FUTURE_ASYNCAWAIT_ABI_VERSION 2

/*
 * The API contained in this file is even more experimental than the rest of
 * Future::AsyncAwait. It is primarily designed to allow suspend-aware dynamic
 * variables in Syntax::Keyword::Dynamically, but may be useful for other
 * tasks.
 *
 * There are no unit tests for these hooks inside this distribution, as testing
 * it would require more XS code. It is tested as a side-effect of the
 * integration with Syntax::Keyword::Dynamically.
 */

struct AsyncAwaitHookFuncs
{
  U32 flags;  /* currently unused but reserve the ABI space just in case */
  void (*post_cv_copy)(pTHX_ CV *runcv, CV *cv, HV *modhookdata, void *hookdata);
  void (*pre_suspend) (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  void (*post_suspend)(pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  void (*pre_resume)  (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  void (*post_resume) (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  void (*free)        (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
};

static void (*register_future_asyncawait_hook_func)(pTHX_ const struct AsyncAwaitHookFuncs *hookfuncs, void *hookdata);
#define register_future_asyncawait_hook(hookfuncs, hookdata) S_register_future_asyncawait_hook(aTHX_ hookfuncs, hookdata)
static void S_register_future_asyncawait_hook(pTHX_ const struct AsyncAwaitHookFuncs *hookfuncs, void *hookdata)
{
  if(!register_future_asyncawait_hook_func)
    croak("Must call boot_future_asyncawait() first");

  (*register_future_asyncawait_hook_func)(aTHX_ hookfuncs, hookdata);
}

#define future_asyncawait_on_activate(func, data) S_future_asyncawait_on_activate(aTHX_ func, data)
static void S_future_asyncawait_on_activate(pTHX_ void (*func)(pTHX_ void *data), void *data)
{
  SV **svp;

  if((svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/loaded", FALSE)) && SvOK(*svp)) {
    (*func)(aTHX_ data);
  }
  else {
    AV *av;

    svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/on_loaded", FALSE);
    if(svp)
      av = (AV *)*svp;
    else {
      av = newAV();
      hv_stores(PL_modglobal, "Future::AsyncAwait/on_loaded", (SV *)av);
    }

    av_push(av, newSVuv(PTR2UV(func)));
    av_push(av, newSVuv(PTR2UV(data)));
  }
}

/* flags constants for future_asyncawait_get_modhookdata() */
enum {
  FAA_MODHOOK_CREATE = (1<<0),
};

static HV *(*future_asyncawait_get_modhookdata_func)(pTHX_ CV *cv, U32 flags, PADOFFSET precreate_padix);
#define future_asyncawait_get_modhookdata(cv, flags, precreate_padix)  \
    S_future_asyncawait_get_modhookdata(aTHX_ cv, flags, precreate_padix)
static HV *S_future_asyncawait_get_modhookdata(pTHX_ CV *cv, U32 flags, PADOFFSET precreate_padix)
{
  if(!future_asyncawait_get_modhookdata_func)
    croak("Must call boot_future_asyncawait() first");

  return (*future_asyncawait_get_modhookdata_func)(aTHX_ cv, flags, precreate_padix);
}

static PADOFFSET (*future_asyncawait_make_precreate_padix_func)(pTHX);
#define future_asyncawait_make_precreate_padix()  S_future_asyncawait_make_precreate_padix(aTHX)
PADOFFSET S_future_asyncawait_make_precreate_padix(pTHX)
{
  if(!future_asyncawait_make_precreate_padix_func)
    croak("Must call boot_future_asyncawait() first");

  return (*future_asyncawait_make_precreate_padix_func)(aTHX);
}

#define boot_future_asyncawait(ver)  S_boot_future_asyncawait(aTHX_ ver)
static void S_boot_future_asyncawait(pTHX_ double ver)
{
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Future::AsyncAwait"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MIN", 0);
  if(!svp)
    croak("Future::AsyncAwait ABI minimum version missing");
  int abi_ver = SvIV(*svp);
  if(abi_ver > FUTURE_ASYNCAWAIT_ABI_VERSION)
    croak("Future::AsyncAwait ABI version mismatch - library supports >= %d, compiled for %d",
        abi_ver, FUTURE_ASYNCAWAIT_ABI_VERSION);

  svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MAX", 0);
  abi_ver = SvIV(*svp);
  if(abi_ver < FUTURE_ASYNCAWAIT_ABI_VERSION)
    croak("Future::AsyncAwait ABI version mismatch - library supports <= %d, compiled for %d",
        abi_ver, FUTURE_ASYNCAWAIT_ABI_VERSION);

  register_future_asyncawait_hook_func = INT2PTR(void (*)(pTHX_ const struct AsyncAwaitHookFuncs *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/register()@2", 0)));

  future_asyncawait_get_modhookdata_func = INT2PTR(HV *(*)(pTHX_ CV *, U32, PADOFFSET),
      SvUV(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/get_modhookdata()@1", 0)));

  future_asyncawait_make_precreate_padix_func = INT2PTR(PADOFFSET (*)(pTHX),
      SvUV(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/make_precreate_padix()@1", 0)));
}

/**************
 * Legacy API *
 **************/

/*
 * This enum provides values for the `phase` hook parameter.
 */
enum {
  /* PRESUSPEND = 0x10, */
  FAA_PHASE_POSTSUSPEND = 0x20,
  FAA_PHASE_PRERESUME   = 0x30,
  /* POSTRESUME = 0x40, */
  FAA_PHASE_FREE = 0xFF,
};

/*
 * The type of suspend hook functions.
 *
 *   `phase` indicates the point in the suspend/resume lifecycle, as one of
 *     the values of the enum above.
 *   `cv` points to the CV being suspended or resumed. This will be after it
 *     has been cloned, if necessary.
 *   `modhookdata` points to an HV associated with the CV state, and may be
 *     used by modules as a scratchpad to store extra data relating to this
 *     function. Callers should prefix keys with their own module name to
 *     avoid collisions.
 */
typedef void SuspendHookFunc(pTHX_ U8 phase, CV *cv, HV *modhookdata);

/*
 * Callers should use this function-like macro to set the value of the hook
 * function variable, by passing in the address of a new function and a pointer
 * to a variable to capture the previous value.
 *
 *   static SuspendHookFunc *oldhook;
 *
 *   future_asyncawait_wrap_suspendhook(&my_hook_func, &oldhook);
 *
 * The hook function itself should remember to chain to the oldhook function,
 * whose value will never be NULL;
 *
 *   void my_hook_func(aTHX_ U8 phase, CV *cv, HV *modhookdata)
 *   {
 *     ...
 *     (*oldhook)(phase, cv, modhookdata);
 *   }
 */

static void S_null_suspendhook(pTHX_ U8 phase, CV *cv, HV *modhookdata)
{
  /* empty */
}

#ifndef OP_CHECK_MUTEX_LOCK /* < 5.15.8 */
#  define OP_CHECK_MUTEX_LOCK ((void)0)
#  define OP_CHECK_MUTEX_UNLOCK ((void)0)
#endif

#define future_asyncawait_wrap_suspendhook(newfunc, oldhookp) S_future_asyncawait_wrap_suspendhook(aTHX_ newfunc, oldhookp)
static void S_future_asyncawait_wrap_suspendhook(pTHX_ SuspendHookFunc *newfunc, SuspendHookFunc **oldhookp)
{
  if(*oldhookp)
    return;

  warn("future_asyncawait_wrap_suspendhook() is now deprecated; use register_future_asyncawait_hook() instead");

  /* Rather than define our own mutex for this very-rare usecase, we'll just
   * abuse core's opcheck mutex for it. At worst this leads to thread
   * contention at module load time for this very quick test
   */
  OP_CHECK_MUTEX_LOCK;

  if(!*oldhookp) {
    SV **hookp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/suspendhook", TRUE);
    if(hookp && SvOK(*hookp))
      *oldhookp = INT2PTR(SuspendHookFunc *, SvUV(*hookp));
    else
      *oldhookp = &S_null_suspendhook;

    sv_setuv(*hookp, PTR2UV(newfunc));
  }

  OP_CHECK_MUTEX_UNLOCK;
}

#endif
