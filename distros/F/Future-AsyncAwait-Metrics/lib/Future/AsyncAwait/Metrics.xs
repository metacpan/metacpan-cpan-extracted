/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AsyncAwait.h"

static SV *S_call_metrics_method(pTHX_ U8 gimme, SV *metrics, const char *method, SV *arg1, SV *arg2)
{
  dSP;
  ENTER;
  SAVETMPS;

  EXTEND(SP, 3);
  PUSHMARK(SP);
  PUSHs(metrics);
  mPUSHs(arg1);
  if(arg2)
    mPUSHs(arg2);
  PUTBACK;

  call_method(method, gimme);

  SV *ret;

  if(gimme > G_VOID) {
    SPAGAIN;
    ret = POPs;
    SvREFCNT_inc(ret);
    PUTBACK;
  }

  FREETMPS;
  LEAVE;

  return ret;
}

#define call_metrics_method_pvn(gimme, metrics, method, pv, len)  \
  S_call_metrics_method(aTHX_ gimme, metrics, method, newSVpvn(pv, len), NULL)
#define call_metrics_method_pvn_iv(gimme, metrics, method, pv, len, iv)  \
  S_call_metrics_method(aTHX_ gimme, metrics, method, newSVpvn(pv, len), newSViv(iv))

struct FAAMetricsState
{
  SV *metrics;

  bool use_batch_mode;

  UV states_created_counter;
  UV suspends_counter;
  UV resumes_counter;
  UV states_destroyed_counter;

  IV current_states_gauge;
  IV current_subs_gauge;
};

XS_INTERNAL(flush_metrics);

static struct FAAMetricsState *S_get_state(pTHX)
{
  struct FAAMetricsState *state;

  SV **svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait::Metrics/state", GV_ADD);
  if(SvOK(*svp))
    state = INT2PTR(struct FAAMetricsState *, SvUV(*svp));
  else {
    Newx(state, 1, struct FAAMetricsState);
    sv_setuv(*svp, PTR2UV(state));

    state->metrics = get_sv("Future::AsyncAwait::Metrics::metrics", 0);

    SV *r = S_call_metrics_method(aTHX_ G_SCALAR, state->metrics,
      "add_batch_mode_callback",
      newRV_noinc((SV *)newXS_flags("flush_metrics", flush_metrics, __FILE__, NULL, 0)),
      NULL
    );

    if(r && SvTRUE(r)) {
      state->use_batch_mode = TRUE;

      state->states_created_counter = 0;
      state->suspends_counter = 0;
      state->resumes_counter = 0;
      state->states_destroyed_counter = 0;

      state->current_states_gauge = 0;
      state->current_subs_gauge = 0;
    }
    else
      state->use_batch_mode = FALSE;
  }

  return state;
}
#define get_state()  S_get_state(aTHX)

XS_INTERNAL(flush_metrics)
{
  struct FAAMetricsState *state = get_state();

#define FLUSH_COUNTER(name) \
  if(state->name##_counter) {                                            \
    call_metrics_method_pvn_iv(G_VOID, state->metrics, "inc_counter_by", \
        "" #name "", sizeof(#name)-1, state->name##_counter);            \
    state->name##_counter = 0;                                           \
  }

  FLUSH_COUNTER(states_created);
  FLUSH_COUNTER(suspends);
  FLUSH_COUNTER(resumes);
  FLUSH_COUNTER(states_destroyed);

#define FLUSH_GAUGE(name) \
  if(state->name##_gauge) {                                            \
    call_metrics_method_pvn_iv(G_VOID, state->metrics, "inc_gauge_by", \
        "" #name "", sizeof(#name)-1, state->name##_gauge);            \
    state->name##_gauge = 0;                                           \
  }

  FLUSH_GAUGE(current_states);
  FLUSH_GAUGE(current_subs);
}

#define INC_COUNTER(name)  \
    if(state->use_batch_mode)  \
      state->name##_counter++; \
    else                       \
      call_metrics_method_pvn(G_VOID, state->metrics, "inc_counter", "" #name "", sizeof(#name)-1)

#define INC_GAUGE(name)  \
    if(state->use_batch_mode)  \
      state->name##_gauge++;   \
    else                       \
      call_metrics_method_pvn(G_VOID, state->metrics, "inc_gauge", "" #name "", sizeof(#name)-1)
#define DEC_GAUGE(name)        \
    if(state->use_batch_mode)  \
      state->name##_gauge--;   \
    else                       \
      call_metrics_method_pvn(G_VOID, state->metrics, "dec_gauge", "" #name "", sizeof(#name)-1)

static void hook_post_cvcopy(pTHX_ CV *runcv, CV *cv, HV *modhookdata, void *hookdata)
{
  struct FAAMetricsState *state = get_state();

  INC_COUNTER(states_created);
  INC_GAUGE(current_states);
}

static void hook_post_suspend(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  struct FAAMetricsState *state = get_state();

  INC_COUNTER(suspends);
  INC_GAUGE(current_subs);
}

static void hook_pre_resume(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  struct FAAMetricsState *state = get_state();

  INC_COUNTER(resumes);
  DEC_GAUGE(current_subs);
}

static void hook_free(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  struct FAAMetricsState *state = get_state();

  INC_COUNTER(states_destroyed);
  DEC_GAUGE(current_states);
}

static const struct AsyncAwaitHookFuncs hooks = {
  .post_cv_copy = &hook_post_cvcopy,
  .post_suspend = &hook_post_suspend,
  .pre_resume   = &hook_pre_resume,
  .free         = &hook_free,
};

MODULE = Future::AsyncAwait::Metrics    PACKAGE = Future::AsyncAwait::Metrics

BOOT:
  boot_future_asyncawait(0.60);

  register_future_asyncawait_hook(&hooks, NULL);
