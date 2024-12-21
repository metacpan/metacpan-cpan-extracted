/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2022 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AsyncAwait.h"

#ifdef HAVE_DMD_HELPER
#  define WANT_DMD_API_044
#  include "DMD_helper.h"
#endif

#include "XSParseKeyword.h"
#include "XSParseSublike.h"

#include "perl-backcompat.c.inc"
#include "PL_savetype_name.c.inc"

#if !HAVE_PERL_VERSION(5, 24, 0)
  /* On perls before 5.24 we have to do some extra work to save the itervar
   * from being thrown away */
#  define HAVE_ITERVAR
#endif

#if HAVE_PERL_VERSION(5, 24, 0)
  /* For unknown reasons, doing this on perls 5.20 or 5.22 massively breaks
   * everything.
   *   https://rt.cpan.org/Ticket/Display.html?id=129202#txn-1843918
   */
#  define HAVE_FUTURE_CHAIN_CANCEL
#endif

#if HAVE_PERL_VERSION(5, 26, 0)
#  define HAVE_OP_ARGCHECK
#endif

#if HAVE_PERL_VERSION(5, 33, 7)
/* perl 5.33.7 added CXp_TRY and the CxTRY macro for true try/catch semantics */
#  define HAVE_CX_TRY
#endif

#ifdef SAVEt_CLEARPADRANGE
#  include "save_clearpadrange.c.inc"
#endif

#if !HAVE_PERL_VERSION(5, 24, 0)
#  include "cx_pushblock.c.inc"
#  include "cx_pusheval.c.inc"
#endif

#include "perl-additions.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "cv_copy_flags.c.inc"

/* Currently no version of perl makes this visible, so we always want it. Maybe
 * one day in the future we can make it version-dependent
 */

static void panic(char *fmt, ...);

#ifndef NOT_REACHED
#  define NOT_REACHED STMT_START { panic("Unreachable\n"); } STMT_END
#endif
#include "docatch.c.inc"

typedef struct SuspendedFrame SuspendedFrame;
struct SuspendedFrame {
  SuspendedFrame *next;
  U8 type;
  U8 gimme;

  U32 stacklen;
  SV **stack;

  U32 marklen;
  I32 *marks;

  COP *oldcop;

  /* items from the save stack */
  U32 savedlen;
  struct Saved {
    U8 type;
    union {
      struct {
        PADOFFSET padix;
        U32 count;
      } clearpad;      /* for SAVEt_CLEARSV and SAVEt_CLEARPADRANGE */
      struct {
        void (*func)(pTHX_ void *data);
        void *data;
      } dx;            /* for SAVEt_DESTRUCTOR_X */
      GV *gv;          /* for SAVEt_SV + cur.sv, saved.sv */
      int *iptr;       /* for SAVEt_INT... */
      STRLEN *lenptr;  /* for SAVEt_STRLEN + cur.len, saved.len */
      PADOFFSET padix; /* for SAVEt_PADSV_AND_MORTALIZE, SAVEt_SPTR */
      SV *sv;          /* for SAVEt_ITEM */
      struct {
        SV *sv;
        U32 mask, set;
      } svflags;       /* for SAVEt_SET_SVFLAGS */
    } u;

    union {
      SV    *sv;      /* for SAVEt_SV, SAVEt_FREESV, SAVEt_ITEM */
      void  *ptr;     /* for SAVEt_COMPPAD, */
      int    i;       /* for SAVEt_INT... */
      STRLEN len;     /* for SAVEt_STRLEN */
    } cur,    /* the current value that *thing that we should restore to */
      saved;  /* the saved value we should push to the savestack on restore */
  } *saved;

  union {
    struct {
      OP *retop;
    } eval;
    struct block_loop loop;
  } el;

  /* for debugging purposes */
  SV *loop_list_first_item;

#ifdef HAVE_ITERVAR
  SV *itervar;
#endif
  U32 scopes;

  U32 mortallen;
  SV **mortals;
};

typedef struct {
  SV *awaiting_future;   /* the Future that 'await' is currently waiting for */
  SV *returning_future;  /* the Future that its contining CV will eventually return */
  COP *curcop;           /* value of PL_curcop at suspend time */
  SuspendedFrame *frames;

  U32 padlen;
  SV **padslots;

  PMOP *curpm;           /* value of PL_curpm at suspend time */
  AV *defav;             /* value of GvAV(PL_defgv) at suspend time */

  HV *modhookdata;
} SuspendedState;

#ifdef DEBUG
#  define TRACEPRINT S_traceprint
static void S_traceprint(char *fmt, ...)
{
  /* TODO: make conditional */
  va_list args;
  va_start(args, fmt);
  vfprintf(stderr, fmt, args);
  va_end(args);
}
#else
#  define TRACEPRINT(...)
#endif

static void vpanic(char *fmt, va_list args)
{
  fprintf(stderr, "Future::AsyncAwait panic: ");
  vfprintf(stderr, fmt, args);
  raise(SIGABRT);
}

static void panic(char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  vpanic(fmt, args);
}

/*
 * Hook mechanism
 */

struct HookRegistration
{
  const struct AsyncAwaitHookFuncs *funcs;
  void                             *data;
};

struct HookRegistrations
{
  struct HookRegistration *arr;
  size_t count, size;
};

static struct HookRegistrations *S_registrations(pTHX_ bool add)
{
  SV *regsv = *hv_fetchs(PL_modglobal, "Future::AsyncAwait/registrations", GV_ADD);
  if(!SvOK(regsv)) {
    if(!add)
      return NULL;

    struct HookRegistrations *registrations;
    Newx(registrations, 1, struct HookRegistrations);

    registrations->count = 0;
    registrations->size  = 4;
    Newx(registrations->arr, registrations->size, struct HookRegistration);

    sv_setuv(regsv, PTR2UV(registrations));
  }

  return INT2PTR(struct HookRegistrations *, SvUV(regsv));
}
#define registrations(add)  S_registrations(aTHX_ add)

static void register_faa_hook(pTHX_ const struct AsyncAwaitHookFuncs *hookfuncs, void *hookdata)
{
  /* Currently no flags are recognised; complain if the caller requested any */
  if(hookfuncs->flags)
    croak("Unrecognised hookfuncs->flags value %08x", hookfuncs->flags);

  struct HookRegistrations *regs = registrations(TRUE);

  if(regs->count == regs->size) {
    regs->size *= 2;
    Renew(regs->arr, regs->size, struct HookRegistration);
  }

  regs->arr[regs->count].funcs = hookfuncs;
  regs->arr[regs->count].data  = hookdata;
  regs->count++;
}

#define RUN_HOOKS_FWD(func, ...) \
  {                                                        \
    int _hooki = 0;                                        \
    while(_hooki < regs->count) {                          \
      struct HookRegistration *reg = regs->arr + _hooki;   \
      if(reg->funcs->func)                                 \
        (*reg->funcs->func)(aTHX_ __VA_ARGS__, reg->data); \
      _hooki++;                                            \
    }                                                      \
  }

#define RUN_HOOKS_REV(func, ...) \
  {                                                        \
    int _hooki = regs->count;                              \
    while(_hooki > 0) {                                    \
      _hooki--;                                            \
      struct HookRegistration *reg = regs->arr + _hooki;   \
      if(reg->funcs->func)                                 \
        (*reg->funcs->func)(aTHX_ __VA_ARGS__, reg->data); \
    }                                                      \
  }

/*
 * Magic that we attach to suspended CVs, that contains state required to restore
 * them
 */

static int suspendedstate_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL vtbl_suspendedstate = {
  NULL, /* get   */
  NULL, /* set   */
  NULL, /* len   */
  NULL, /* clear */
  suspendedstate_free,
};

#ifdef HAVE_DMD_HELPER
static int dumpmagic_suspendedstate(pTHX_ DMDContext *ctx, const SV *sv, MAGIC *mg)
{
  SuspendedState *state = (SuspendedState *)mg->mg_ptr;
  int ret = 0;

  ret += DMD_ANNOTATE_SV(sv, state->awaiting_future, "the awaiting Future");
  ret += DMD_ANNOTATE_SV(sv, state->returning_future, "the returning Future");

  SuspendedFrame *frame;
  for(frame = state->frames; frame; frame = frame->next) {
    int i;

    for(i = 0; i < frame->stacklen; i++)
      ret += DMD_ANNOTATE_SV(sv, frame->stack[i], "a suspended stack temporary");

    for(i = 0; i < frame->mortallen; i++)
      ret += DMD_ANNOTATE_SV(sv, frame->mortals[i], "a suspended mortal");

#ifdef HAVE_ITERVAR
    if(frame->itervar)
      ret += DMD_ANNOTATE_SV(sv, frame->itervar, "a suspended loop iteration variable");
#endif

    switch(frame->type) {
      case CXt_BLOCK:
      case CXt_LOOP_PLAIN:
        break;

      case CXt_LOOP_LAZYSV:
        ret += DMD_ANNOTATE_SV(sv, frame->el.loop.state_u.lazysv.cur, "a suspended foreach LAZYSV loop iterator value");
        ret += DMD_ANNOTATE_SV(sv, frame->el.loop.state_u.lazysv.end, "a suspended foreach LAZYSV loop stop value");
        goto cxt_loop_common;

#if HAVE_PERL_VERSION(5, 24, 0)
      case CXt_LOOP_ARY:
#else
      case CXt_LOOP_FOR:
#endif
        if(frame->el.loop.state_u.ary.ary)
          ret += DMD_ANNOTATE_SV(sv, (SV *)frame->el.loop.state_u.ary.ary, "a suspended foreach ARY loop value array");
        goto cxt_loop_common;

      case CXt_LOOP_LAZYIV:
#if HAVE_PERL_VERSION(5, 24, 0)
      case CXt_LOOP_LIST:
#endif
      cxt_loop_common:
#if !defined(HAVE_ITERVAR)
        ret += DMD_ANNOTATE_SV(sv, frame->el.loop.itersave, "a suspended loop saved iteration variable");
#endif
        break;
    }

    for(i = 0; i < frame->savedlen; i++) {
      struct Saved *saved = &frame->saved[i];
      switch(saved->type) {
#ifdef SAVEt_CLEARPADRANGE
        case SAVEt_CLEARPADRANGE:
#endif
        case SAVEt_CLEARSV:
        case SAVEt_INT_SMALL:
        case SAVEt_DESTRUCTOR_X:
#ifdef SAVEt_STRLEN
      case SAVEt_STRLEN:
#endif
        case SAVEt_SET_SVFLAGS:
          /* Nothing interesting */
          break;

        case SAVEt_FREEPV:
          /* This is interesting but a plain char* pointer so there's nothing
           * we can do with it in Devel::MAT */
          break;

        case SAVEt_COMPPAD:
          ret += DMD_ANNOTATE_SV(sv, saved->cur.ptr, "a suspended SAVEt_COMPPAD");
          break;

        case SAVEt_FREESV:
          ret += DMD_ANNOTATE_SV(sv, saved->saved.sv, "a suspended SAVEt_FREESV");
          break;

        case SAVEt_SV:
          ret += DMD_ANNOTATE_SV(sv, (SV *)saved->u.gv, "a suspended SAVEt_SV target GV");
          ret += DMD_ANNOTATE_SV(sv, saved->cur.sv,     "a suspended SAVEt_SV current value");
          ret += DMD_ANNOTATE_SV(sv, saved->saved.sv,   "a suspended SAVEt_SV saved value");
          break;

        case SAVEt_SPTR:
          ret += DMD_ANNOTATE_SV(sv, saved->cur.sv,   "a suspended SAVEt_SPTR current value");
          ret += DMD_ANNOTATE_SV(sv, saved->saved.sv, "a suspended SAVEt_SPTR saved value");
          break;

        case SAVEt_PADSV_AND_MORTALIZE:
          ret += DMD_ANNOTATE_SV(sv, saved->cur.sv,   "a suspended SAVEt_PADSV_AND_MORTALIZE current value");
          ret += DMD_ANNOTATE_SV(sv, saved->saved.sv, "a suspended SAVEt_PADSV_AND_MORTALIZE saved value");
          break;
      }
    }
  }

  if(state->padlen && state->padslots) {
    int i;
    for(i = 0; i < state->padlen - 1; i++)
      if(state->padslots[i])
        ret += DMD_ANNOTATE_SV(sv, state->padslots[i], "a suspended pad slot");
  }

  if(state->defav)
    ret += DMD_ANNOTATE_SV(sv, (SV *)state->defav, "the subroutine arguments AV");

  if(state->modhookdata)
    ret += DMD_ANNOTATE_SV(sv, (SV *)state->modhookdata, "the module hook data HV");

  return ret;
}
#endif

#define suspendedstate_get(cv)  MY_suspendedstate_get(aTHX_ cv)
static SuspendedState *MY_suspendedstate_get(pTHX_ CV *cv)
{
  MAGIC *magic;

  for(magic = mg_find((SV *)cv, PERL_MAGIC_ext); magic; magic = magic->mg_moremagic)
    if(magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &vtbl_suspendedstate)
      return (SuspendedState *)magic->mg_ptr;

  return NULL;
}

#define suspendedstate_new(cv)  MY_suspendedstate_new(aTHX_ cv)
static SuspendedState *MY_suspendedstate_new(pTHX_ CV *cv)
{
  SuspendedState *ret;
  Newx(ret, 1, SuspendedState);

  ret->awaiting_future = NULL;
  ret->returning_future = NULL;
  ret->frames = NULL;
  ret->padslots = NULL;
  ret->modhookdata = NULL;
  ret->defav = NULL;

  sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &vtbl_suspendedstate, (char *)ret, 0);

  return ret;
}

static int suspendedstate_free(pTHX_ SV *sv, MAGIC *mg)
{
  SuspendedState *state = (SuspendedState *)mg->mg_ptr;

  if(state->awaiting_future) {
    SvREFCNT_dec(state->awaiting_future);
    state->awaiting_future = NULL;
  }

  if(state->returning_future) {
    SvREFCNT_dec(state->returning_future);
    state->returning_future = NULL;
  }

  if(state->frames) {
    SuspendedFrame *frame, *next = state->frames;
    while((frame = next)) {
      next = frame->next;

      if(frame->stacklen) {
        /* The stack isn't refcounted, so we should not SvREFCNT_dec() these
         * items
         */
        Safefree(frame->stack);
      }

      if(frame->marklen) {
        Safefree(frame->marks);
      }

      if(frame->saved) {
        int idx;
        for(idx = 0; idx < frame->savedlen; idx++) {
          struct Saved *saved = &frame->saved[idx];
          switch(saved->type) {
            /* Saved types for which we've no cleanup needed */
#ifdef SAVEt_CLEARPADRANGE
            case SAVEt_CLEARPADRANGE:
#endif
            case SAVEt_CLEARSV:
            case SAVEt_COMPPAD:
            case SAVEt_INT_SMALL:
            case SAVEt_DESTRUCTOR_X:
#ifdef SAVEt_STRLEN
            case SAVEt_STRLEN:
#endif
            case SAVEt_SET_SVFLAGS:
              break;

            case SAVEt_FREEPV:
              Safefree(saved->cur.ptr);
              break;

            case SAVEt_FREESV:
              SvREFCNT_dec(saved->saved.sv);
              break;

            case SAVEt_SV:
              SvREFCNT_dec(saved->u.gv);
              SvREFCNT_dec(saved->saved.sv);
              SvREFCNT_dec(saved->cur.sv);
              break;

            case SAVEt_PADSV_AND_MORTALIZE:
              SvREFCNT_dec(saved->saved.sv);
              SvREFCNT_dec(saved->cur.sv);
              break;

            case SAVEt_SPTR:
              SvREFCNT_dec(saved->saved.sv);
              /* saved->cur.sv does not account for an extra refcount */
              break;

            default:
            {
              char *name = PL_savetype_name[saved->type];
              if(name)
                fprintf(stderr, "TODO: free saved slot type SAVEt_%s=%d\n", name, saved->type);
              else
                fprintf(stderr, "TODO: free saved slot type UNKNOWN=%d\n", saved->type);
              break;
            }
          }
        }

        Safefree(frame->saved);
      }

      switch(frame->type) {
        case CXt_BLOCK:
        case CXt_LOOP_PLAIN:
          break;

        case CXt_LOOP_LAZYSV:
          SvREFCNT_dec(frame->el.loop.state_u.lazysv.cur);
          SvREFCNT_dec(frame->el.loop.state_u.lazysv.end);
          goto cxt_loop_common;

#if HAVE_PERL_VERSION(5, 24, 0)
        case CXt_LOOP_ARY:
#else
        case CXt_LOOP_FOR:
#endif
          if(frame->el.loop.state_u.ary.ary)
            SvREFCNT_dec(frame->el.loop.state_u.ary.ary);
          goto cxt_loop_common;

        case CXt_LOOP_LAZYIV:
#if HAVE_PERL_VERSION(5, 24, 0)
        case CXt_LOOP_LIST:
#endif
        cxt_loop_common:
#if !defined(HAVE_ITERVAR)
          SvREFCNT_dec(frame->el.loop.itersave);
#endif
          break;
      }

#ifdef HAVE_ITERVAR
      if(frame->itervar) {
        SvREFCNT_dec(frame->itervar);
        frame->itervar = NULL;
      }
#endif

      if(frame->mortals) {
        int i;
        for(i = 0; i < frame->mortallen; i++)
          sv_2mortal(frame->mortals[i]);

        Safefree(frame->mortals);
      }

      Safefree(frame);
    }
  }

  if(state->padslots) {
    int i;
    for(i = 0; i < state->padlen - 1; i++) {
      if(state->padslots[i])
        SvREFCNT_dec(state->padslots[i]);
    }

    Safefree(state->padslots);
    state->padslots = NULL;
    state->padlen = 0;
  }

  if(state->defav) {
    SvREFCNT_dec(state->defav);
    state->defav = NULL;
  }

  if(state->modhookdata) {
    struct HookRegistrations *regs = registrations(FALSE);
    /* New hooks first */
    if(regs)
      RUN_HOOKS_REV(free, (CV *)sv, state->modhookdata);

    /* Legacy hooks after */
    SV **hookp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/suspendhook", FALSE);
    if(hookp && SvOK(*hookp) && SvUV(*hookp)) {
      warn("Invoking legacy Future::AsyncAwait suspendhook for FREE phase");
      SuspendHookFunc *hook = INT2PTR(SuspendHookFunc *, SvUV(*hookp));
      (*hook)(aTHX_ FAA_PHASE_FREE, (CV *)sv, state->modhookdata);
    }

    SvREFCNT_dec(state->modhookdata);
  }

  Safefree(state);

  return 1;
}

#define suspend_frame(frame, cx)  MY_suspend_frame(aTHX_ frame, cx)
static void MY_suspend_frame(pTHX_ SuspendedFrame *frame, PERL_CONTEXT *cx)
{
  frame->stacklen = (I32)(PL_stack_sp - PL_stack_base)  - cx->blk_oldsp;
  if(frame->stacklen) {
    SV **bp = PL_stack_base + cx->blk_oldsp + 1;
    I32 i;
    /* Steal SVs right off the stack */
    Newx(frame->stack, frame->stacklen, SV *);
    for(i = 0; i < frame->stacklen; i++) {
      frame->stack[i] = bp[i];
      bp[i] = NULL;
    }
    PL_stack_sp = PL_stack_base + cx->blk_oldsp;
  }

  frame->marklen = (I32)(PL_markstack_ptr - PL_markstack) - cx->blk_oldmarksp;
  if(frame->marklen) {
    I32 *markbase = PL_markstack + cx->blk_oldmarksp + 1;
    I32 i;
    Newx(frame->marks, frame->marklen, I32);
    for(i = 0; i < frame->marklen; i++) {
      /* Translate mark value relative to base */
      I32 relmark = markbase[i] - cx->blk_oldsp;
      frame->marks[i] = relmark;
    }
    PL_markstack_ptr = PL_markstack + cx->blk_oldmarksp;
  }

  frame->oldcop = cx->blk_oldcop;

  I32 old_saveix = OLDSAVEIX(cx);
  /* This is an over-estimate but it doesn't matter. We just waste a bit of RAM
   * temporarily
   */
  I32 savedlen = PL_savestack_ix - old_saveix;
  if(savedlen)
    Newx(frame->saved, savedlen, struct Saved);
  else
    frame->saved = NULL;
  frame->savedlen = 0; /* we increment it as we fill it */

  I32 oldtmpsfloor = -2;
#if HAVE_PERL_VERSION(5, 24, 0)
  /* Perl 5.24 onwards has a PERL_CONTEXT slot for the old value of
   * PL_tmpsfloor. Older perls do not, and keep it in the save stack instead.
   * We'll keep an eye out for its saved value
   */
  oldtmpsfloor = cx->blk_old_tmpsfloor;
#endif

  while(PL_savestack_ix > old_saveix) {
    /* Useful references
     *   scope.h
     *   scope.c: Perl_leave_scope()
     */

    UV uv = PL_savestack[PL_savestack_ix-1].any_uv;
    U8 type = (U8)uv & SAVE_MASK;

    struct Saved *saved = &frame->saved[frame->savedlen];

    switch(type) {
#ifdef SAVEt_CLEARPADRANGE
      case SAVEt_CLEARPADRANGE: {
        UV padix = uv >> (OPpPADRANGE_COUNTSHIFT + SAVE_TIGHT_SHIFT);
        I32 count = (uv >> SAVE_TIGHT_SHIFT) & OPpPADRANGE_COUNTMASK;
        PL_savestack_ix--;

        saved->type = count == 1 ? SAVEt_CLEARSV : SAVEt_CLEARPADRANGE;
        saved->u.clearpad.padix = padix;
        saved->u.clearpad.count = count;

        break;
      }
#endif

      case SAVEt_CLEARSV: {
        UV padix = (uv >> SAVE_TIGHT_SHIFT);
        PL_savestack_ix--;

        saved->type = SAVEt_CLEARSV;
        saved->u.clearpad.padix = padix;

        break;
      }

      case SAVEt_COMPPAD: {
        /* This occurs as a side-effect of Perl_pad_new on 5.22 */
        PL_savestack_ix -= 2;
        void *pad = PL_savestack[PL_savestack_ix].any_ptr;

        saved->type      = SAVEt_COMPPAD;
        saved->saved.ptr = pad;
        saved->cur.ptr   = PL_comppad;

        PL_comppad = pad;
        PL_curpad = PL_comppad ? AvARRAY(PL_comppad) : NULL;

        break;
      }

      case SAVEt_FREEPV: {
        PL_savestack_ix -= 2;
        char *pv = PL_savestack[PL_savestack_ix].any_ptr;

        saved->type = SAVEt_FREEPV;
        saved->saved.ptr = pv;

        break;
      }

      case SAVEt_FREESV: {
        PL_savestack_ix -= 2;
        void *sv = PL_savestack[PL_savestack_ix].any_ptr;

        saved->type     = SAVEt_FREESV;
        saved->saved.sv = sv;

        break;
      }

      case SAVEt_INT_SMALL: {
        PL_savestack_ix -= 2;
        int val = ((int)uv >> SAVE_TIGHT_SHIFT);
        int *var = PL_savestack[PL_savestack_ix].any_ptr;

        /* In general we don't want to support this; but specifically on perls
         * older than 5.20, this might be PL_tmps_floor
         */
        if(var == (int *)&PL_tmps_floor) {
          /* Don't bother to save the old tmpsfloor as we'll SAVETMPS again
           * later if we need to
           */
          oldtmpsfloor = val;
          goto nosave;
        }

        panic("TODO: Unsure how to handle a savestack entry of SAVEt_INT_SMALL with var != &PL_tmps_floor\n");
        break;
      }

      case SAVEt_DESTRUCTOR_X: {
        /* This is only known to be used by Syntax::Keyword::Try to implement
         * finally blocks. It may be found elsewhere for which this code is
         * unsafe, but detecting such cases is generally impossible. Good luck.
         */
        PL_savestack_ix -= 3;
        void (*func)(pTHX_ void *) = PL_savestack[PL_savestack_ix].any_dxptr;
        void *data                 = PL_savestack[PL_savestack_ix+1].any_ptr;

        saved->type = SAVEt_DESTRUCTOR_X;
        saved->u.dx.func = func;
        saved->u.dx.data = data;

        break;
      }

      case SAVEt_ITEM: {
        PL_savestack_ix -= 3;
        SV *var = PL_savestack[PL_savestack_ix].any_ptr;
        SV *val = PL_savestack[PL_savestack_ix+1].any_ptr;

        saved->type = SAVEt_ITEM;
        saved->u.sv = var;
        saved->cur.sv = newSVsv(var);
        saved->saved.sv = val;

        /* restore it for now */
        sv_setsv(var, val);

        break;
      }

      case SAVEt_SPTR: {
        PL_savestack_ix -= 3;
        SV  *val = PL_savestack[PL_savestack_ix].any_ptr;
        SV **var = PL_savestack[PL_savestack_ix+1].any_ptr;

        /* In general we don't support this; but specifically we will accept
         * it if we can convert var into a PAD index. This is to support
         * SAVESPTR(PAD_SVl(padix)), as may be used by Object::Pad or others
         */
        if(var < PL_curpad || var > PL_curpad + AvFILL(PL_comppad))
          panic("TODO: Unsure how to handle a savestack entry of SAVEt_SPTR with var not the current pad\n");

        PADOFFSET padix = var - PL_curpad;

        saved->type = SAVEt_SPTR;
        saved->u.padix = padix;
        saved->cur.sv = PL_curpad[padix]; /* steal ownership */
        saved->saved.sv = val;            /* steal ownership */

        /* restore it for now */
        PL_curpad[padix] = SvREFCNT_inc(val);

        break;
      }

#ifdef SAVEt_STRLEN
      case SAVEt_STRLEN: {
        PL_savestack_ix -= 3;
        STRLEN  val = PL_savestack[PL_savestack_ix].any_iv;
        STRLEN *var = PL_savestack[PL_savestack_ix+1].any_ptr;

        /* In general we don't want to support this; but specifically on perls
         * older than 5.24, this might be PL_tmps_floor
         */
        if(var == (STRLEN *)&PL_tmps_floor) {
          /* Don't bother to save the old tmpsfloor as we'll SAVETMPS again
           * later if we need to
           */
          oldtmpsfloor = val;
          goto nosave;
        }

        panic("TODO: Unsure how to handle a savestack entry of SAVEt_STRLEN with var != &PL_tmps_floor\n");
        break;
      }
#endif

      case SAVEt_SV: {
        PL_savestack_ix -= 3;
        /* despite being called SAVEt_SV, the first field actually points at
         * the GV containing the local'ised SV
         */
        GV *gv  = PL_savestack[PL_savestack_ix  ].any_ptr;
        SV *val = PL_savestack[PL_savestack_ix+1].any_ptr;

        /* In general we don't want to support local $VAR. However, a special
         * case of  local $@  is allowable
         * See also  https://rt.cpan.org/Ticket/Display.html?id=122793
         */
        if(gv != PL_errgv) {
          const char *name = GvNAME(gv);
          const char *stashname = HvNAME(GvSTASH(gv));

          if(name && stashname)
            panic("TODO: Unsure how to handle a savestack entry of SAVEt_SV with gv != PL_errgv ($%s::%s)\n",
              stashname, name);
          else
            panic("TODO: Unsure how to handle a savestack entry of SAVEt_SV with gv != PL_errgv\n");
        }

        saved->type     = SAVEt_SV;
        saved->u.gv     = gv;
        saved->cur.sv   = GvSV(gv); /* steal ownership */
        saved->saved.sv = val;      /* steal ownership */

        /* restore it for now */
        GvSV(gv) = val;

        break;
      }

      case SAVEt_PADSV_AND_MORTALIZE: {
        PL_savestack_ix -= 4;
        SV *val         = PL_savestack[PL_savestack_ix  ].any_ptr;
        AV *padav       = PL_savestack[PL_savestack_ix+1].any_ptr;
        PADOFFSET padix = PL_savestack[PL_savestack_ix+2].any_uv;

        if(padav != PL_comppad)
          panic("TODO: Unsure how to handle a savestack entry of SAVEt_PADSV_AND_MORTALIZE with padav != PL_comppad\n");

        SvREFCNT_inc(PL_curpad[padix]); /* un-mortalize */

        saved->type     = SAVEt_PADSV_AND_MORTALIZE;
        saved->u.padix  = padix;
        saved->cur.sv   = PL_curpad[padix]; /* steal ownership */
        saved->saved.sv = val;              /* steal ownership */

        AvARRAY(padav)[padix] = SvREFCNT_inc(val);

        break;
      }

      case SAVEt_SET_SVFLAGS: {
        PL_savestack_ix -= 4;
        SV *sv   = PL_savestack[PL_savestack_ix  ].any_ptr;
        U32 mask = (U32)PL_savestack[PL_savestack_ix+1].any_i32;
        U32 set  = (U32)PL_savestack[PL_savestack_ix+2].any_i32;

        saved->type           = SAVEt_SET_SVFLAGS;
        saved->u.svflags.sv   = sv;
        saved->u.svflags.mask = mask;
        saved->u.svflags.set  = set;

        break;
      }

      default:
      {
        char *name = PL_savetype_name[type];
        if(name)
          panic("TODO: Unsure how to handle savestack entry of SAVEt_%s=%d\n", name, type);
        else
          panic("TODO: Unsure how to handle savestack entry of UNKNOWN=%d\n", type);
      }
    }

    frame->savedlen++;

nosave:
    ;
  }

  if(OLDSAVEIX(cx) != PL_savestack_ix)
    panic("TODO: handle OLDSAVEIX\n");

  frame->scopes = (PL_scopestack_ix - cx->blk_oldscopesp) + 1;
  if(frame->scopes) {
    /* We'll mutate PL_scopestack_ix but it doesn't matter as dounwind() will
     * put it right at the end. Do this unconditionally to avoid divergent
     * behaviour between -DDEBUGGING builds and non.
     */
    PL_scopestack_ix -= frame->scopes;
  }

  /* ref:
   *   https://perl5.git.perl.org/perl.git/blob/HEAD:/cop.h
   */
  U8 type = CxTYPE(cx);
  switch(type) {
    case CXt_BLOCK:
      frame->type = CXt_BLOCK;
      frame->gimme = cx->blk_gimme;
      /* nothing else special */
      break;

    case CXt_LOOP_PLAIN:
      frame->type = type;
      frame->el.loop = cx->blk_loop;
      frame->gimme = cx->blk_gimme;
      break;

#if HAVE_PERL_VERSION(5, 24, 0)
    case CXt_LOOP_ARY:
    case CXt_LOOP_LIST:
#else
    case CXt_LOOP_FOR:
#endif
    case CXt_LOOP_LAZYSV:
    case CXt_LOOP_LAZYIV:
      if(!CxPADLOOP(cx))
        /* non-lexical foreach will effectively work like 'local' and we
         * can't really support local
         */
        croak("Cannot suspend a foreach loop on non-lexical iterator");

      frame->type = type;
      frame->el.loop = cx->blk_loop;
      frame->gimme = cx->blk_gimme;

#ifdef HAVE_ITERVAR
#  ifdef USE_ITHREADS
      if(cx->blk_loop.itervar_u.svp != (SV **)PL_comppad)
        panic("TODO: Unsure how to handle a foreach loop with itervar != PL_comppad\n");
#  else
      if(cx->blk_loop.itervar_u.svp != &PAD_SVl(cx->blk_loop.my_op->op_targ))
        panic("TODO: Unsure how to handle a foreach loop with itervar != PAD_SVl(op_targ))\n");
#  endif

      frame->itervar = SvREFCNT_inc(*CxITERVAR(cx));
#else
      if(CxITERVAR(cx) != &PAD_SVl(cx->blk_loop.my_op->op_targ))
        panic("TODO: Unsure how to handle a foreach loop with itervar != PAD_SVl(op_targ))\n");
      SvREFCNT_inc(cx->blk_loop.itersave);
#endif

      switch(type) {
        case CXt_LOOP_LAZYSV:
          /* these two fields are refcounted, so we need to save them from
           * dounwind() throwing them away
           */
          SvREFCNT_inc(frame->el.loop.state_u.lazysv.cur);
          SvREFCNT_inc(frame->el.loop.state_u.lazysv.end);
          break;

#if HAVE_PERL_VERSION(5, 24, 0)
        case CXt_LOOP_ARY:
#else
        case CXt_LOOP_FOR:
          /* The ix field stores an absolute stack height as offset from
           * PL_stack_base directly. When we get resumed the stack will
           * probably not be the same absolute height at this point, so we'll
           * have to store them relative to something fixed.
           */
          if(!cx->blk_loop.state_u.ary.ary) {
            I32 height = PL_stack_sp - PL_stack_base;
            frame->el.loop.state_u.ary.ix = height - frame->el.loop.state_u.ary.ix;
          }
#endif
          /* this field is also refcounted, so we need to save it too */
          if(frame->el.loop.state_u.ary.ary)
            SvREFCNT_inc(frame->el.loop.state_u.ary.ary);
          break;

#if HAVE_PERL_VERSION(5, 24, 0)
        case CXt_LOOP_LIST: {
          /* The various fields in the context structure store absolute stack
           * heights as offsets from PL_stack_base directly. When we get
           * resumed the stack will probably not be the same absolute height
           * at this point, so we'll have to store them relative to something
           * fixed.
           * We'll adjust them to be upside-down, counting -backwards- from
           * the current stack height.
           */
          I32 height = PL_stack_sp - PL_stack_base;

          if(cx->blk_oldsp != height)
            panic("ARGH suspending CXt_LOOP_LIST frame with blk_oldsp != stack height\n");

          /* First item is at [1] oddly, not [0] */
          frame->loop_list_first_item = PL_stack_base[cx->blk_loop.state_u.stack.basesp+1];

          frame->el.loop.state_u.stack.basesp = height - frame->el.loop.state_u.stack.basesp;
          frame->el.loop.state_u.stack.ix     = height - frame->el.loop.state_u.stack.ix;
          break;
        }
#endif
      }

      break;

    case CXt_EVAL: {
      if(!(cx->cx_type & CXp_TRYBLOCK))
        panic("TODO: handle CXt_EVAL without CXp_TRYBLOCK\n");
      if(cx->blk_eval.old_namesv)
        panic("TODO: handle cx->blk_eval.old_namesv\n");
      if(cx->blk_eval.cv)
        panic("TODO: handle cx->blk_eval.cv\n");
      if(cx->blk_eval.cur_top_env != PL_top_env)
        panic("TODO: handle cx->blk_eval.cur_top_env\n");

      /*
       * It seems we don't need to care about blk_eval.old_eval_root or
       * blk_eval.cur_text, and if we ignore these then it works fine via
       * string eval().
       *   https://rt.cpan.org/Ticket/Display.html?id=126036
       */

      frame->type = CXt_EVAL;
      frame->gimme = cx->blk_gimme;

#ifdef HAVE_CX_TRY
      if(CxTRY(cx))
        frame->type |= CXp_TRY;
#endif

      frame->el.eval.retop = cx->blk_eval.retop;

      break;
    }

    default:
      panic("TODO: unsure how to handle a context frame of type %d\n", CxTYPE(cx));
  }

  frame->mortallen = 0;
  frame->mortals = NULL;
  if(oldtmpsfloor == -2) {
    /* Don't worry about it; the next level down will save us */
  }
  else {
    /* Save the mortals! */
    SV **tmpsbase = PL_tmps_stack + PL_tmps_floor + 1;
    I32 i;

    frame->mortallen = (I32)(PL_tmps_ix - PL_tmps_floor);
    if(frame->mortallen) {
      Newx(frame->mortals, frame->mortallen, SV *);
      for(i = 0; i < frame->mortallen; i++) {
        frame->mortals[i] = tmpsbase[i];
        tmpsbase[i] = NULL;
      }
    }

    PL_tmps_ix = PL_tmps_floor;
    PL_tmps_floor = oldtmpsfloor;
  }
}

#define suspendedstate_suspend(state, cv)  MY_suspendedstate_suspend(aTHX_ state, cv)
static void MY_suspendedstate_suspend(pTHX_ SuspendedState *state, CV *cv)
{
  I32 cxix;
  PADOFFSET padnames_max, pad_max, i;
  PADLIST *plist;
  PADNAME **padnames;
  PAD *pad;
  SV **padsvs;

  state->frames = NULL;

  for(cxix = cxstack_ix; cxix; cxix--) {
    PERL_CONTEXT *cx = &cxstack[cxix];
    if(CxTYPE(cx) == CXt_SUB)
      break;

    SuspendedFrame *frame;

    Newx(frame, 1, SuspendedFrame);
    frame->next = state->frames;
    state->frames = frame;
#ifdef HAVE_ITERVAR
    frame->itervar = NULL;
#endif

    suspend_frame(frame, cx);
  }

  /* Now steal the lexical SVs from the PAD */
  plist = CvPADLIST(cv);

  padnames = PadnamelistARRAY(PadlistNAMES(plist));
  padnames_max = PadnamelistMAX(PadlistNAMES(plist));

  pad = PadlistARRAY(plist)[CvDEPTH(cv)];
  pad_max = PadMAX(pad);
  padsvs = PadARRAY(pad);

  state->padlen = PadMAX(pad) + 1;
  Newx(state->padslots, state->padlen - 1, SV *);

  /* slot 0 is always the @_ AV */
  for(i = 1; i <= pad_max; i++) {
    PADNAME *pname = (i <= padnames_max) ? padnames[i] : NULL;

    if(!padname_is_normal_lexical(pname)) {
      state->padslots[i-1] = NULL;
      continue;
    }

    if(PadnameIsSTATE(pname)) {
      state->padslots[i-1] = SvREFCNT_inc(padsvs[i]);
    }
    else {
      /* Don't fiddle refcount */
      state->padslots[i-1] = padsvs[i];
      switch(PadnamePV(pname)[0]) {
        case '@':
          padsvs[i] = MUTABLE_SV(newAV());
          break;
        case '%':
          padsvs[i] = MUTABLE_SV(newHV());
          break;
        case '$':
          padsvs[i] = newSV(0);
          break;
        default:
          panic("TODO: unsure how to steal and switch pad slot with pname %s\n",
            PadnamePV(pname));
      }
      SvPADMY_on(padsvs[i]);
    }
  }

  if(PL_curpm)
    state->curpm  = PL_curpm;
  else
    state->curpm = NULL;

#if !HAVE_PERL_VERSION(5, 24, 0)
  /* perls before v5.24 will crash if we try to do this at all */
  if(0)
#elif HAVE_PERL_VERSION(5, 36, 0)
  /* perls 5.36 onwards have CvSIGNATURE; we don't need to bother doing this
   * inside signatured subs */
  if(!CvSIGNATURE(cv))
#endif
  /* on perl versions between those, just do it unconditionally */
  {
    state->defav = GvAV(PL_defgv); /* steal */

    AV *av = GvAV(PL_defgv) = newAV();
    AvREAL_off(av);

    if(PAD_SVl(0) == (SV *)state->defav) {
      /* Steal that one too */
      SvREFCNT_dec(PAD_SVl(0));
      PAD_SVl(0) = SvREFCNT_inc(av);
    }
  }

  dounwind(cxix);
}

#define resume_frame(frame, cx)  MY_resume_frame(aTHX_ frame)
static void MY_resume_frame(pTHX_ SuspendedFrame *frame)
{
  I32 i;

  PERL_CONTEXT *cx;
  I32 was_scopestack_ix = PL_scopestack_ix;

  switch(frame->type) {
    case CXt_BLOCK:
#if !HAVE_PERL_VERSION(5, 24, 0)
      ENTER_with_name("block");
      SAVETMPS;
#endif
      cx = cx_pushblock(CXt_BLOCK, frame->gimme, PL_stack_sp, PL_savestack_ix);
      /* nothing else special */
      break;

    case CXt_LOOP_PLAIN:
#if !HAVE_PERL_VERSION(5, 24, 0)
      ENTER_with_name("loop1");
      SAVETMPS;
      ENTER_with_name("loop2");
#endif
      cx = cx_pushblock(frame->type, frame->gimme, PL_stack_sp, PL_savestack_ix);
      /* don't call cx_pushloop_plain() because it will get this wrong */
      cx->blk_loop = frame->el.loop;
      break;

#if HAVE_PERL_VERSION(5, 24, 0)
    case CXt_LOOP_ARY:
    case CXt_LOOP_LIST:
#else
    case CXt_LOOP_FOR:
#endif
    case CXt_LOOP_LAZYSV:
    case CXt_LOOP_LAZYIV:
#if !HAVE_PERL_VERSION(5, 24, 0)
      ENTER_with_name("loop1");
      SAVETMPS;
      ENTER_with_name("loop2");
#endif
      cx = cx_pushblock(frame->type, frame->gimme, PL_stack_sp, PL_savestack_ix);
      /* don't call cx_pushloop_plain() because it will get this wrong */
      cx->blk_loop = frame->el.loop;
#if HAVE_PERL_VERSION(5, 24, 0)
      cx->cx_type |= CXp_FOR_PAD;
#endif

#ifdef HAVE_ITERVAR
#  ifdef USE_ITHREADS
      cx->blk_loop.itervar_u.svp = (SV **)PL_comppad;
#  else 
      cx->blk_loop.itervar_u.svp = &PAD_SVl(cx->blk_loop.my_op->op_targ);
#  endif
      SvREFCNT_dec(*CxITERVAR(cx));
      *CxITERVAR(cx) = frame->itervar;
      frame->itervar = NULL;
#else
      cx->blk_loop.itervar_u.svp = &PAD_SVl(cx->blk_loop.my_op->op_targ);
#endif
      break;

    case CXt_EVAL:
      if(CATCH_GET)
        panic("Too late to docatch()\n");

#if !HAVE_PERL_VERSION(5, 24, 0)
      ENTER_with_name("eval_scope");
      SAVETMPS;
#endif
      cx = cx_pushblock(CXt_EVAL|CXp_TRYBLOCK, frame->gimme,
        PL_stack_sp, PL_savestack_ix);
      cx_pusheval(cx, frame->el.eval.retop, NULL);
      PL_in_eval = EVAL_INEVAL;
      CLEAR_ERRSV();
      break;

#ifdef HAVE_CX_TRY
    case CXt_EVAL|CXp_TRY:
      if(CATCH_GET)
        panic("Too late to docatch()\n");

      cx = cx_pushblock(CXt_EVAL|CXp_EVALBLOCK|CXp_TRY, frame->gimme,
        PL_stack_sp, PL_savestack_ix);
      cx_pushtry(cx, frame->el.eval.retop);
      PL_in_eval = EVAL_INEVAL;
      CLEAR_ERRSV();
      break;
#endif

    default:
      panic("TODO: Unsure how to restore a %d frame\n", frame->type);
  }

  if(frame->stacklen) {
    dSP;
    EXTEND(SP, frame->stacklen);

    for(i = 0; i < frame->stacklen; i++) {
      PUSHs(frame->stack[i]);
    }

    Safefree(frame->stack);
    PUTBACK;
  }

  if(frame->marklen) {
    for(i = 0; i < frame->marklen; i++) {
      I32 absmark = frame->marks[i] + cx->blk_oldsp;
      PUSHMARK(PL_stack_base + absmark);
    }

    Safefree(frame->marks);
  }

  cx->blk_oldcop = frame->oldcop;

  for(i = frame->savedlen - 1; i >= 0; i--) {
    struct Saved *saved = &frame->saved[i];

    switch(saved->type) {
      case SAVEt_CLEARSV:
        save_clearsv(PL_curpad + saved->u.clearpad.padix);
        break;

#ifdef SAVEt_CLEARPADRANGE
      case SAVEt_CLEARPADRANGE:
        save_clearpadrange(saved->u.clearpad.padix, saved->u.clearpad.count);
        break;
#endif

      case SAVEt_DESTRUCTOR_X:
        save_pushptrptr(saved->u.dx.func, saved->u.dx.data, saved->type);
        break;

      case SAVEt_COMPPAD:
        PL_comppad = saved->saved.ptr;
        save_pushptr(PL_comppad, saved->type);

        PL_comppad = saved->cur.ptr;
        PL_curpad = PL_comppad ? AvARRAY(PL_comppad) : NULL;
        break;

      case SAVEt_FREEPV:
        save_freepv(saved->saved.ptr);
        break;

      case SAVEt_FREESV:
        save_freesv(saved->saved.sv);
        break;

      case SAVEt_INT:
        *(saved->u.iptr) = saved->saved.i;
        save_int(saved->u.iptr);

        *(saved->u.iptr) = saved->cur.i;
        break;

      case SAVEt_SV:
        save_pushptrptr(saved->u.gv, SvREFCNT_inc(saved->saved.sv), SAVEt_SV);

        SvREFCNT_dec(GvSV(saved->u.gv));
        GvSV(saved->u.gv) = saved->cur.sv;
        break;

      case SAVEt_ITEM:
        save_pushptrptr(saved->u.sv, saved->saved.sv, SAVEt_ITEM);

        sv_setsv(saved->u.sv, saved->cur.sv);
        SvREFCNT_dec(saved->cur.sv);
        break;

      case SAVEt_SPTR:
        PL_curpad[saved->u.padix] = saved->saved.sv;
        SAVESPTR(PL_curpad[saved->u.padix]);

        SvREFCNT_dec(PL_curpad[saved->u.padix]);
        PL_curpad[saved->u.padix] = saved->cur.sv;
        break;

#ifdef SAVEt_STRLEN
      case SAVEt_STRLEN:
        *(saved->u.lenptr) = saved->saved.len;
        Perl_save_strlen(aTHX_ saved->u.lenptr);

        *(saved->u.lenptr) = saved->cur.len;
        break;
#endif

      case SAVEt_PADSV_AND_MORTALIZE:
        PL_curpad[saved->u.padix] = saved->saved.sv;
        save_padsv_and_mortalize(saved->u.padix);

        SvREFCNT_dec(PL_curpad[saved->u.padix]);
        PL_curpad[saved->u.padix] = saved->cur.sv;
        break;

      case SAVEt_SET_SVFLAGS:
        /*
        save_set_svflags(saved->u.svflags.sv,
          saved->u.svflags.mask, saved->u.svflags.set);
        */
        break;

      default:
        panic("TODO: Unsure how to restore a %d savestack entry\n", saved->type);
    }
  }

  if(frame->saved)
    Safefree(frame->saved);

  if(frame->scopes) {
#ifdef DEBUG
    if(PL_scopestack_ix - was_scopestack_ix < frame->scopes) {
      fprintf(stderr, "TODO ARG still more scopes to ENTER\n");
    }
#endif
  }

  if(frame->mortallen) {
    for(i = 0; i < frame->mortallen; i++) {
      sv_2mortal(frame->mortals[i]);
    }

    Safefree(frame->mortals);
    frame->mortals = NULL;
  }

  switch(frame->type) {
#if !HAVE_PERL_VERSION(5, 24, 0)
    case CXt_LOOP_FOR:
      if(!cx->blk_loop.state_u.ary.ary) {
        I32 height = PL_stack_sp - PL_stack_base - frame->stacklen;
        cx->blk_loop.state_u.ary.ix = height - cx->blk_loop.state_u.ary.ix;
      }
      break;
#endif

#if HAVE_PERL_VERSION(5, 24, 0)
    case CXt_LOOP_LIST: {
      I32 height = PL_stack_sp - PL_stack_base - frame->stacklen;

      cx->blk_loop.state_u.stack.basesp = height - cx->blk_loop.state_u.stack.basesp;
      cx->blk_loop.state_u.stack.ix     = height - cx->blk_loop.state_u.stack.ix;

      /* For consistency; check that the first SV in the list is in the right
       * place. If so we presume the others are
       */
      if(PL_stack_base[cx->blk_loop.state_u.stack.basesp+1] == frame->loop_list_first_item)
        break;

      /* First item is at [1] oddly, not [0] */
#ifdef debug_sv_summary
      fprintf(stderr, "F:AA: consistency check resume LOOP_LIST with first=%p:",
        frame->loop_list_first_item);
      debug_sv_summary(frame->loop_list_first_item);
      fprintf(stderr, " stackitem=%p:", PL_stack_base[frame->el.loop.state_u.stack.basesp + 1]);
      debug_sv_summary(PL_stack_base[frame->el.loop.state_u.stack.basesp]);
      fprintf(stderr, "\n");
#endif
      panic("ARGH CXt_LOOP_LIST consistency check failed\n");
      break;
    }
#endif
  }
}

#define suspendedstate_resume(state, cv)  MY_suspendedstate_resume(aTHX_ state, cv)
static void MY_suspendedstate_resume(pTHX_ SuspendedState *state, CV *cv)
{
  I32 i;

  if(state->padlen) {
    PAD *pad = PadlistARRAY(CvPADLIST(cv))[CvDEPTH(cv)];
    PADOFFSET i;

    /* slot 0 is always the @_ AV */
    for(i = 1; i < state->padlen; i++) {
      if(!state->padslots[i-1])
        continue;

      SvREFCNT_dec(PadARRAY(pad)[i]);
      PadARRAY(pad)[i] = state->padslots[i-1];
    }

    Safefree(state->padslots);
    state->padslots = NULL;
    state->padlen = 0;
  }

  SuspendedFrame *frame, *next;
  for(frame = state->frames; frame; frame = next) {
    next = frame->next;

    resume_frame(frame, cx);

    Safefree(frame);
  }
  state->frames = NULL;

  if(state->curpm)
    PL_curpm = state->curpm;

  if(state->defav) {
    SvREFCNT_dec(GvAV(PL_defgv));
    SvREFCNT_dec(PAD_SVl(0));

    GvAV(PL_defgv) = state->defav;
    PAD_SVl(0) = SvREFCNT_inc((SV *)state->defav);
    state->defav = NULL;
  }
}

#define suspendedstate_cancel(state)  MY_suspendedstate_cancel(aTHX_ state)
static void MY_suspendedstate_cancel(pTHX_ SuspendedState *state)
{
  SuspendedFrame *frame;
  for(frame = state->frames; frame; frame = frame->next) {
    I32 i;

    for(i = frame->savedlen - 1; i >= 0; i--) {
      struct Saved *saved = &frame->saved[i];

      switch(saved->type) {
        case SAVEt_DESTRUCTOR_X:
          /* We have to run destructors to ensure that defer {} and try/finally
           * work correctly
           *   https://rt.cpan.org/Ticket/Display.html?id=135351
           */
          (*saved->u.dx.func)(aTHX_ saved->u.dx.data);
          break;
      }
    }
  }
}

/*
 * Pre-creation assistance
 */

enum {
  PRECREATE_CANCEL,
  PRECREATE_MODHOOKDATA,
};

#define get_precreate_padix()  S_get_precreate_padix(aTHX)
PADOFFSET S_get_precreate_padix(pTHX)
{
  return SvUV(SvRV(*hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/*precreate_padix", 0)));
}

#define get_or_create_precreate_padix()  S_get_or_create_precreate_padix(aTHX)
PADOFFSET S_get_or_create_precreate_padix(pTHX)
{
  SV *sv;
  PADOFFSET padix = SvUV(sv = SvRV(*hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/*precreate_padix", 0)));
  if(!padix) {
    padix = pad_add_name_pvs("@(Future::AsyncAwait/precancel)", 0, NULL, NULL);
    sv_setuv(sv, padix);

    PADOFFSET p2 = pad_add_name_pvs("%(Future::AsyncAwait/premodhookdata)", 0, NULL, NULL);
    assert(p2 == padix + PRECREATE_MODHOOKDATA);
  }

  return padix;
}

/*
 * Some Future class helper functions
 */

#define future_classname()  MY_future_classname(aTHX)
static SV *MY_future_classname(pTHX)
{
  /* cop_hints_fetch_* return a mortal copy so this is fine */
  SV *class = cop_hints_fetch_pvs(PL_curcop, "Future::AsyncAwait/future", 0);
  if(class == &PL_sv_placeholder)
    class = sv_2mortal(newSVpvn("Future", 6));

  return class;
}

#define future_done_from_stack(f, mark)  MY_future_done_from_stack(aTHX_ f, mark)
static SV *MY_future_done_from_stack(pTHX_ SV *f, SV **mark)
{
  dSP;
  SV **svp;

  EXTEND(SP, 1);

  ENTER_with_name("future_done_from_stack");
  SAVETMPS;

  PUSHMARK(mark);
  SV **bottom = mark + 1;
  const char *method;

  /* splice the class name 'Future' in to the start of the stack */

  for (svp = SP; svp >= bottom; svp--) {
    *(svp+1) = *svp;
  }

  if(f) {
    assert(SvROK(f));
    *bottom = f;
    method  = "AWAIT_DONE";
  }
  else {
    *bottom = future_classname();
    method  = "AWAIT_NEW_DONE";
  }
  SP++;
  PUTBACK;

  call_method(method, G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE_with_name("future_done_from_stack");

  return ret;
}

#define future_fail(f, failure)  MY_future_fail(aTHX_ f, failure)
static SV *MY_future_fail(pTHX_ SV *f, SV *failure)
{
  dSP;

  ENTER_with_name("future_fail");
  SAVETMPS;

  const char *method;

  PUSHMARK(SP);
  if(f) {
    assert(SvROK(f));
    PUSHs(f);
    method = "AWAIT_FAIL";
  }
  else {
    PUSHs(future_classname());
    method = "AWAIT_NEW_FAIL";
  }
  mPUSHs(newSVsv(failure));
  PUTBACK;

  call_method(method, G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE_with_name("future_fail");

  return ret;
}

#define future_new_from_proto(proto)  MY_future_new_from_proto(aTHX_ proto)
static SV *MY_future_new_from_proto(pTHX_ SV *proto)
{
  assert(SvROK(proto));

  dSP;

  ENTER_with_name("future_new_from_proto");
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(proto);
  PUTBACK;

  call_method("AWAIT_CLONE", G_SCALAR);

  SPAGAIN;

  SV *f = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE_with_name("future_new_from_proto");

  if(!SvROK(f))
    croak("Expected Future->new to yield a new reference");

  assert(SvREFCNT(f) == 1);
  assert(SvREFCNT(SvRV(f)) == 1);
  return f;
}

#define future_is_ready(f)      MY_future_check(aTHX_ f, "AWAIT_IS_READY")
#define future_is_cancelled(f)  MY_future_check(aTHX_ f, "AWAIT_IS_CANCELLED")
static bool MY_future_check(pTHX_ SV *f, const char *method)
{
  dSP;

  if(!f || !SvOK(f))
    panic("ARGH future_check() on undefined value\n");
  if(!SvROK(f))
    panic("ARGH future_check() on non-reference\n");

  ENTER_with_name("future_check");
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(f);
  PUTBACK;

  call_method(method, G_SCALAR);

  SPAGAIN;

  bool ret = SvTRUEx(POPs);

  PUTBACK;
  FREETMPS;
  LEAVE_with_name("future_check");

  return ret;
}

#define future_get_to_stack(f, gimme)  MY_future_get_to_stack(aTHX_ f, gimme)
static void MY_future_get_to_stack(pTHX_ SV *f, I32 gimme)
{
  dSP;

  ENTER_with_name("future_get_to_stack");

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(f);
  PUTBACK;

  call_method("AWAIT_GET", gimme);

  LEAVE_with_name("future_get_to_stack");
}

#define future_on_ready(f, code)  MY_future_on_ready(aTHX_ f, code)
static void MY_future_on_ready(pTHX_ SV *f, CV *code)
{
  dSP;

  ENTER_with_name("future_on_ready");
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(f);
  mPUSHs(newRV_inc((SV *)code));
  PUTBACK;

  call_method("AWAIT_ON_READY", G_VOID);

  FREETMPS;
  LEAVE_with_name("future_on_ready");
}

#define future_on_cancel(f, code)  MY_future_on_cancel(aTHX_ f, code)
static void MY_future_on_cancel(pTHX_ SV *f, SV *code)
{
  dSP;

  ENTER_with_name("future_on_cancel");
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(f);
  mPUSHs(code);
  PUTBACK;

  call_method("AWAIT_ON_CANCEL", G_VOID);

  FREETMPS;
  LEAVE_with_name("future_on_cancel");
}

#define future_chain_on_cancel(f1, f2)  MY_future_chain_on_cancel(aTHX_ f1, f2)
static void MY_future_chain_on_cancel(pTHX_ SV *f1, SV *f2)
{
  dSP;

  ENTER_with_name("future_chain_on_cancel");
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  PUSHs(f1);
  PUSHs(f2);
  PUTBACK;

  call_method("AWAIT_CHAIN_CANCEL", G_VOID);

  FREETMPS;
  LEAVE_with_name("future_chain_on_cancel");
}

#define future_await_toplevel(f)  MY_future_await_toplevel(aTHX_ f)
static void MY_future_await_toplevel(pTHX_ SV *f)
{
  dSP;

  ENTER_with_name("future_await_toplevel");

  PUSHMARK(SP);
  EXTEND(SP, 1);
  PUSHs(f);
  PUTBACK;

  call_method("AWAIT_WAIT", GIMME_V);

  LEAVE_with_name("future_await_toplevel");
}

/*
 * API functions
 */

static HV *get_modhookdata(pTHX_ CV *cv, U32 flags, PADOFFSET precreate_padix)
{
  SuspendedState *state = suspendedstate_get(cv);

  if(!state) {
    if(!precreate_padix)
      return NULL;

    if(!(flags & FAA_MODHOOK_CREATE))
      return NULL;

    return (HV *)PAD_SVl(precreate_padix + PRECREATE_MODHOOKDATA);
  }

  if((flags & FAA_MODHOOK_CREATE) && !state->modhookdata)
    state->modhookdata = newHV();

  return state->modhookdata;
}

/*
 * Custom ops
 */

static XOP xop_enterasync;
static OP *pp_enterasync(pTHX)
{
  PADOFFSET precreate_padix = PL_op->op_targ;

  if(precreate_padix) {
    save_clearsv(&PAD_SVl(precreate_padix + PRECREATE_CANCEL));
    save_clearsv(&PAD_SVl(precreate_padix + PRECREATE_MODHOOKDATA));
  }

  return PL_op->op_next;
}

static XOP xop_leaveasync;
static OP *pp_leaveasync(pTHX)
{
  dSP;
  dMARK;

  SV *f = NULL;
  SV *ret = NULL;

  SuspendedState *state = suspendedstate_get(find_runcv(0));
  if(state && state->returning_future) {
    f = state->returning_future;
    state->returning_future = NULL;
  }

  if(f && !SvROK(f)) {
    /* async sub was abandoned. We just have to tidy up a bit and finish */

    if(SvTRUE(ERRSV)) {
      /* This error will otherwise go unreported; best we can do is warn() it */
      CV *curcv = find_runcv(0);
      GV *gv = CvGV(curcv);
      if(!CvANON(curcv))
        warn("Abandoned async sub %s::%s failed: %" SVf,
          HvNAME(GvSTASH(gv)), GvNAME(gv), SVfARG(ERRSV));
      else
        warn("Abandoned async sub CODE(0x%p) in package %s failed: %" SVf,
          curcv, HvNAME(GvSTASH(gv)), SVfARG(ERRSV));
    }

    goto abort;
  }

  if(SvTRUE(ERRSV)) {
    ret = future_fail(f, ERRSV);
  }
  else {
    ret = future_done_from_stack(f, mark);
  }

  SPAGAIN;

abort: ; /* statement to keep C compilers happy */
  PERL_CONTEXT *cx = CX_CUR();

  SV **oldsp = PL_stack_base + cx->blk_oldsp;

  /* Pop extraneous stack items */
  while(SP > oldsp)
    POPs;

  if(ret) {
    EXTEND(SP, 1);
    mPUSHs(ret);
    PUTBACK;
  }

  if(f)
    SvREFCNT_dec(f);

  return PL_op->op_next;
}

static XOP xop_await;
static OP *pp_await(pTHX)
{
  /* We arrive here in either of two cases:
   *   1) Normal code flow has executed an 'await F' expression
   *   2) A previous await operation is resuming
   * Distinguish which by inspecting the state (if any) of the suspended context
   * magic on the containing CV
   */
  dSP;
  SV *f;

  CV *curcv = find_runcv(0);
  CV *origcv = curcv;
  bool defer_mortal_curcv = FALSE;

  PADOFFSET precreate_padix = PL_op->op_targ;
  /* Must fetch precancel AV now, before any pad fiddling or cv copy */
  AV *precancel = precreate_padix ? (AV *)PAD_SVl(precreate_padix + PRECREATE_CANCEL) : NULL;

  SuspendedState *state = suspendedstate_get(curcv);

  if(state && state->awaiting_future && CATCH_GET) {
    /* If we don't do this we get all the mess that is
     *   https://rt.cpan.org/Ticket/Display.html?id=126037
     */
    return docatch(pp_await);
  }

  struct HookRegistrations *regs = registrations(FALSE);

  if(state && state->curcop)
    PL_curcop = state->curcop;

  TRACEPRINT("ENTER await curcv=%p [%s:%d]\n", curcv, CopFILE(PL_curcop), CopLINE(PL_curcop));
  if(state)
    TRACEPRINT(" (state=%p/{awaiting_future=%p, returning_future=%p})\n",
      state, state->awaiting_future, state->returning_future);
  else
    TRACEPRINT(" (no state)\n");

  if(state) {
    if(!SvROK(state->returning_future) || future_is_cancelled(state->returning_future)) {
      if(!SvROK(state->returning_future)) {
        GV *gv = CvGV(curcv);
        if(!CvANON(curcv))
          warn("Suspended async sub %s::%s lost its returning future", HvNAME(GvSTASH(gv)), GvNAME(gv));
        else
          warn("Suspended async sub CODE(0x%p) in package %s lost its returning future", curcv, HvNAME(GvSTASH(gv)));
      }

      TRACEPRINT("  CANCELLED\n");

      suspendedstate_cancel(state);

      PUSHMARK(SP);
      PUTBACK;
      return PL_ppaddr[OP_RETURN](aTHX);
    }
  }

  if(state && state->awaiting_future) {
    I32 orig_height;

    TRACEPRINT("  RESUME\n");

    f = state->awaiting_future;
    sv_2mortal(state->awaiting_future);
    state->awaiting_future = NULL;

    /* Before we restore the stack we first need to POP the caller's
     * arguments, as we don't care about those
     */
    orig_height = CX_CUR()->blk_oldsp;
    while(sp > PL_stack_base + orig_height)
      POPs;
    PUTBACK;

    /* We also need to clean up the markstack and insert a new mark at the
     * beginning
     */
    orig_height = CX_CUR()->blk_oldmarksp;
    while(PL_markstack_ptr > PL_markstack + orig_height)
      POPMARK;
    PUSHMARK(SP);

    /* Legacy ones first */
    {
      SV **hookp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/suspendhook", FALSE);
      if(hookp && SvOK(*hookp) && SvUV(*hookp)) {
        warn("Invoking legacy Future::AsyncAwait suspendhook for PRERESUME phase");
        SuspendHookFunc *hook = INT2PTR(SuspendHookFunc *, SvUV(*hookp));
        if(!state->modhookdata)
          state->modhookdata = newHV();

        (*hook)(aTHX_ FAA_PHASE_PRERESUME, curcv, state->modhookdata);
      }
    }

    /* New ones after */
    if(regs)
      RUN_HOOKS_REV(pre_resume, curcv, state->modhookdata);

    suspendedstate_resume(state, curcv);

    if(regs)
      RUN_HOOKS_FWD(post_resume, curcv, state->modhookdata);

#ifdef DEBUG_SHOW_STACKS
    debug_showstack("Stack after resume");
#endif
  }
  else {
    f = POPs;
    PUTBACK;
  }

  if(!sv_isobject(f))
    croak("Expected a blessed object reference to await");

  if(PL_op->op_flags & OPf_SPECIAL) {
    future_await_toplevel(f);
    return PL_op->op_next;
  }

  if(future_is_ready(f)) {
    assert(CvDEPTH(curcv) > 0);
    TRACEPRINT("  READY\n");
    if(state)
      state->curcop = NULL;
    /* This might throw */
    future_get_to_stack(f, GIMME_V);
    TRACEPRINT("LEAVE await curcv=%p [%s:%d]\n", curcv, CopFILE(PL_curcop), CopLINE(PL_curcop));
    return PL_op->op_next;
  }

#ifdef DEBUG_SHOW_STACKS
  debug_showstack("Stack before suspend");
#endif

  if(!state) {
    /* Clone the CV and then attach suspendedstate magic to it */

    /* No point copying a normal lexical slot because the suspend logic is
     * about to capture all the pad slots from the running CV (orig) and
     * they'll be restored into this new one later by resume.
     */
    CV *runcv = curcv;
    curcv = cv_copy_flags(runcv, CV_COPY_NULL_LEXICALS);
    state = suspendedstate_new(curcv);

    HV *premodhookdata = precreate_padix ? (HV *)PAD_SVl(precreate_padix + PRECREATE_MODHOOKDATA) : NULL;
    if(premodhookdata) {
      state->modhookdata = premodhookdata;
      PAD_SVl(precreate_padix + PRECREATE_MODHOOKDATA) = NULL; /* steal it */
    }

    if(regs) {
      if(!state->modhookdata)
        state->modhookdata = newHV();
      RUN_HOOKS_FWD(post_cv_copy, runcv, curcv, state->modhookdata);
    }

    TRACEPRINT("  SUSPEND cloned CV->%p\n", curcv);
    defer_mortal_curcv = TRUE;
  }
  else {
    TRACEPRINT("  SUSPEND reuse CV\n");
  }

  state->curcop = PL_curcop;

  if(regs)
    RUN_HOOKS_REV(pre_suspend, curcv, state->modhookdata);

  suspendedstate_suspend(state, origcv);

  /* New ones first */
  if(regs)
    RUN_HOOKS_FWD(post_suspend, curcv, state->modhookdata);

  /* Legacy ones after */
  {
    SV **hookp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/suspendhook", FALSE);
    if(hookp && SvOK(*hookp) && SvUV(*hookp)) {
      warn("Invoking legacy Future::AsyncAwait suspendhook for POSTSUSPEND phase");
      SuspendHookFunc *hook = INT2PTR(SuspendHookFunc *, SvUV(*hookp));
        if(!state->modhookdata)
          state->modhookdata = newHV();

      (*hook)(aTHX_ FAA_PHASE_POSTSUSPEND, curcv, state->modhookdata);
    }
  }

  CvSTART(curcv) = PL_op; /* resume from here */
  future_on_ready(f, curcv);

  /* If the Future implementation's ->AWAIT_ON_READY failed to capture this CV
   * then we'll segfault later after SvREFCNT_dec() on it. We can at least
   * detect that here
   */
  if(SvREFCNT(curcv) < 2) {
    croak("AWAIT_ON_READY failed to capture the CV");
  }

  state->awaiting_future = newSVsv(f);
  sv_rvweaken(state->awaiting_future);

  if(!state->returning_future) {
    state->returning_future = future_new_from_proto(f);

    if(precancel) {
      I32 i;
      for(i = 0; i < av_count(precancel); i++)
        future_on_cancel(state->returning_future, AvARRAY(precancel)[i]);
      AvFILLp(precancel) = -1;
    }
#ifndef HAVE_FUTURE_CHAIN_CANCEL
    /* We can't chain the cancellation but we do need a different way to
     * invoke the defer and finally blocks
     */
    future_on_cancel(state->returning_future, newRV_inc((SV *)curcv));
#endif
  }

  if(defer_mortal_curcv)
    SvREFCNT_dec((SV *)curcv);

  PUSHMARK(SP);
  mPUSHs(newSVsv(state->returning_future));
  PUTBACK;

  if(!SvWEAKREF(state->returning_future))
    sv_rvweaken(state->returning_future);
  if(!SvROK(state->returning_future))
    panic("ARGH we lost state->returning_future for curcv=%p\n", curcv);

#ifdef HAVE_FUTURE_CHAIN_CANCEL
  future_chain_on_cancel(state->returning_future, state->awaiting_future);

  if(!SvROK(state->returning_future))
    panic("ARGH we lost state->returning_future for curcv=%p\n", curcv);
#endif

  if(!SvROK(state->awaiting_future))
    panic("ARGH we lost state->awaiting_future for curcv=%p\n", curcv);

  TRACEPRINT("LEAVE await curcv=%p [%s:%d]\n", curcv, CopFILE(PL_curcop), CopLINE(PL_curcop));

  return PL_ppaddr[OP_RETURN](aTHX);
}

static XOP xop_pushcancel;
static OP *pp_pushcancel(pTHX)
{
  SuspendedState *state = suspendedstate_get(find_runcv(0));

  CV *on_cancel = cv_clone((CV *)cSVOP->op_sv);

  if(state && state->returning_future) {
    future_on_cancel(state->returning_future, newRV_noinc((SV *)on_cancel));
  }
  else {
    PADOFFSET precreate_padix = PL_op->op_targ;
    AV *precancel = (AV *)PAD_SVl(precreate_padix + PRECREATE_CANCEL);
    av_push(precancel, newRV_noinc((SV *)on_cancel));
  }

  return PL_op->op_next;
}

enum {
  NO_FORBID,
  FORBID_FOREACH_NONLEXICAL,
  FORBID_MAP,
  FORBID_GREP,
};

static void check_optree(pTHX_ OP *op, int forbid, COP **last_cop);
static void check_optree(pTHX_ OP *op, int forbid, COP **last_cop)
{
  OP *op_first;
  OP *kid = NULL;

  if(OP_CLASS(op) == OA_COP)
    *last_cop = (COP *)op;

  switch(op->op_type) {
    case OP_LEAVELOOP:
      if((op_first = cUNOPx(op)->op_first)->op_type != OP_ENTERITER)
        break;

      /* This is a foreach loop of some kind. If it's not using a lexical
       * iterator variable, disallow await inside the body.
       * Check the first child, then apply forbid to the remainder of the body
       */
      check_optree(aTHX_ op_first, forbid, last_cop);
      kid = OpSIBLING(op_first);

      if(!op_first->op_targ)
        forbid = FORBID_FOREACH_NONLEXICAL;
      break;

    case OP_MAPSTART:
    case OP_GREPSTART:
      /* children are: PUSHMARK, BODY, ITEMS... */
      if((op_first = cUNOPx(op)->op_first)->op_type != OP_PUSHMARK)
        break;

      kid = OpSIBLING(op_first);
      check_optree(aTHX_ kid,
        op->op_type == OP_MAPSTART ? FORBID_MAP : FORBID_GREP, last_cop);

      kid = OpSIBLING(kid);
      break;

    case OP_CUSTOM:
      if(op->op_ppaddr != &pp_await)
        break;
      if(!forbid)
        /* await is allowed here */
        break;

      char *reason;
      switch(forbid) {
        case FORBID_FOREACH_NONLEXICAL:
          reason = "foreach on non-lexical iterator variable";
          break;
        case FORBID_MAP:
          reason = "map";
          break;
        case FORBID_GREP:
          reason = "grep";
          break;
      }

      croak("await is not allowed inside %s at %s line %d.\n",
        reason, CopFILE(*last_cop), CopLINE(*last_cop));
      break;
  }

  if(op->op_flags & OPf_KIDS) {
    if(!kid)
      kid = cUNOPx(op)->op_first;
    for(; kid; kid = OpSIBLING(kid))
      check_optree(aTHX_ kid, forbid, last_cop);
  }
}

/*
 * Keyword plugins
 */

static void parse_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  /* Save the identity of the currently-compiling sub so that 
   * await_keyword_plugin() can check
   */
  hv_stores(GvHV(PL_hintgv), "Future::AsyncAwait/PL_compcv", newSVuv(PTR2UV(PL_compcv)));

  hv_stores(GvHV(PL_hintgv), "Future::AsyncAwait/*precreate_padix", newRV_noinc(newSVuv(0)));
}

static void parse_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  /* body might be NULL if an error happened, or if this was a bodyless
   * prototype or required method declaration
   */
  if(!ctx->body)
    return;

  COP *last_cop = PL_curcop;
  check_optree(aTHX_ ctx->body, NO_FORBID, &last_cop);

#ifdef HAVE_OP_ARGCHECK
  /* If the sub body is using signatures, we want to pull the OP_ARGCHECK
   * outside the try block. This has two advantages:
   *   1. arity checks appear synchronous from the perspective of the caller;
   *      immediate exceptions rather than failed Futures
   *   2. it makes Syntax::Keyword::MultiSub able to handle `async multi sub`
   */
  OP *argcheckop = NULL;
  if(ctx->body->op_type == OP_LINESEQ) {
    OP *lineseq = ctx->body;
    OP *o = cLISTOPx(lineseq)->op_first;
    /* OP_ARGCHECK is often found inside a second inner nested OP_LINESEQ that
     * was op_null'ed out
     */
    if(o->op_type == OP_NULL && o->op_flags & OPf_KIDS &&
        cUNOPo->op_first->op_type == OP_LINESEQ) {
      lineseq = cUNOPo->op_first;
      o = cLISTOPx(lineseq)->op_first;
    }
    if(o->op_type == OP_NEXTSTATE &&
        OpSIBLING(o)->op_type == OP_ARGCHECK) {
      /* Splice out the NEXTSTATE+ARGCHECK ops */
      argcheckop = o; /* technically actually the NEXTSTATE before it */

      o = OpSIBLING(OpSIBLING(o));
      OpMORESIB_set(OpSIBLING(argcheckop), NULL);

      cLISTOPx(lineseq)->op_first = o;
    }
  }
#endif

  /* turn block into
   *    NEXTSTATE; PUSHMARK; eval { BLOCK }; LEAVEASYNC
   */

  OP *body = newSTATEOP(0, NULL, NULL);

  PADOFFSET precreate_padix = get_precreate_padix();
  if(precreate_padix) {
    OP *enterasync;
    body = op_append_elem(OP_LINESEQ, body,
      enterasync = newOP_CUSTOM(&pp_enterasync, 0));

    enterasync->op_targ = precreate_padix;
  }

  body = op_append_elem(OP_LINESEQ, body, newOP(OP_PUSHMARK, 0));

  OP *try;
  body = op_append_elem(OP_LINESEQ, body, try = newUNOP(OP_ENTERTRY, 0, ctx->body));
  op_contextualize(try, G_ARRAY);

  body = op_append_elem(OP_LINESEQ, body, newOP_CUSTOM(&pp_leaveasync, OPf_WANT_SCALAR));

#ifdef HAVE_OP_ARGCHECK
  if(argcheckop) {
    assert(body->op_type == OP_LINESEQ);
    /* Splice the argcheckop back into the start of the lineseq */
    OP *o = argcheckop;
    while(OpSIBLING(o))
      o = OpSIBLING(o);

    OpMORESIB_set(o, cLISTOPx(body)->op_first);
    cLISTOPx(body)->op_first = argcheckop;
  }
#endif

  ctx->body = body;
}

static void parse_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  if(ctx->cv && CvLVALUE(ctx->cv))
    warn("Pointless use of :lvalue on async sub");
}

static struct XSParseSublikeHooks hooks_async = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "Future::AsyncAwait/async",
  .flags = XS_PARSE_SUBLIKE_FLAG_PREFIX|XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL|XS_PARSE_SUBLIKE_FLAG_ALLOW_PKGNAME,

  .post_blockstart = parse_post_blockstart,
  .pre_blockend    = parse_pre_blockend,
  .post_newcv      = parse_post_newcv,
};

static void check_await(pTHX_ void *hookdata)
{
  SV **asynccvp = hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/PL_compcv", 0);
  if(asynccvp && SvUV(*asynccvp) == PTR2UV(PL_compcv))
    ; /* await inside regular `async sub` */
  else if(PL_compcv == PL_main_cv)
    ; /* toplevel await */
  else
    croak(CvEVAL(PL_compcv) ?
      "await is not allowed inside string eval" :
      "Cannot 'await' outside of an 'async sub'");
}

static int build_await(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *expr = arg0->op;

  if(PL_compcv == PL_main_cv)
    *out = newUNOP_CUSTOM(&pp_await, OPf_SPECIAL, expr);
  else {
    *out = newUNOP_CUSTOM(&pp_await, 0, expr);

    (*out)->op_targ = get_precreate_padix();
  }

  return KEYWORD_PLUGIN_EXPR;
}

static struct XSParseKeywordHooks hooks_await = {
  .permit_hintkey = "Future::AsyncAwait/async",
  .check = &check_await,
  .piece1 = XPK_TERMEXPR_SCALARCTX,
  .build1 = &build_await,
};

static void check_cancel(pTHX_ void *hookdata)
{
  SV **asynccvp = hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/PL_compcv", 0);
  if(!asynccvp || SvUV(*asynccvp) != PTR2UV(PL_compcv))
    croak(CvEVAL(PL_compcv) ?
      "CANCEL is not allowed inside string eval" :
      "Cannot 'CANCEL' outside of an 'async sub'");

#ifdef WARN_EXPERIMENTAL
  if(!hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/experimental(cancel)", 0)) {
    Perl_ck_warner(aTHX_ packWARN(WARN_EXPERIMENTAL),
      "CANCEL block syntax is experimental and may be changed or removed without notice");
  }
#endif
}

static int build_cancel(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  CV *on_cancel = arg0->cv;
  OP *pushcancel;

  *out = op_prepend_elem(OP_LINESEQ,
    (pushcancel = newSVOP_CUSTOM(&pp_pushcancel, 0, (SV *)on_cancel)), NULL);

  pushcancel->op_targ = get_or_create_precreate_padix();

  return KEYWORD_PLUGIN_STMT;
}

static struct XSParseKeywordHooks hooks_cancel = {
  .permit_hintkey = "Future::AsyncAwait/async",
  .check = &check_cancel,
  .piece1 = XPK_ANONSUB,
  .build1 = &build_cancel,
};

/*
 * Back-compat support
 */

struct AsyncAwaitHookFuncs_v1
{
  U32 flags;
  void (*post_cv_copy)(pTHX_ CV *runcv, CV *cv, HV *modhookdata, void *hookdata);
  /* no pre_suspend */
  void (*post_suspend)(pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  void (*pre_resume)  (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
  /* no post_resume */
  void (*free)        (pTHX_ CV *cv, HV *modhookdata, void *hookdata);
};

static void register_faa_hook_v1(pTHX_ const struct AsyncAwaitHookFuncs_v1 *hookfuncs_v1, void *hookdata)
{
  /* No flags are recognised; complain if the caller requested any */
  if(hookfuncs_v1->flags)
    croak("Unrecognised hookfuncs->flags value %08x", hookfuncs_v1->flags);

  struct AsyncAwaitHookFuncs *hookfuncs;
  Newx(hookfuncs, 1, struct AsyncAwaitHookFuncs);

  hookfuncs->flags = 0;
  hookfuncs->post_cv_copy = hookfuncs_v1->post_cv_copy;
  hookfuncs->pre_suspend  = NULL;
  hookfuncs->post_suspend = hookfuncs_v1->post_suspend;
  hookfuncs->pre_resume   = hookfuncs_v1->pre_resume;
  hookfuncs->post_resume  = NULL;
  hookfuncs->free         = hookfuncs_v1->free;

  register_faa_hook(aTHX_ hookfuncs, hookdata);
}

MODULE = Future::AsyncAwait    PACKAGE = Future::AsyncAwait

int
__cxstack_ix()
  CODE:
    RETVAL = cxstack_ix;
  OUTPUT:
    RETVAL

BOOT:
  XopENTRY_set(&xop_enterasync, xop_name, "enterasync");
  XopENTRY_set(&xop_enterasync, xop_desc, "enterasync()");
  XopENTRY_set(&xop_enterasync, xop_class, OA_BASEOP);
  Perl_custom_op_register(aTHX_ &pp_enterasync, &xop_enterasync);

  XopENTRY_set(&xop_leaveasync, xop_name, "leaveasync");
  XopENTRY_set(&xop_leaveasync, xop_desc, "leaveasync()");
  XopENTRY_set(&xop_leaveasync, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_leaveasync, &xop_leaveasync);

  XopENTRY_set(&xop_await, xop_name, "await");
  XopENTRY_set(&xop_await, xop_desc, "await()");
  XopENTRY_set(&xop_await, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_await, &xop_await);

  XopENTRY_set(&xop_pushcancel, xop_name, "pushcancel");
  XopENTRY_set(&xop_pushcancel, xop_desc, "pushcancel()");
  XopENTRY_set(&xop_pushcancel, xop_class, OA_SVOP);
  Perl_custom_op_register(aTHX_ &pp_pushcancel, &xop_pushcancel);

  boot_xs_parse_keyword(0.13);
  boot_xs_parse_sublike(0.31);

  register_xs_parse_sublike("async", &hooks_async, NULL);

  register_xs_parse_keyword("await", &hooks_await, NULL);
  register_xs_parse_keyword("CANCEL", &hooks_cancel, NULL);
#ifdef HAVE_DMD_HELPER
  DMD_SET_MAGIC_HELPER(&vtbl_suspendedstate, dumpmagic_suspendedstate);
#endif

  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MIN", 1), 1);
  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/ABIVERSION_MAX", 1), FUTURE_ASYNCAWAIT_ABI_VERSION);

  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/register()@2", 1),
    PTR2UV(&register_faa_hook));
  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/register()@1", 1),
    PTR2UV(&register_faa_hook_v1));
  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/get_modhookdata()@1", 1),
    PTR2UV(&get_modhookdata));
  sv_setiv(*hv_fetchs(PL_modglobal, "Future::AsyncAwait/make_precreate_padix()@1", 1),
    PTR2UV(&S_get_or_create_precreate_padix));

  {
    AV *run_on_loaded = NULL;
    SV **svp;
    if(svp = hv_fetchs(PL_modglobal, "Future::AsyncAwait/on_loaded", FALSE)) {
      run_on_loaded = (AV *)SvREFCNT_inc(*svp);
      hv_deletes(PL_modglobal, "Future::AsyncAwait/on_loaded", 0);
    }

    hv_stores(PL_modglobal, "Future::AsyncAwait/loaded", &PL_sv_yes);

    if(run_on_loaded) {
      svp = AvARRAY(run_on_loaded);

      int i;
      for(i = 0; i < AvFILL(run_on_loaded); i += 2) {
        void (*func)(pTHX_ void *data) = INT2PTR(void *, SvUV(svp[i  ]));
        void *data                     = INT2PTR(void *, SvUV(svp[i+1]));

        (*func)(aTHX_ data);
      }

      SvREFCNT_dec(run_on_loaded);
    }
  }
