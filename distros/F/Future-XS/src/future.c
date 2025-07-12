#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "future.h"

#include "perl-backcompat.c.inc"

#include "av-utils.c.inc"
#include "cv_set_anysv_refcounted.c.inc"

#if !HAVE_PERL_VERSION(5, 16, 0)
#  define false FALSE
#  define true  TRUE
#endif

#ifdef HAVE_DMD_HELPER
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#if !HAVE_PERL_VERSION(5, 16, 0)
#  define XS_INTERNAL(name)  static XS(name)
#endif

#define mPUSHpvs(s)   mPUSHp("" s "", sizeof(s)-1)

static bool future_debug;
static bool capture_times;

/* There's no reason these have to match those in Future.pm but for now we
 * might as well just copy the same values
 */
enum {
  CB_DONE   = (1<<0),
  CB_FAIL   = (1<<1),
  CB_CANCEL = (1<<2),
  CB_ALWAYS = CB_DONE|CB_FAIL|CB_CANCEL,

  CB_SELF   = (1<<3),
  CB_RESULT = (1<<4),

  CB_SEQ_READY  = (1<<5),
  CB_SEQ_CANCEL = (1<<6),
  CB_SEQ_ANY = CB_SEQ_READY|CB_SEQ_CANCEL,

  CB_SEQ_IMDONE = (1<<7),
  CB_SEQ_IMFAIL = (1<<8),

  CB_SEQ_STRICT = (1<<9),

  CB_IS_FUTURE = (1<<10),
};

// TODO: Consider using different struct types to save memory? Or maybe it's
// so small a difference it doesn't matter
struct FutureXSCallback
{
  unsigned int flags;
  union {
    SV *code;   /* if !(flags & CB_SEQ_ANY) */
    struct {    /* if  (flags & CB_SEQ_ANY) */
      SV *thencode;
      SV *elsecode;
      HV *catches;
      SV *f;
    } seq;
  };
};

struct FutureXSRevocation
{
  SV *precedent_f;
  SV *toclear_sv_at;
};

#define CB_NONSEQ_CODE(cb)  \
  ({ if((cb)->flags & CB_SEQ_ANY) croak("ARGH: CB_NONSEQ_CODE on SEQ"); (cb)->code;})

enum {
  SUBFLAG_NO_CANCEL = (1<<0),
};

struct FutureXS
{
  unsigned int ready : 1;
  unsigned int cancelled : 1;
  unsigned int reported : 1;
  SV *label;
  AV *result;   // implies done
  AV *failure;  // implies fail
  AV *callbacks;  // values are struct FutureXSCallback ptrs directly. TODO: custom ptr/fill/max
  AV *on_cancel;  // values are CVs directly
  AV *revoke_when_ready; // values are struct FutureXSRevocation ptrs directly.
  int empty_revocation_slots;

  HV *udata;

  struct timeval btime, rtime;
  SV *constructed_at;

  /* For convergents
   * TODO: consider making this an optional extra part of the body, only
   * allocated when required
   */
  AV *subs;
  U8 *subflags;
  Size_t pending_subs;

  /* For without_cancel, purely to keep a strongref */
  SV *precedent_f;
};

#ifdef USE_ITHREADS
static int future_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);

static MGVTBL vtbl = {
  .svt_dup = &future_dup,
};
#endif

bool Future_sv_is_future(pTHX_ SV *sv)
{
  if(!SvROK(sv) || !SvOBJECT(SvRV(sv)))
    return false;

  if(sv_derived_from(sv, "Future") || sv_derived_from(sv, "Future::XS"))
    return true;

  return false;
}

#define get_future(sv)        S_get_future(aTHX_ sv, FALSE)
#define maybe_get_future(sv)  S_get_future(aTHX_ sv, TRUE)
static struct FutureXS *S_get_future(pTHX_ SV *sv, bool nullok)
{
  assert(sv);
  assert(SvROK(sv) && SvOBJECT(SvRV(sv)));
  // TODO: Add some safety checking about class
  struct FutureXS *self = INT2PTR(struct FutureXS *, SvIV(SvRV(sv)));
  if(self || nullok)
    return self;
  croak("Future::XS instance %" SVf " is not available in this thread", SVfARG(sv));
}

SV *Future_new(pTHX_ const char *cls)
{
  if(!cls)
    cls = "Future::XS";

  struct FutureXS *self;
  Newx(self, 1, struct FutureXS);

  self->ready = false;
  self->cancelled = false;
  self->reported = false;

  self->label = NULL;

  if(capture_times)
    gettimeofday(&self->btime, NULL);
  else
    self->btime = (struct timeval){ 0 };

  self->rtime = (struct timeval){ 0 };

  if(future_debug)
    self->constructed_at = newSVpvf("constructed at %s line %d", CopFILE(PL_curcop), CopLINE(PL_curcop));
  else
    self->constructed_at = NULL;

  self->result  = NULL;
  self->failure = NULL;

  self->callbacks = NULL;
  self->on_cancel = NULL;
  self->revoke_when_ready = NULL;
  self->empty_revocation_slots = 0;

  self->udata = NULL;

  self->subs = NULL;
  self->subflags = NULL;

  self->precedent_f = NULL;

  SV *ret = newSV(0);
  sv_setref_pv(ret, cls, self);

#ifdef USE_ITHREADS
  MAGIC *mg = sv_magicext(SvRV(ret), SvRV(ret), PERL_MAGIC_ext, &vtbl, NULL, 0);
  mg->mg_flags |= MGf_DUP;
#endif

  return ret;
}

#define future_new_proto(f1)  Future_new_proto(aTHX_ f1)
SV *Future_new_proto(pTHX_ SV *f1)
{
  assert(f1 && SvROK(f1) && SvRV(f1));
  // TODO Shortcircuit in the common case that f1 is a Future instance
  //   return future_new(HvNAME(SvSTASH(SvRV(f1))));

  dSP;
  ENTER;
  SAVETMPS;

  EXTEND(SP, 1);
  PUSHMARK(SP);
  PUSHs(sv_mortalcopy(f1));
  PUTBACK;

  call_method("new", G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

#ifdef USE_ITHREADS

static int future_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
  /* We don't currently support duplicating a Future instance across thread
   * creation/return. For now just zero out the pointer and complain if anyone
   * tries to access it.
   * This at least means that incidental Future instances that happen to exist
   * in main thread memory won't be disturbed when sidecar threads are joined.
   */
  sv_setiv(mg->mg_obj, 0);
}
#endif

#define clear_callback(cb)  S_clear_callback(aTHX_ cb)
static void S_clear_callback(pTHX_ struct FutureXSCallback *cb)
{
  int flags = cb->flags;
  if(flags & CB_SEQ_ANY) {
    SvREFCNT_dec(cb->seq.thencode);
    SvREFCNT_dec(cb->seq.elsecode);
    SvREFCNT_dec(cb->seq.catches);
    SvREFCNT_dec(cb->seq.f);
  }
  else {
    SvREFCNT_dec(CB_NONSEQ_CODE(cb));
  }
}

#define destroy_callbacks(self)  S_destroy_callbacks(aTHX_ self)
static void S_destroy_callbacks(pTHX_ struct FutureXS *self)
{
  AV *callbacksav = self->callbacks;
  while(callbacksav && AvFILLp(callbacksav) > -1) {
    struct FutureXSCallback *cb = (struct FutureXSCallback *)AvARRAY(self->callbacks)[AvFILLp(callbacksav)--];
    clear_callback(cb);
    Safefree(cb);
  }
}

#define future_mortal_selfstr(f)  Future_mortal_selfstr(aTHX_ f)
static SV *Future_mortal_selfstr(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);

  SV *ret = newSVpvf("%" SVf, SVfARG(f));
  if(self->label)
    sv_catpvf(ret, " (\"%" SVf "\")", SVfARG(self->label));
  if(future_debug)
    sv_catpvf(ret, " (%" SVf ")", SVfARG(self->constructed_at));
  return sv_2mortal(ret);
}

void Future_destroy(pTHX_ SV *f)
{
#ifdef DEBUGGING
// Every pointer in this function ought to have been uniquely held
#  define UNREF(p)  \
    do {                                \
      if(p) assert(SvREFCNT(p) == 1);   \
      SvREFCNT_dec((SV *)p);            \
      (p) = (void *)0xAA55AA55;         \
    } while(0)
#else
#  define UNREF(p)  SvREFCNT_dec((SV *)p)
#endif

  /* Defend against being run during global destruction */
  if(!f || !SvROK(f))
    return;
  struct FutureXS *self = maybe_get_future(f);
  if(!self)
    return;

  if(future_debug &&
    (!self->ready || (self->failure && !self->reported))) {
    if(!self->ready)
      warn("%" SVf " was lost near %s line %d before it was ready\n",
          SVfARG(future_mortal_selfstr(f)),
          CopFILE(PL_curcop), CopLINE(PL_curcop));
    else {
      SV *failure = AvARRAY(self->failure)[0];
      warn("%" SVf " was lost near %s line %d with an unreported failure of: %" SVf "\n",
          SVfARG(future_mortal_selfstr(f)),
          CopFILE(PL_curcop), CopLINE(PL_curcop),
          SVfARG(failure));
    }
  }

  UNREF(self->label);

  UNREF(self->result);

  UNREF(self->failure);

  destroy_callbacks(self);
  UNREF(self->callbacks);

  UNREF(self->on_cancel);

  AV *revocationsav = self->revoke_when_ready;
  while(revocationsav && AvFILLp(revocationsav) > -1) {
    struct FutureXSRevocation *rev = (struct FutureXSRevocation *)AvARRAY(revocationsav)[AvFILLp(revocationsav)--];
    UNREF(rev->precedent_f);
    UNREF(rev->toclear_sv_at);
    Safefree(rev);
  }
  UNREF(self->revoke_when_ready);

  UNREF(self->udata);

  UNREF(self->constructed_at);

  UNREF(self->subs);
  Safefree(self->subflags);

  UNREF(self->precedent_f);

  Safefree(self);

#undef UNREF
}

bool Future_is_ready(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->ready;
}

bool Future_is_done(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->ready && !self->failure && !self->cancelled;
}

bool Future_is_failed(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->ready && self->failure;
}

bool Future_is_cancelled(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->cancelled;
}

#define clear_on_cancel(self)  S_clear_on_cancel(aTHX_ self)
static void S_clear_on_cancel(pTHX_ struct FutureXS *self)
{
  if(!self->on_cancel)
    return;

  AV *on_cancel = self->on_cancel;
  self->on_cancel = NULL;

  SvREFCNT_dec(on_cancel);
}

#define push_callback(self, cb)  S_push_callback(aTHX_ self, cb)
static void S_push_callback(pTHX_ struct FutureXS *self, struct FutureXSCallback *cb)
{
  struct FutureXSCallback *new;
  Newx(new, 1, struct FutureXSCallback);

  new->flags = cb->flags;
  if(cb->flags & CB_SEQ_ANY) {
    new->seq.thencode = cb->seq.thencode;
    new->seq.elsecode = cb->seq.elsecode;
    new->seq.catches  = cb->seq.catches;
    new->seq.f        = cb->seq.f;
  }
  else {
    new->code  = CB_NONSEQ_CODE(cb);
  }

  if(!self->callbacks)
    self->callbacks = newAV();

  av_push(self->callbacks, (SV *)new);
}

#define wrap_cb(f, name, cv)  S_wrap_cb(aTHX_ f, name, cv)
static SV *S_wrap_cb(pTHX_ SV *f, const char *name, SV *cv)
{
  // TODO: This is quite the speed bump having to do this, in the common case
  // that it isn't overridden
  dSP;
  ENTER;
  SAVETMPS;

  EXTEND(SP, 3);
  PUSHMARK(SP);
  PUSHs(sv_mortalcopy(f));
  mPUSHp(name, strlen(name));
  PUSHs(sv_mortalcopy(cv));
  PUTBACK;

  call_method("wrap_cb", G_SCALAR);

  SPAGAIN;
  SV *ret = newSVsv(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

#define invoke_seq_callback(self, selfsv, cb)  S_invoke_seq_callback(aTHX_ self, selfsv, cb)
static SV *S_invoke_seq_callback(pTHX_ struct FutureXS *self, SV *selfsv, struct FutureXSCallback *cb)
{
  int flags = cb->flags;

  bool is_fail = cBOOL(self->failure);
  bool is_done = !self->cancelled && !is_fail;

  AV *result = (is_done) ? self->result :
               (is_fail) ? self->failure :
               NULL;

  SV *code = (is_done) ? cb->seq.thencode :
             (is_fail) ? cb->seq.elsecode :
             NULL;

  if(is_fail && result && av_count(result) > 1 && cb->seq.catches) {
    SV *category = AvARRAY(result)[1];
    if(SvOK(category)) {
      HE *he = hv_fetch_ent(cb->seq.catches, category, 0, 0);
      if(he && HeVAL(he))
        code = HeVAL(he);
    }
  }

  if(!code || !SvOK(code))
    return newSVsv(selfsv);

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  if(flags & CB_SELF)
    XPUSHs(selfsv);
  if(flags & CB_RESULT)
    XPUSHs_from_AV(result);
  PUTBACK;

  assert(SvOK(code));
  call_sv(code, G_SCALAR|G_EVAL);

  SPAGAIN;

  if(SvROK(ERRSV) || SvTRUE(ERRSV)) {
    POPs;

    SV *fseq = cb->seq.f;

    if(!fseq)
      fseq = future_new_proto(selfsv);

    future_failv(fseq, &ERRSV, 1);

    FREETMPS;
    LEAVE;

    return fseq;
  }

  SV *f2 = POPs;
  SvREFCNT_inc(f2);

  PUTBACK;
  FREETMPS;
  LEAVE;

  if(!sv_is_future(f2)) {
    SV *result = f2;

    // TODO: strictness check

    f2 = future_new_proto(selfsv);
    future_donev(f2, &result, 1);
  }

  return f2;
}

#define invoke_callback(self, selfsv, cb)  S_invoke_callback(aTHX_ self, selfsv, cb)
static void S_invoke_callback(pTHX_ struct FutureXS *self, SV *selfsv, struct FutureXSCallback *cb)
{
  int flags = cb->flags;

  bool is_cancelled = self->cancelled;
  bool is_fail      = cBOOL(self->failure);
  bool is_done      = !is_cancelled && !is_fail;

  AV *result = (is_done) ? self->result :
               (is_fail) ? self->failure :
               NULL;

  if(is_done && !(flags & CB_DONE))
    return;
  if(is_fail && !(flags & CB_FAIL))
    return;
  if(is_cancelled && !(flags & CB_CANCEL))
    return;

  if(flags & CB_IS_FUTURE) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(CB_NONSEQ_CODE(cb)); // really a Future RV
    if(result)
      XPUSHs_from_AV(result);

    PUTBACK;
    if(is_done)
      call_method("done", G_VOID);
    else if(is_fail)
      call_method("fail", G_VOID);
    else
      call_method("cancel", G_VOID);

    FREETMPS;
    LEAVE;
  }
  else if(flags & CB_SEQ_ANY) {
    SV *fseq  = cb->seq.f;

    if(!SvOK(fseq)) {
      warn("%" SVf " lost a sequence Future",
          SVfARG(future_mortal_selfstr(selfsv)));
      return;
    }

    SV *f2 = invoke_seq_callback(self, selfsv, cb);
    if(f2 == fseq)
      /* immediate fail */
      return;

    future_on_cancel(fseq, f2);

    if(future_is_ready(f2)) {
      if(!future_is_cancelled(f2))
        future_on_ready(f2, fseq);
      else if(flags & CB_CANCEL)
        future_cancel(fseq);
    }
    else {
      struct FutureXS *f2self = get_future(f2);
      struct FutureXSCallback cb2 = {
        .flags = CB_DONE|CB_FAIL|CB_IS_FUTURE,
        .code  = sv_rvweaken(newSVsv(fseq)),
      };
      push_callback(f2self, &cb2);
    }

    assert(SvREFCNT(f2) == 1);
    SvREFCNT_dec(f2);
  }
  else {
    SV *code = CB_NONSEQ_CODE(cb);

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    if(flags & CB_SELF)
      XPUSHs(selfsv);
    if((flags & CB_RESULT) && result)
      XPUSHs_from_AV(result);

    PUTBACK;
    assert(SvOK(code));
    call_sv(code, G_VOID);

    FREETMPS;
    LEAVE;
  }
}

#define revoke_on_cancel(rev)  S_revoke_on_cancel(aTHX_ rev)
static void S_revoke_on_cancel(pTHX_ struct FutureXSRevocation *rev)
{
  if(rev->toclear_sv_at && SvROK(rev->toclear_sv_at)) {
    assert(SvTYPE(rev->toclear_sv_at) <= SVt_PVMG);
    assert(SvROK(rev->toclear_sv_at));
    sv_set_undef(SvRV(rev->toclear_sv_at));
    SvREFCNT_dec(rev->toclear_sv_at);
    rev->toclear_sv_at = NULL;
  }

  if(!SvOK(rev->precedent_f))
    return;

  struct FutureXS *self = get_future(rev->precedent_f);

  self->empty_revocation_slots++;

  AV *on_cancel = self->on_cancel;
  if(self->empty_revocation_slots >= 8 && on_cancel &&
      self->empty_revocation_slots >= AvFILL(on_cancel)/2) {

    // Squash up the array to contain only defined values
    SV **wrsv = AvARRAY(on_cancel),
       **rdsv = AvARRAY(on_cancel),
       **end  = AvARRAY(on_cancel) + AvFILL(on_cancel);

    while(rdsv <= end) {
      if(SvOK(*rdsv))
        // Keep this one
        *(wrsv++) = *rdsv;
      else
        // Free this one
        SvREFCNT_dec(*rdsv);

      rdsv++;
    }
    AvFILLp(on_cancel) = wrsv - AvARRAY(on_cancel) - 1;

    self->empty_revocation_slots = 0;
  }
}

#define mark_ready(self, selfsv, state)  S_mark_ready(aTHX_ self, selfsv, state)
static void S_mark_ready(pTHX_ struct FutureXS *self, SV *selfsv, const char *state)
{
  self->ready = true;
  // TODO: self->ready_at
  if(capture_times)
    gettimeofday(&self->rtime, NULL);

  /* Make sure self doesn't disappear during this function */
  SvREFCNT_inc(SvRV(selfsv));
  SAVEFREESV(SvRV(selfsv));

  if(self->precedent_f) {
    SvREFCNT_dec(self->precedent_f);
    self->precedent_f = NULL;
  }

  clear_on_cancel(self);
  if(self->revoke_when_ready) {
    AV *revocations = self->revoke_when_ready;
    for(size_t i = 0; i < av_count(revocations); i++) {
      struct FutureXSRevocation *rev = (struct FutureXSRevocation *)AvARRAY(revocations)[i];
      revoke_on_cancel(rev);

      SvREFCNT_dec(rev->precedent_f);
      Safefree(rev);
    }
    AvFILLp(revocations) = -1;
    SvREFCNT_dec(revocations);

    self->revoke_when_ready = NULL;
  }

  if(!self->callbacks)
    return;

  AV *callbacks = self->callbacks;

  struct FutureXSCallback **cbs = (struct FutureXSCallback **)AvARRAY(callbacks);
  size_t i, n = av_count(callbacks);
  for(i = 0; i < n; i++) {
    struct FutureXSCallback *cb = cbs[i];
    invoke_callback(self, selfsv, cb);
  }

  destroy_callbacks(self);
}

#define make_sequence(f1, cb)  S_make_sequence(aTHX_ f1, cb)
static SV *S_make_sequence(pTHX_ SV *f1, struct FutureXSCallback *cb)
{
  struct FutureXS *self = get_future(f1);

  int flags = cb->flags;

  if(self->ready) {
    // TODO: CB_SEQ_IM*

    SV *f2 = invoke_seq_callback(self, f1, cb);
    clear_callback(cb);
    return f2;
  }

  SV *fseq = future_new_proto(f1);
  if(cb->flags & CB_SEQ_CANCEL)
    future_on_cancel(fseq, f1);

  cb->flags |= CB_DONE|CB_FAIL;
  if(cb->seq.thencode)
    cb->seq.thencode = wrap_cb(f1, "sequence", sv_2mortal(cb->seq.thencode));
  if(cb->seq.elsecode)
    cb->seq.elsecode = wrap_cb(f1, "sequence", sv_2mortal(cb->seq.elsecode));
  cb->seq.f = sv_rvweaken(newSVsv(fseq));

  push_callback(self, cb);

  return fseq;
}

// TODO: move to a hax/ file
#define CvNAME_FILE_LINE(cv)  S_CvNAME_FILE_LINE(aTHX_ cv)
static SV *S_CvNAME_FILE_LINE(pTHX_ CV *cv)
{
  if(!CvANON(cv)) {
    SV *ret = newSVpvf("HvNAME::GvNAME");
    return ret;
  }

  OP *cop = CvSTART(cv);
  while(cop && OP_CLASS(cop) != OA_COP)
    cop = cop->op_next;

  if(!cop)
    return newSVpvs("__ANON__");

  return newSVpvf("__ANON__(%s line %d)", CopFILE((COP *)cop), CopLINE((COP *)cop));
}

static const char *statestr(struct FutureXS *self)
{
  if(!self->ready)
    return "pending";
  if(self->cancelled)
    return "cancelled";
  if(self->failure)
    return "failed";

  return "done";
}

void Future_donev(pTHX_ SV *f, SV **svp, size_t n)
{
  struct FutureXS *self = get_future(f);

  if(self->cancelled)
    return;

  if(self->ready)
    croak("%" SVf " is already %s and cannot be ->done",
        SVfARG(f), statestr(self));
  // TODO: test subs

  self->result = newAV_svn_dup(svp, n);
  mark_ready(self, f, "done");
}

void Future_failv(pTHX_ SV *f, SV **svp, size_t n)
{
  struct FutureXS *self = get_future(f);

  if(self->cancelled)
    return;

  if(self->ready)
    croak("%" SVf " is already %s and cannot be ->fail'ed",
        SVfARG(f), statestr(self));

  if(n == 1 &&
      SvROK(svp[0]) && SvOBJECT(SvRV(svp[0])) &&
      sv_derived_from(svp[0], "Future::Exception")) {
    SV *exception = svp[0];
    AV *failure = self->failure = newAV();

    dSP;

    {
      ENTER;
      SAVETMPS;

      EXTEND(SP, 1);
      PUSHMARK(SP);
      PUSHs(sv_mortalcopy(exception));
      PUTBACK;

      call_method("message", G_SCALAR);

      SPAGAIN;

      av_push(failure, SvREFCNT_inc(POPs));

      PUTBACK;
      FREETMPS;
      LEAVE;
    }

    {
      ENTER;
      SAVETMPS;

      EXTEND(SP, 1);
      PUSHMARK(SP);
      PUSHs(sv_mortalcopy(exception));
      PUTBACK;

      call_method("category", G_SCALAR);

      SPAGAIN;

      av_push(failure, SvREFCNT_inc(POPs));

      PUTBACK;
      FREETMPS;
      LEAVE;
    }

    {
      ENTER;
      SAVETMPS;

      EXTEND(SP, 1);
      PUSHMARK(SP);
      PUSHs(sv_mortalcopy(exception));
      PUTBACK;

      SSize_t count = call_method("details", G_LIST);

      SPAGAIN;

      SV **retp = SP - count + 1;

      for(SSize_t i = 0; i < count; i++)
        av_push(failure, SvREFCNT_inc(retp[i]));
      SP -= count;

      PUTBACK;
      FREETMPS;
      LEAVE;
    }
  }
  else {
    self->failure = newAV_svn_dup(svp, n);
  }

  mark_ready(self, f, "failed");
}

#define future_failp(f, s)  Future_failp(aTHX_ f, s)
void Future_failp(pTHX_ SV *f, const char *s)
{
  struct FutureXS *self = get_future(f);

  if(self->cancelled)
    return;

  if(self->ready)
    croak("%" SVf " is already %s and cannot be ->fail'ed",
        SVfARG(f), statestr(self));

  self->failure = newAV();
  av_push(self->failure, newSVpv(s, strlen(s)));
  mark_ready(self, f, "failed");
}

void Future_on_cancel(pTHX_ SV *f, SV *code)
{
  struct FutureXS *self = get_future(f);

  if(self->ready)
    return;

  bool is_future = sv_is_future(code);
  // TODO: is_future or callable(code) or croak

  if(!self->on_cancel)
    self->on_cancel = newAV();

  SV *rv = newSVsv((SV *)code);
  av_push(self->on_cancel, rv);

  if(is_future) {
    struct FutureXSRevocation *rev;
    Newx(rev, 1, struct FutureXSRevocation);

    rev->precedent_f = sv_rvweaken(newSVsv(f));
    rev->toclear_sv_at = sv_rvweaken(newRV_inc(rv));

    struct FutureXS *codeself = get_future(code);
    if(!codeself->revoke_when_ready)
      codeself->revoke_when_ready = newAV();

    av_push(codeself->revoke_when_ready, (SV *)rev);
  }
}

void Future_on_ready(pTHX_ SV *f, SV *code)
{
  struct FutureXS *self = get_future(f);

  bool is_future = sv_is_future(code);
  // TODO: is_future or callable(code) or croak

  int flags = CB_ALWAYS|CB_SELF;
  if(is_future)
    flags |= CB_IS_FUTURE;

  struct FutureXSCallback cb = {
    .flags = flags,
    .code  = code,
  };

  if(self->ready)
    invoke_callback(self, f, &cb);
  else {
    cb.code = wrap_cb(f, "on_ready", cb.code);
    push_callback(self, &cb);
  }
}

void Future_on_done(pTHX_ SV *f, SV *code)
{
  struct FutureXS *self = get_future(f);

  bool is_future = sv_is_future(code);
  // TODO: is_future or callable(code) or croak

  int flags = CB_DONE|CB_RESULT;
  if(is_future)
    flags |= CB_IS_FUTURE;

  struct FutureXSCallback cb = {
    .flags = flags,
    .code  = code,
  };

  if(self->ready)
    invoke_callback(self, f, &cb);
  else {
    cb.code = wrap_cb(f, "on_done", cb.code);
    push_callback(self, &cb);
  }
}

void Future_on_fail(pTHX_ SV *f, SV *code)
{
  struct FutureXS *self = get_future(f);

  bool is_future = sv_is_future(code);
  // TODO: is_future or callable(code) or croak

  int flags = CB_FAIL|CB_RESULT;
  if(is_future)
    flags |= CB_IS_FUTURE;

  struct FutureXSCallback cb = {
    .flags = flags,
    .code  = code,
  };

  if(self->ready)
    invoke_callback(self, f, &cb);
  else {
    cb.code = wrap_cb(f, "on_fail", cb.code);
    push_callback(self, &cb);
  }
}

#define future_await(f)  Future_await(aTHX_ f)
static void Future_await(pTHX_ SV *f)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  mXPUSHs(newSVsv(f));
  PUTBACK;

  call_method("await", G_VOID);

  FREETMPS;
  LEAVE;
}

AV *Future_get_result_av(pTHX_ SV *f, bool await)
{
  struct FutureXS *self = get_future(f);

  if(await && !self->ready)
    future_await(f);

  if(!self->ready)
    croak("%" SVf " is not yet ready", SVfARG(f));

  if(self->failure) {
    self->reported = true;

    SV *exception = AvARRAY(self->failure)[0];
    if(av_count(self->failure) > 1) {
      dSP;
      ENTER;
      SAVETMPS;

      PUSHMARK(SP);
      EXTEND(SP, 1 + av_count(self->failure));
      mPUSHpvs("Future::Exception");
      for(SSize_t i = 0; i < av_count(self->failure); i++)
        PUSHs(sv_mortalcopy(AvARRAY(self->failure)[i]));
      PUTBACK;

      call_method("new", G_SCALAR);

      SPAGAIN;

      exception = SvREFCNT_inc(POPs);

      PUTBACK;
      FREETMPS;
      LEAVE;
    }

    if(SvROK(exception) || SvPV_nolen(exception)[SvCUR(exception)-1] == '\n')
      die_sv(exception);
    else {
      /* We'd like to call Carp::croak to do the @CARP_NOT logic, but it gets
       * confused about a missing callframe first because this is XS. We'll
       * reïmplement the logic here
       */
      I32 cxix;
      for(cxix = cxstack_ix; cxix; cxix--) {
        if(CxTYPE(&cxstack[cxix]) != CXt_SUB)
          continue;

        const CV *cv = cxstack[cxix].blk_sub.cv;
        if(!cv)
          continue;

        const char *stashname = HvNAME(CvSTASH(cv));
        if(!stashname)
          continue;

        // The essence of the @CARP_NOT logic
        if(strEQ(stashname, "Future::_base"))
          continue;

        const COP *cop = cxix < cxstack_ix ? cxstack[cxix+1].blk_oldcop : PL_curcop;

        sv_catpvf(exception, " at %s line %d.\n", CopFILE(cop), CopLINE(cop));
        break;
      }

      die_sv(exception);
    }
  }

  if(self->cancelled)
    croak("%" SVf " was cancelled",
        SVfARG(future_mortal_selfstr(f)));

  if(!self->result)
    self->result = newAV();

  return self->result;
}

AV *Future_get_failure_av(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);

  if(!self->ready)
    future_await(f);

  if(!self->failure)
    return NULL;

  return self->failure;
}

void Future_cancel(pTHX_ SV *f)
{
  /* Specifically don't make it an error to ->cancel a future instance not
   * available in this thread; as it often appears in defer / DESTROY / etc
   */
  struct FutureXS *self = maybe_get_future(f);
  if(!self)
    return;

  if(self->ready)
    return;

  self->cancelled = true;
  AV *on_cancel = self->on_cancel;

  if(self->subs) {
    for(Size_t i = 0; i < av_count(self->subs); i++) {
      U8 flags = self->subflags[i];
      if(!(flags & SUBFLAG_NO_CANCEL))
        future_cancel(AvARRAY(self->subs)[i]);
    }
  }

  // TODO: maybe we need to clear these out from self before we do this, in
  // case of recursion?

  for(int i = on_cancel ? AvFILL(on_cancel) : -1; i >= 0; i--) {
    SV *code = AvARRAY(on_cancel)[i];
    if(!SvOK(code))
      continue;

    if(sv_is_future(code)) {
      dSP;

      ENTER;
      SAVETMPS;

      PUSHMARK(SP);
      PUSHs(code);
      PUTBACK;

      call_method("cancel", G_VOID);

      FREETMPS;
      LEAVE;
    }
    else {
      dSP;

      ENTER;
      SAVETMPS;

      PUSHMARK(SP);
      PUSHs(f);
      PUTBACK;

      assert(SvOK(code));
      call_sv(code, G_VOID);

      FREETMPS;
      LEAVE;
    }
  }

  mark_ready(self, f, "cancel");
}

SV *Future_without_cancel(pTHX_ SV *f)
{
  struct FutureXSCallback cb = {
    .flags = CB_SEQ_READY|CB_CANCEL, /* without CB_SEQ_CANCEL */
    /* no code */
  };

  SV *ret = make_sequence(f, &cb);
  struct FutureXS *self = get_future(ret);

  self->precedent_f = newSVsv(f);

  return ret;
}

SV *Future_then(pTHX_ SV *f, U32 flags, SV *thencode, SV *elsecode)
{
  struct FutureXSCallback cb = {
    .flags        = CB_SEQ_ANY|CB_RESULT,
    .seq.thencode = thencode,
    .seq.elsecode = elsecode,
  };
  if(flags & FUTURE_THEN_WITH_F)
    cb.flags |= CB_SELF;

  return make_sequence(f, &cb);
}

SV *Future_followed_by(pTHX_ SV *f, SV *code)
{
  struct FutureXSCallback cb = {
    .flags        = CB_SEQ_ANY|CB_SELF,
    .seq.thencode = code,
    .seq.elsecode = SvREFCNT_inc(code),
  };

  return make_sequence(f, &cb);
}

SV *Future_thencatch(pTHX_ SV *f, U32 flags, SV *thencode, HV *catches, SV *elsecode)
{
  struct FutureXSCallback cb = {
    .flags        = CB_SEQ_ANY|CB_RESULT,
    .seq.thencode = thencode,
    .seq.elsecode = elsecode,
    .seq.catches  = catches,
  };
  if(flags & FUTURE_THEN_WITH_F)
    cb.flags |= CB_SELF;

  return make_sequence(f, &cb);
}

#define future_new_subsv(cls, subs, n)  S_future_new_subsv(aTHX_ cls, subs, n)
static SV *S_future_new_subsv(pTHX_ const char *cls, SV **subs, size_t n)
{
  HV *future_stash = get_hv("Future::", 0);
  assert(future_stash);

  /* Find the best prototype; pick the first derived instance if there is
   * one */
  SV *proto = NULL;
  size_t subcount = 0;
  for(Size_t i = 0; i < n; i++) {
    if(!SvROK(subs[i]) && SvPOK(subs[i]) && strEQ(SvPVX(subs[i]), "also"))
      i++;

    if(!SvROK(subs[i]) || !SvOBJECT(SvRV(subs[i])))
      croak("Expected a Future, got %" SVf, SVfARG(subs[i]));

    subcount++;

    if(!proto && SvSTASH(SvRV(subs[i])) != future_stash)
      proto = subs[i];
  }

  SV *f = proto ? future_new_proto(proto) : future_new(cls);
  struct FutureXS *self = get_future(f);

  if(!self->subs)
    self->subs = newAV();
  av_extend(self->subs, subcount);
  if(!self->subflags)
    Newx(self->subflags, subcount, U8);

  for(Size_t i = 0, subi = 0; i < n; i++, subi++) {
    U8 flags = 0;
    if(!SvROK(subs[i]) && SvPOK(subs[i]) && strEQ(SvPVX(subs[i]), "also"))
      flags |= SUBFLAG_NO_CANCEL, i++;

    av_store(self->subs, subi, newSVsv(subs[i]));
    self->subflags[subi] = flags;
  }

  return f;
}

#define copy_result(self, src)  S_copy_result(aTHX_ self, src)
static void S_copy_result(pTHX_ struct FutureXS *self, SV *src)
{
  /* TODO: Handle non-Future::XS instances too */
  struct FutureXS *srcself = get_future(src);

  assert(srcself->ready);
  assert(!srcself->cancelled);

  if(srcself->failure) {
    self->failure = newAV_svn_dup(AvARRAY(srcself->failure), av_count(srcself->failure));
  }
  else {
    assert(srcself->result);
    self->result = newAV_svn_dup(AvARRAY(srcself->result),  av_count(srcself->result));
  }
}

#define cancel_pending_subs(self)  S_cancel_pending_subs(aTHX_ self)
static void S_cancel_pending_subs(pTHX_ struct FutureXS *self)
{
  if(!self->subs)
    return;

  for(Size_t i = 0; i < av_count(self->subs); i++) {
    SV *sub = AvARRAY(self->subs)[i];
    U8 flags = self->subflags[i];

    if(!(flags & SUBFLAG_NO_CANCEL) && !future_is_ready(sub))
      future_cancel(sub);
  }
}

XS_INTERNAL(sub_on_ready_waitall)
{
  dXSARGS;

  SV *f = XSANY_sv;
  if(!SvOK(f))
    return;

  /* Make sure self doesn't disappear during this function */
  SvREFCNT_inc(SvRV(f));
  SAVEFREESV(SvRV(f));

  struct FutureXS *self = get_future(f);

  self->pending_subs--;

  if(self->pending_subs)
    XSRETURN(0);

  /* TODO: This is really just newAVav() */
  self->result = newAV_svn_dup(AvARRAY(self->subs), av_count(self->subs));
  mark_ready(self, f, "wait_all");
}

SV *Future_new_waitallv(pTHX_ const char *cls, SV **subs, size_t n)
{
  SV *f = future_new_subsv(cls, subs, n);
  struct FutureXS *self = get_future(f);

  /* Reïnit subs + n */
  subs = AvARRAY(self->subs);
  n    = av_count(self->subs);

  self->pending_subs = 0;
  for(Size_t i = 0; i < n; i++) {
    /* TODO: This should probably use some API function to make it transparent */
    if(!future_is_ready(subs[i]))
      self->pending_subs++;
  }

  if(!self->pending_subs) {
    self->result = newAV_svn_dup(subs, n);
    mark_ready(self, f, "wait_all");

    return f;
  }

  CV *sub_on_ready = newXS(NULL, sub_on_ready_waitall, __FILE__);
  cv_set_anysv_refcounted(sub_on_ready, newSVsv(f));
  sv_rvweaken(CvXSUBANY_sv(sub_on_ready));

  GV *gv = gv_fetchpvs("Future::XS::(wait_all callback)", GV_ADDMULTI, SVt_PVCV);
  CvGV_set(sub_on_ready, gv);
  CvANON_off(sub_on_ready);

  for(Size_t i = 0; i < n; i++) {
    if(!future_is_ready(subs[i]))
      future_on_ready(subs[i], sv_2mortal(newRV_inc((SV *)sub_on_ready)));
  }

  SvREFCNT_dec(sub_on_ready);

  return f;
}

XS_INTERNAL(sub_on_ready_waitany)
{
  dXSARGS;
  SV *thissub = ST(0);

  SV *f = XSANY_sv;
  if(!SvOK(f))
    return;

  /* Make sure self doesn't disappear during this function */
  SvREFCNT_inc(SvRV(f));
  SAVEFREESV(SvRV(f));

  struct FutureXS *self = get_future(f);

  if(self->result || self->failure)
    return;

  self->pending_subs--;

  bool this_cancelled = future_is_cancelled(thissub);

  if(self->pending_subs && this_cancelled)
    return;

  if(this_cancelled) {
    future_failp(f, "All component futures were cancelled");
    return;
  }
  else
    copy_result(self, thissub);

  cancel_pending_subs(self);

  mark_ready(self, f, "wait_any");
}

SV *Future_new_waitanyv(pTHX_ const char *cls, SV **subs, size_t n)
{
  SV *f = future_new_subsv(cls, subs, n);
  struct FutureXS *self = get_future(f);

  /* Reïnit subs + n */
  subs = AvARRAY(self->subs);
  n    = av_count(self->subs);

  if(!n) {
    future_failp(f, "Cannot ->wait_any with no subfutures");
    return f;
  }

  SV *immediate_ready = NULL;
  for(Size_t i = 0; i < n; i++) {
    /* TODO: This should probably use some API function to make it transparent */
    if(future_is_ready(subs[i]) && !future_is_cancelled(subs[i])) {
      immediate_ready = subs[i];
      break;
    }
  }

  if(immediate_ready) {
    copy_result(self, immediate_ready);

    cancel_pending_subs(self);

    mark_ready(self, f, "wait_any");

    return f;
  }

  self->pending_subs = 0;

  CV *sub_on_ready = newXS(NULL, sub_on_ready_waitany, __FILE__);
  cv_set_anysv_refcounted(sub_on_ready, newSVsv(f));
  sv_rvweaken(CvXSUBANY_sv(sub_on_ready));

  GV *gv = gv_fetchpvs("Future::XS::(wait_any callback)", GV_ADDMULTI, SVt_PVCV);
  CvGV_set(sub_on_ready, gv);
  CvANON_off(sub_on_ready);

  for(Size_t i = 0; i < n; i++) {
    if(future_is_cancelled(subs[i]))
      continue;

    future_on_ready(subs[i], sv_2mortal(newRV_inc((SV *)sub_on_ready)));
    self->pending_subs++;
  }

  SvREFCNT_dec(sub_on_ready);

  return f;
}

#define compose_needsall_result(self)  S_compose_needsall_result(aTHX_ self)
static void S_compose_needsall_result(pTHX_ struct FutureXS *self)
{
  AV *result = self->result = newAV();
  for(Size_t i = 0; i < av_count(self->subs); i++) {
    SV *sub = AvARRAY(self->subs)[i];
    struct FutureXS *subself = get_future(sub);
    assert(subself->result);
    av_push_svn(result, AvARRAY(subself->result), av_count(subself->result));
  }
}

XS_INTERNAL(sub_on_ready_needsall)
{
  dXSARGS;
  SV *thissub = ST(0);

  SV *f = XSANY_sv;
  if(!SvOK(f))
    return;

  /* Make sure self doesn't disappear during this function */
  SvREFCNT_inc(SvRV(f));
  SAVEFREESV(SvRV(f));

  struct FutureXS *self = get_future(f);

  if(self->result || self->failure)
    return;

  if(future_is_cancelled(thissub)) {
    future_failp(f, "A component future was cancelled");
    cancel_pending_subs(self);
    return;
  }
  else if(future_is_failed(thissub)) {
    copy_result(self, thissub);
    cancel_pending_subs(self);
    mark_ready(self, f, "needs_all");
  }
  else {
    self->pending_subs--;
    if(self->pending_subs)
      return;
    compose_needsall_result(self);
    mark_ready(self, f, "needs_all");
  }
}

SV *Future_new_needsallv(pTHX_ const char *cls, SV **subs, size_t n)
{
  SV *f = future_new_subsv(cls, subs, n);
  struct FutureXS *self = get_future(f);

  /* Reïnit subs + n */
  subs = AvARRAY(self->subs);
  n    = av_count(self->subs);

  if(!n) {
    future_donev(f, NULL, 0);
    return f;
  }

  SV *immediate_fail = NULL;
  for(Size_t i = 0; i < n; i++) {
    if(future_is_cancelled(subs[i])) {
      future_failp(f, "A component future was cancelled");
      cancel_pending_subs(self);
      return f;
    }
    if(future_is_failed(subs[i])) {
      immediate_fail = subs[i];
      break;
    }
  }

  if(immediate_fail) {
    copy_result(self, immediate_fail);
    cancel_pending_subs(self);
    mark_ready(self, f, "needs_all");
    return f;
  }

  self->pending_subs = 0;

  CV *sub_on_ready = newXS(NULL, sub_on_ready_needsall, __FILE__);
  cv_set_anysv_refcounted(sub_on_ready, newSVsv(f));
  sv_rvweaken(CvXSUBANY_sv(sub_on_ready));

  GV *gv = gv_fetchpvs("Future::XS::(needs_all callback)", GV_ADDMULTI, SVt_PVCV);
  CvGV_set(sub_on_ready, gv);
  CvANON_off(sub_on_ready);

  for(Size_t i = 0; i < n; i++) {
    if(future_is_ready(subs[i]))
      continue;

    future_on_ready(subs[i], sv_2mortal(newRV_inc((SV *)sub_on_ready)));
    self->pending_subs++;
  }

  if(!self->pending_subs) {
    compose_needsall_result(self);
    mark_ready(self, f, "needs_all");
  }

  SvREFCNT_dec(sub_on_ready);

  return f;
}

XS_INTERNAL(sub_on_ready_needsany)
{
  dXSARGS;
  SV *thissub = ST(0);

  SV *f = XSANY_sv;
  if(!SvOK(f))
    return;

  /* Make sure self doesn't disappear during this function */
  SvREFCNT_inc(SvRV(f));
  SAVEFREESV(SvRV(f));

  struct FutureXS *self = get_future(f);

  if(self->result || self->failure)
    return;

  self->pending_subs--;

  bool this_cancelled = future_is_cancelled(thissub);

  if(self->pending_subs && this_cancelled)
    return;

  if(this_cancelled) {
    future_failp(f, "All component futures were cancelled");
  }
  else if(future_is_failed(thissub)) {
    if(self->pending_subs)
      return;

    copy_result(self, thissub);
    mark_ready(self, f, "needs_any");
  }
  else {
    copy_result(self, thissub);
    cancel_pending_subs(self);
    mark_ready(self, f, "needs_any");
  }
}

SV *Future_new_needsanyv(pTHX_ const char *cls, SV **subs, size_t n)
{
  SV *f = future_new_subsv(cls, subs, n);
  struct FutureXS *self = get_future(f);

  /* Reïnit subs + n */
  subs = AvARRAY(self->subs);
  n    = av_count(self->subs);

  if(!n) {
    future_failp(f, "Cannot ->needs_any with no subfutures");
    return f;
  }

  SV *immediate_done = NULL;
  for(Size_t i = 0; i < n; i++) {
    if(future_is_done(subs[i])) {
      immediate_done = subs[i];
      break;
    }
  }

  if(immediate_done) {
    copy_result(self, immediate_done);
    cancel_pending_subs(self);
    mark_ready(self, f, "needs_any");
    return f;
  }

  self->pending_subs = 0;

  CV *sub_on_ready = newXS(NULL, sub_on_ready_needsany, __FILE__);
  cv_set_anysv_refcounted(sub_on_ready, newSVsv(f));
  sv_rvweaken(CvXSUBANY_sv(sub_on_ready));

  GV *gv = gv_fetchpvs("Future::XS::(needs_any callback)", GV_ADDMULTI, SVt_PVCV);
  CvGV_set(sub_on_ready, gv);
  CvANON_off(sub_on_ready);

  for(Size_t i = 0; i < n; i++) {
    if(future_is_ready(subs[i]))
      continue;

    future_on_ready(subs[i], sv_2mortal(newRV_inc((SV *)sub_on_ready)));
    self->pending_subs++;
  }

  if(!self->pending_subs) {
    copy_result(self, subs[n-1]);
    mark_ready(self, f, "needs_any");
  }

  SvREFCNT_dec(sub_on_ready);

  return f;
}

Size_t Future_mPUSH_subs(pTHX_ SV *f, enum FutureSubFilter filter)
{
  dSP;

  struct FutureXS *self = get_future(f);

  Size_t ret = 0;
  for(Size_t i = 0; self->subs && i < av_count(self->subs); i++) {
    SV *sub = AvARRAY(self->subs)[i];

    bool want;
    switch(filter) {
      case FUTURE_SUBS_PENDING:
        want = !future_is_ready(sub);
        break;

      case FUTURE_SUBS_READY:
        want = future_is_ready(sub);
        break;

      case FUTURE_SUBS_DONE:
        want = future_is_done(sub);
        break;

      case FUTURE_SUBS_FAILED:
        want = future_is_failed(sub);
        break;

      case FUTURE_SUBS_CANCELLED:
        want = future_is_cancelled(sub);
        break;
    }

    if(want) {
      XPUSHs(sv_mortalcopy(sub));
      ret++;
    }
  }

  PUTBACK;
  return ret;
}

struct timeval Future_get_btime(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->btime;
}

struct timeval Future_get_rtime(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);
  return self->rtime;
}

void Future_set_label(pTHX_ SV *f, SV *label)
{
  struct FutureXS *self = get_future(f);

  if(self->label)
    SvREFCNT_dec(label);

  self->label = newSVsv(label);
}

SV *Future_get_label(pTHX_ SV *f)
{
  struct FutureXS *self = get_future(f);

  return self->label;
}

void Future_set_udata(pTHX_ SV *f, SV *key, SV *value)
{
  struct FutureXS *self = get_future(f);

  if(!self->udata)
    self->udata = newHV();

  hv_store_ent(self->udata, key, newSVsv(value), 0);
}

SV *Future_get_udata(pTHX_ SV *f, SV *key)
{
  struct FutureXS *self = get_future(f);

  if(!self->udata)
    return &PL_sv_undef;

  HE *he = hv_fetch_ent(self->udata, key, 0, 0);
  return he ? HeVAL(he) : &PL_sv_undef;
}

/* DMD_HELPER assistants */

#ifdef HAVE_DMD_HELPER
static int dumpstruct_callback(pTHX_ DMDContext *ctx, struct FutureXSCallback *cb)
{
  if(!(cb->flags & CB_SEQ_ANY))
    DMD_DUMP_STRUCT(ctx, "Future::XS/FutureXSCallback", cb, sizeof(struct FutureXSCallback),
      /* Some cheating here, to claim the "code" is either a CV or a Future,
       * depending on the CB_IS_FUTURE flag */
      3, ((const DMDNamedField []){
        {"flags",         DMD_FIELD_UINT, .n   = cb->flags},
        {"the code CV",   DMD_FIELD_PTR,  .ptr = (cb->flags & CB_IS_FUTURE) ? NULL     : cb->code},
        {"the Future SV", DMD_FIELD_PTR,  .ptr = (cb->flags & CB_IS_FUTURE) ? cb->code : NULL    },
      })
    );
  else
    DMD_DUMP_STRUCT(ctx, "Future::XS/FutureXSCallback(CB_SEQ)", cb, sizeof(struct FutureXSCallback),
      4, ((const DMDNamedField []){
        {"flags",                  DMD_FIELD_UINT, .n = cb->flags},
        {"the then code CV",       DMD_FIELD_PTR,  .ptr = cb->seq.thencode},
        {"the else code CV",       DMD_FIELD_PTR,  .ptr = cb->seq.elsecode},
        {"the sequence future SV", DMD_FIELD_PTR,  .ptr = cb->seq.f},
      })
    );

  return 0;
}

static int dumpstruct_revocation(pTHX_ DMDContext *ctx, struct FutureXSRevocation *rev)
{
  DMD_DUMP_STRUCT(ctx, "Future::XS/FutureXSRevocation", rev, sizeof(struct FutureXSRevocation),
    2, ((const DMDNamedField []){
      {"the precedent future SV", DMD_FIELD_PTR, .ptr = rev->precedent_f},
      {"the SV to clear RV",      DMD_FIELD_PTR, .ptr = rev->toclear_sv_at},
    })
  );

  return 0;
}

static int dumpstruct(pTHX_ DMDContext *ctx, const SV *sv)
{
  int ret = 0;

  // TODO: Add some safety checking
  struct FutureXS *self = INT2PTR(struct FutureXS *, SvIV((SV *)sv));

  DMD_DUMP_STRUCT(ctx, "Future::XS/FutureXS", self, sizeof(struct FutureXS),
    12, ((const DMDNamedField []){
      {"ready",                    DMD_FIELD_BOOL, .b   = self->ready},
      {"cancelled",                DMD_FIELD_BOOL, .b   = self->cancelled},
      {"the label SV",             DMD_FIELD_PTR,  .ptr = self->label},
      {"the result AV",            DMD_FIELD_PTR,  .ptr = self->result},
      {"the failure AV",           DMD_FIELD_PTR,  .ptr = self->failure},
      {"the callbacks AV",         DMD_FIELD_PTR,  .ptr = self->callbacks},
      {"the on_cancel AV",         DMD_FIELD_PTR,  .ptr = self->on_cancel},
      {"the revoke_when_ready AV", DMD_FIELD_PTR,  .ptr = self->revoke_when_ready},
      {"the udata HV",             DMD_FIELD_PTR,  .ptr = self->udata},
      {"the constructed-at SV",    DMD_FIELD_PTR,  .ptr = self->constructed_at},
      {"the subs AV",              DMD_FIELD_PTR,  .ptr = self->subs},
      {"the pending sub count",    DMD_FIELD_UINT, .n   = self->pending_subs},
    })
  );

  for(size_t i = 0; self->callbacks && i < av_count(self->callbacks); i++) {
    struct FutureXSCallback *cb = (struct FutureXSCallback *)AvARRAY(self->callbacks)[i];
    ret += dumpstruct_callback(aTHX_ ctx, cb);
  }

  for(size_t i = 0; self->revoke_when_ready && i < av_count(self->revoke_when_ready); i++) {
    struct FutureXSRevocation *rev = (struct FutureXSRevocation *)AvARRAY(self->revoke_when_ready)[i];
    ret += dumpstruct_revocation(aTHX_ ctx, rev);
  }

  ret += DMD_ANNOTATE_SV(sv, (SV *)self, "the FutureXS structure");

  return ret;
}
#endif

#define getenv_bool(key)  S_getenv_bool(aTHX_ key)
static bool S_getenv_bool(pTHX_ const char *key)
{
  const char *val = getenv(key);
  if(!val || !val[0])
    return false;
  if(val[0] == '0' && strlen(val) == 1)
    return false;
  return true;
}

#ifndef newSVbool
#  define newSVbool(b)  newSVsv(b ? &PL_sv_yes : &PL_sv_no)
#endif

void Future_reread_environment(pTHX)
{
  future_debug = getenv_bool("PERL_FUTURE_DEBUG");

  capture_times = future_debug || getenv_bool("PERL_FUTURE_TIMES");
  sv_setsv(get_sv("Future::TIMES", GV_ADDMULTI), capture_times ? &PL_sv_yes : &PL_sv_no);
}

void Future_boot(pTHX)
{
#ifdef HAVE_DMD_HELPER
  DMD_SET_PACKAGE_HELPER("Future::XS", dumpstruct);
#endif

  Future_reread_environment(aTHX);

  // We can only do this once
  newCONSTSUB(gv_stashpvn("Future::XS", 10, TRUE), "DEBUG", newSVbool(future_debug));
}
