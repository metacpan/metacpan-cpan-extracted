#ifndef __FUTURE_H__
#define __FUTURE_H__

#define future_boot()  Future_boot(aTHX)
void Future_boot(pTHX);

#define future_new()  Future_new(aTHX)
SV *Future_new(pTHX);

#define future_destroy(f)  Future_destroy(aTHX_ f)
void Future_destroy(pTHX_ SV *f);

#define sv_is_future(sv)  Future_sv_is_future(aTHX_ sv)
bool Future_sv_is_future(pTHX_ SV *sv);

#define future_is_ready(f)  Future_is_ready(aTHX_ f)
bool Future_is_ready(pTHX_ SV *f);

#define future_is_done(f)  Future_is_done(aTHX_ f)
bool Future_is_done(pTHX_ SV *f);

#define future_is_failed(f)  Future_is_failed(aTHX_ f)
bool Future_is_failed(pTHX_ SV *f);

#define future_is_cancelled(f)  Future_is_cancelled(aTHX_ f)
bool Future_is_cancelled(pTHX_ SV *f);

#define future_donev(f, svp, n)  Future_donev(aTHX_ f, svp, n)
void Future_donev(pTHX_ SV *f, SV **svp, size_t n);

#define future_failv(f, svp, n)  Future_failv(aTHX_ f, svp, n)
void Future_failv(pTHX_ SV *f, SV **svp, size_t n);

#define future_failp(f, s)  Future_failp(aTHX_ f, s)
void Future_failp(pTHX_ SV *f, const char *s);

#define future_on_cancel(f, code)  Future_on_cancel(aTHX_ f, code)
void Future_on_cancel(pTHX_ SV *f, SV *code);

#define future_on_ready(f, code)  Future_on_ready(aTHX_ f, code)
void Future_on_ready(pTHX_ SV *f, SV *code);

#define future_on_done(f, code)  Future_on_done(aTHX_ f, code)
void Future_on_done(pTHX_ SV *f, SV *code);

#define future_on_fail(f, code)  Future_on_fail(aTHX_ f, code)
void Future_on_fail(pTHX_ SV *f, SV *code);

#define future_get_result_av(f)  Future_get_result_av(aTHX_ f)
AV *Future_get_result_av(pTHX_ SV *f);

#define future_get_failure_av(f)  Future_get_failure_av(aTHX_ f)
AV *Future_get_failure_av(pTHX_ SV *f);

#define future_cancel(f)  Future_cancel(aTHX_ f)
void Future_cancel(pTHX_ SV *f);

#define future_without_cancel(f)  Future_without_cancel(aTHX_ f)
SV *Future_without_cancel(pTHX_ SV *f);

#define future_then(f, thencode, elsecode)  Future_then(aTHX_ f, thencode, elsecode)
SV *Future_then(pTHX_ SV *f, SV *thencode, SV *elsecode);

#define future_thencatch(f, thencode, catches, elsecode)  Future_thencatch(aTHX_ f, thencode, catches, elsecode)
SV *Future_thencatch(pTHX_ SV *f, SV *thencode, HV *catches, SV *elsecode);

#define future_followed_by(f, code)  Future_followed_by(aTHX_ f, code)
SV *Future_followed_by(pTHX_ SV *f, SV *code);

/* convergent constructors */
#define future_new_waitallv(subs, n)  Future_new_waitallv(aTHX_ subs, n)
SV *Future_new_waitallv(pTHX_ SV **subs, size_t n);

#define future_new_waitanyv(subs, n)  Future_new_waitanyv(aTHX_ subs, n)
SV *Future_new_waitanyv(pTHX_ SV **subs, size_t n);

#define future_new_needsallv(subs, n)  Future_new_needsallv(aTHX_ subs, n)
SV *Future_new_needsallv(pTHX_ SV **subs, size_t n);

#define future_new_needsanyv(subs, n)  Future_new_needsanyv(aTHX_ subs, n)
SV *Future_new_needsanyv(pTHX_ SV **subs, size_t n);

enum FutureSubFilter {
  FUTURE_SUBS_PENDING,
  FUTURE_SUBS_READY,
  FUTURE_SUBS_DONE,
  FUTURE_SUBS_FAILED,
  FUTURE_SUBS_CANCELLED,
};
#define future_mPUSH_subs(f, filter)  Future_mPUSH_subs(aTHX_ f, filter)
Size_t Future_mPUSH_subs(pTHX_ SV *f, enum FutureSubFilter filter);

#define future_set_label(f, label)  Future_set_label(aTHX_ f, label)
void Future_set_label(pTHX_ SV *f, SV *label);

#define future_get_label(f)  Future_get_label(aTHX_ f)
SV *Future_get_label(pTHX_ SV *f);

#endif
