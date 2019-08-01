/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016-2019 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef HAVE_DMD_HELPER
#  include "DMD_helper.h"
#endif

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 31, 3)
#  define HAVE_PARSE_SUBSIGNATURE
#elif HAVE_PERL_VERSION(5, 26, 0)
#  include "parse_subsignature.c.inc"
#  define HAVE_PARSE_SUBSIGNATURE
#endif

#if !HAVE_PERL_VERSION(5, 24, 0)
  /* On perls before 5.24 we have to do some extra work to save the itervar
   * from being thrown away */
#  define HAVE_ITERVAR
#endif

#if HAVE_PERL_VERSION(5, 24, 0)
#  define OLDSAVEIX(cx)  (cx->blk_oldsaveix)
#else
#  define OLDSAVEIX(cx)  (PL_scopestack[cx->blk_oldscopesp-1])
#endif

#ifndef CX_CUR
#  define CX_CUR() (&cxstack[cxstack_ix])
#endif

#ifndef OpSIBLING
#  define OpSIBLING(op)  (op->op_sibling)
#endif

#ifdef SAVEt_CLEARPADRANGE
#  include "save_clearpadrange.c.inc"
#endif

#if !HAVE_PERL_VERSION(5, 24, 0)
#  include "cx_pushblock.c.inc"
#  include "cx_pusheval.c.inc"
#endif

#if !HAVE_PERL_VERSION(5, 22, 0)
#  include "block_start.c.inc"
#  include "block_end.c.inc"

#  define CvPADLIST_set(cv, padlist)  (CvPADLIST(cv) = padlist)
#endif

#if !HAVE_PERL_VERSION(5, 18, 0)
#  define PadARRAY(pad)           AvARRAY(pad)
#  define PadMAX(pad)             AvFILLp(pad)

typedef AV PADNAMELIST;
#  define PadlistARRAY(pl)        ((PAD **)AvARRAY(pl))
#  define PadlistNAMES(pl)        (*PadlistARRAY(pl))

typedef SV PADNAME;
#  define PadnamePV(pn)           (SvPOKp(pn) ? SvPVX(pn) : NULL)
#  define PadnameLEN(pn)          SvCUR(pn)
#  define PadnameOUTER(pn)        !!SvFAKE(pn)
#  define PadnamelistARRAY(pnl)   AvARRAY(pnl)
#  define PadnamelistMAX(pnl)     AvFILLp(pnl)
#endif

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
      PADOFFSET padix; /* for SAVEt_PADSV_AND_MORTALIZE */
      struct {
        SV *sv;
        U32 mask, set;
      } svflags;       /* for SAVEt_SET_SVFLAGS */
    } u;

    union {
      SV    *sv;      /* for SAVEt_SV, SAVEt_FREESV */
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

static void debug_sv_summary(const SV *sv)
{
  const char *type;

  switch(SvTYPE(sv)) {
    case SVt_NULL: type = "NULL"; break;
    case SVt_IV:   type = "IV";   break;
    case SVt_NV:   type = "NV";   break;
    case SVt_PV:   type = "PV";   break;
    case SVt_PVGV: type = "PVGV"; break;
    case SVt_PVAV: type = "PVAV"; break;
    default: {
      char buf[16];
      sprintf(buf, "(%d)", SvTYPE(sv));
      type = buf;
      break;
    }
  }

  if(SvROK(sv))
    type = "RV";

  fprintf(stderr, "SV{type=%s,refcnt=%d", type, SvREFCNT(sv));

  if(SvTEMP(sv))
    fprintf(stderr, ",TEMP");

  if(SvROK(sv))
    fprintf(stderr, ",ROK");
  else {
    if(SvIOK(sv))
      fprintf(stderr, ",IV=%" IVdf, SvIVX(sv));
    if(SvUOK(sv))
      fprintf(stderr, ",UV=%" UVuf, SvUVX(sv));
    if(SvPOK(sv)) {
      fprintf(stderr, ",PVX=\"%.10s\"", SvPVX((SV *)sv));
      if(SvCUR(sv) > 10)
        fprintf(stderr, "...");
    }
  }

  fprintf(stderr, "}");
}

static void debug_showstack(const char *name)
{
  SV **sp;

  fprintf(stderr, "%s:\n", name ? name : "Stack");

  PERL_CONTEXT *cx = CX_CUR();

  I32 floor = cx->blk_oldsp;
  I32 *mark = PL_markstack + cx->blk_oldmarksp + 1;

  fprintf(stderr, "  marks (TOPMARK=@%d):\n", TOPMARK - floor);
  for(; mark <= PL_markstack_ptr; mark++)
    fprintf(stderr,  "    @%d\n", *mark - floor);

  mark = PL_markstack + cx->blk_oldmarksp + 1;
  for(sp = PL_stack_base + floor + 1; sp <= PL_stack_sp; sp++) {
    fprintf(stderr, sp == PL_stack_sp ? "-> " : "   ");
    fprintf(stderr, "%p = ", *sp);
    debug_sv_summary(*sp);
    while(mark <= PL_markstack_ptr && PL_stack_base + *mark == sp)
      fprintf(stderr, " [*M]"), mark++;
    fprintf(stderr, "\n");
  }
}

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
 * Magic that we attach to suspended CVs, that contains state required to restore
 * them
 */

static int magic_free(pTHX_ SV *sv, MAGIC *mg);

static MGVTBL vtbl = {
  NULL, /* get   */
  NULL, /* set   */
  NULL, /* len   */
  NULL, /* clear */
  magic_free,
};

#ifdef HAVE_DMD_HELPER
static int dumpmagic(pTHX_ const SV *sv, MAGIC *mg)
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

  return ret;
}
#endif

#define suspendedstate_get(cv)  MY_suspendedstate_get(aTHX_ cv)
static SuspendedState *MY_suspendedstate_get(pTHX_ CV *cv)
{
  MAGIC *magic;

  for(magic = mg_find((SV *)cv, PERL_MAGIC_ext); magic; magic = magic->mg_moremagic)
    if(magic->mg_type == PERL_MAGIC_ext && magic->mg_virtual == &vtbl)
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

  sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &vtbl, (char *)ret, 0);

  return ret;
}

static int magic_free(pTHX_ SV *sv, MAGIC *mg)
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
#ifdef SAVEt_STRLEN
            case SAVEt_STRLEN:
#endif
            case SAVEt_SET_SVFLAGS:
              break;

            case SAVEt_FREEPV:
              Safefree(saved->cur.ptr);
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

            default:
              fprintf(stderr, "TODO: free saved slot type %d\n", saved->type);
              break;
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
        if(gv != PL_errgv)
          panic("TODO: Unsure how to handle a savestack entry of SAVEt_SV with gv != PL_errgv\n");

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
        panic("TODO: Unsure how to handle savestack entry of %d\n", type);
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

static bool padname_is_normal_lexical(PADNAME *pname)
{
  /* PAD slots without names are certainly not lexicals */
  if(!pname ||
#if !HAVE_PERL_VERSION(5, 20, 0)
    /*  Perl before 5.20.0 could put PL_sv_undef in PADNAMEs */
    pname == &PL_sv_undef || 
#endif
    !PadnameLEN(pname))
    return FALSE;

  /* Outer lexical captures are not lexicals */
  if(PadnameOUTER(pname))
    return FALSE;

  /* Protosubs for closures are not lexicals */
  if(PadnamePV(pname)[0] == '&')
    return FALSE;

  /* anything left is a normal lexical */
  return TRUE;
}

#define cv_dup_for_suspend(orig)  MY_cv_dup_for_suspend(aTHX_ orig)
static CV *MY_cv_dup_for_suspend(pTHX_ CV *orig)
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
  CvSTART(new) = NULL; /* intentionally left NULL because caller should fill this in */
  CvOUTSIDE_SEQ(new) = CvOUTSIDE_SEQ(orig);

  /* No need to bother with SvPV slot because that's the prototype, and it's
   * too late for that here
   */

  {
    ENTER_with_name("cv_dup_for_suspend");

    SAVESPTR(PL_compcv);
    PL_compcv = new;

    CvOUTSIDE(new) = MUTABLE_CV(SvREFCNT_inc(CvOUTSIDE(orig)));

    SAVESPTR(PL_comppad_name);
    PL_comppad_name = PadlistNAMES(CvPADLIST(orig));
    CvPADLIST_set(new, pad_new(padnew_CLONE|padnew_SAVE));
#if HAVE_PERL_VERSION(5, 22, 0)
    CvPADLIST(new)->xpadl_id = CvPADLIST(orig)->xpadl_id;
#endif

    PADNAMELIST *padnames = PadlistNAMES(CvPADLIST(orig));
    const PADOFFSET fnames = PadnamelistMAX(padnames);
    const PADOFFSET fpad = AvFILLp(PadlistARRAY(CvPADLIST(orig))[1]);
    SV **origpad = AvARRAY(PadlistARRAY(CvPADLIST(orig))[CvDEPTH(orig)]);

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
    for(padix = 1; padix <= fpad; padix++) {
      PADNAME *pname = (padix <= fnames) ? pnames[padix] : NULL;
      SV *newval;

      if(padname_is_normal_lexical(pname)) {
        /* No point copying a normal lexical slot because the suspend logic is
         * about to capture all the pad slots from the running CV (orig) and
         * they'll be restored into this new one later by resume.
         */
        continue;
      }
      else if(pname && PadnamePV(pname)) {
#if !HAVE_PERL_VERSION(5, 18, 0)
        /* Before perl 5.18.0, inner anon subs didn't find the right CvOUTSIDE
         * at runtime, so we'll have to patch them up here
         */
        CV *origproto;
        if(PadnamePV(pname)[0] == '&' && 
           CvOUTSIDE(origproto = MUTABLE_CV(origpad[padix])) == orig) {
          /* quiet any "Variable $FOO is not available" warnings about lexicals
           * yet to be introduced
           */
          ENTER_with_name("find_cv_outside");
          SAVEINT(CvDEPTH(origproto));
          CvDEPTH(origproto) = 1;

          CV *newproto = cv_dup_for_suspend(origproto);
          CvPADLIST_set(newproto, CvPADLIST(origproto));
          CvSTART(newproto) = CvSTART(origproto);

          SvREFCNT_dec(CvOUTSIDE(newproto));
          CvOUTSIDE(newproto) = MUTABLE_CV(SvREFCNT_inc_simple_NN(new));

          LEAVE_with_name("find_cv_outside");

          newval = MUTABLE_SV(newproto);
        }
        else if(origpad[padix])
          newval = SvREFCNT_inc_NN(origpad[padix]);
#else
        newval = SvREFCNT_inc_NN(origpad[padix]);
#endif
      }
      else {
        newval = newSV(0);
        SvPADTMP_on(newval);
      }

      PL_curpad[padix] = newval;
    }

    LEAVE_with_name("cv_dup_for_suspend");
  }

  return new;
}

#define suspendedstate_suspend(state, cv)  MY_suspendedstate_suspend(aTHX_ state, cv)
static void MY_suspendedstate_suspend(pTHX_ SuspendedState *state, CV *cv)
{
  I32 cxix;
  PADOFFSET padnames_max, pad_max, i;
  PADLIST *plist;
  PADNAME **padnames;
  PAD *pad;

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

  state->padlen = PadMAX(pad) + 1;
  Newx(state->padslots, state->padlen - 1, SV *);

  /* slot 0 is always the @_ AV */
  for(i = 1; i <= pad_max; i++) {
    PADNAME *pname = (i <= padnames_max) ? padnames[i] : NULL;

    if(!padname_is_normal_lexical(pname)) {
      state->padslots[i-1] = NULL;
      continue;
    }

    /* Don't fiddle refcount */
    state->padslots[i-1] = PadARRAY(pad)[i];
    switch(PadnamePV(pname)[0]) {
      case '@':
        PadARRAY(pad)[i] = MUTABLE_SV(newAV());
        break;
      case '%':
        PadARRAY(pad)[i] = MUTABLE_SV(newHV());
        break;
      case '$':
        PadARRAY(pad)[i] = newSV(0);
        break;
      default:
        panic("TODO: unsure how to steal and switch pad slot with pname %s\n",
          PadnamePV(pname));
      }
  }

  if(PL_curpm)
    state->curpm  = PL_curpm;
  else
    state->curpm = NULL;

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
      fprintf(stderr, "F:AA: consistency check resume LOOP_LIST with first=%p:",
        frame->loop_list_first_item);
      debug_sv_summary(frame->loop_list_first_item);
      fprintf(stderr, " stackitem=%p:", PL_stack_base[frame->el.loop.state_u.stack.basesp + 1]);
      debug_sv_summary(PL_stack_base[frame->el.loop.state_u.stack.basesp]);
      fprintf(stderr, "\n");
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
}

/*
 * Some Future class helper functions
 */

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

  /* splice the class name 'Future' in to the start of the stack */

  for (svp = SP; svp >= bottom; svp--) {
    *(svp+1) = *svp;
  }
  if(f)
    *bottom = f;
  else
    *bottom = sv_2mortal(newSVpvn("Future", 6));
  SP++;
  PUTBACK;

  call_method("done", G_SCALAR);

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

  PUSHMARK(SP);
  if(f)
    PUSHs(f);
  else
    mPUSHp("Future", 6);
  mPUSHs(newSVsv(failure));
  PUTBACK;

  call_method("fail", G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE_with_name("future_fail");

  return ret;
}

#define future_new_from_proto(proto)  MY_future_new_from_proto(aTHX_ proto)
static SV *MY_future_new_from_proto(pTHX_ SV *proto)
{
  dSP;

  ENTER_with_name("future_new_from_proto");
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(proto);
  PUTBACK;

  call_method("new", G_SCALAR);

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

#define future_is_ready(f)      MY_future_check(aTHX_ f, "is_ready")
#define future_is_cancelled(f)  MY_future_check(aTHX_ f, "is_cancelled")
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
  XPUSHs(f);
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
  XPUSHs(f);
  PUTBACK;

  call_method("get", gimme);

  LEAVE_with_name("future_get_to_stack");
}

#define future_on_ready(f, code)  MY_future_on_ready(aTHX_ f, code)
static void MY_future_on_ready(pTHX_ SV *f, CV *code)
{
  dSP;

  ENTER_with_name("future_on_ready");
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(f);
  mXPUSHs(newRV_inc((SV *)code));
  PUTBACK;

  call_method("on_ready", G_VOID);

  FREETMPS;
  LEAVE_with_name("future_on_ready");
}

#define future_chain_on_cancel(f1, f2)  MY_future_chain_on_cancel(aTHX_ f1, f2)
static void MY_future_chain_on_cancel(pTHX_ SV *f1, SV *f2)
{
  dSP;

  ENTER_with_name("future_chain_on_cancel");
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(f1);
  XPUSHs(f2);
  PUTBACK;

  call_method("on_cancel", G_VOID);

  FREETMPS;
  LEAVE_with_name("future_chain_on_cancel");
}

/*
 * Custom ops
 */

static XOP xop_leaveasync;
static OP *pp_leaveasync(pTHX)
{
  dSP;
  dMARK;

  PERL_CONTEXT *cx = CX_CUR();
  SV *f = NULL;
  SV *ret;
  SV **oldsp = PL_stack_base + cx->blk_oldsp;

  SuspendedState *state = suspendedstate_get(find_runcv(0));
  if(state && state->returning_future) {
    f = state->returning_future;
    state->returning_future = NULL;
  }

  if(SvTRUE(ERRSV)) {
    ret = future_fail(f, ERRSV);
  }
  else {
    ret = future_done_from_stack(f, mark);
  }

  /* Pop extraneous stack items */
  while(SP > oldsp)
    POPs;

  mPUSHs(ret);
  PUTBACK;

  if(f)
    SvREFCNT_dec(f);

  return PL_op->op_next;
}

static OP *newLEAVEASYNCOP(I32 flags)
{
  OP *op = newOP(OP_CUSTOM, flags);
  op->op_ppaddr = &pp_leaveasync;

  return op;
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

  SuspendedState *state = suspendedstate_get(curcv);

  if(state && state->awaiting_future && CATCH_GET) {
    /* If we don't do this we get all the mess that is
     *   https://rt.cpan.org/Ticket/Display.html?id=126037
     */
    return docatch(pp_await);
  }

  if(state && state->curcop)
    PL_curcop = state->curcop;

  TRACEPRINT("ENTER await curcv=%p [%s:%d]\n", curcv, CopFILE(PL_curcop), CopLINE(PL_curcop));

  if(state && state->awaiting_future) {
    if(!SvROK(state->returning_future) || future_is_cancelled(state->returning_future)) {
      if(!SvROK(state->returning_future)) {
        GV *gv = CvGV(curcv);
        if(!CvANON(curcv))
          warn("Suspended async sub %s::%s lost its returning future", HvNAME(GvSTASH(gv)), GvNAME(gv));
        else
          warn("Suspended async sub CODE(0x%p) in package %s lost its returning future", curcv, HvNAME(GvSTASH(gv)));
      }

      TRACEPRINT("  CANCELLED\n");

      PUSHMARK(SP);
      PUTBACK;
      return PL_ppaddr[OP_RETURN](aTHX);
    }

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

    suspendedstate_resume(state, curcv);

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
    curcv = cv_dup_for_suspend(curcv);
    state = suspendedstate_new(curcv);

    TRACEPRINT("  SUSPEND cloned CV->%p\n", curcv);
    defer_mortal_curcv = TRUE;
  }
  else {
    TRACEPRINT("  SUSPEND reuse CV\n");
  }

  state->curcop = PL_curcop;

  suspendedstate_suspend(state, origcv);

  CvSTART(curcv) = PL_op; /* resume from here */
  future_on_ready(f, curcv);

  state->awaiting_future = newSVsv(f);
  sv_rvweaken(state->awaiting_future);

  if(!state->returning_future)
    state->returning_future = future_new_from_proto(f);

  if(defer_mortal_curcv)
    SvREFCNT_dec((SV *)curcv);

  PUSHMARK(SP);
  mPUSHs(newSVsv(state->returning_future));
  PUTBACK;

  if(!SvWEAKREF(state->returning_future))
    sv_rvweaken(state->returning_future);
  if(!SvROK(state->returning_future))
    panic("ARGH we lost state->returning_future for curcv=%p\n", curcv);

/* For unknown reasons, doing this on perls 5.20 or 5.22 massively breaks
 * everything.
 *   https://rt.cpan.org/Ticket/Display.html?id=129202#txn-1843918
 */
#if HAVE_PERL_VERSION(5, 24, 0)
  future_chain_on_cancel(state->returning_future, state->awaiting_future);
#endif

  if(!SvROK(state->returning_future))
    panic("ARGH we lost state->returning_future for curcv=%p\n", curcv);
  if(!SvROK(state->awaiting_future))
    panic("ARGH we lost state->awaiting_future for curcv=%p\n", curcv);

  TRACEPRINT("LEAVE await curcv=%p [%s:%d]\n", curcv, CopFILE(PL_curcop), CopLINE(PL_curcop));

  return PL_ppaddr[OP_RETURN](aTHX);
}

static OP *newAWAITOP(I32 flags, OP *expr)
{
  OP *op = newUNOP(OP_CUSTOM, flags, expr);
  op->op_ppaddr = &pp_await;

  return op;
}

/*
 * Lexer extensions
 */

#define lex_consume(s)  MY_lex_consume(aTHX_ s)
static int MY_lex_consume(pTHX_ char *s)
{
  /* I want strprefix() */
  size_t i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  lex_read_to(PL_parser->bufptr + i);
  return i;
}

#define sv_cat_c(sv, c)  MY_sv_cat_c(aTHX_ sv, c)
static void MY_sv_cat_c(pTHX_ SV *sv, U32 c)
{
  char ds[UTF8_MAXBYTES + 1], *d;
  d = (char *)uvchr_to_utf8((U8 *)ds, c);
  if (d - ds > 1) {
    sv_utf8_upgrade(sv);
  }
  sv_catpvn(sv, ds, d - ds);
}

#define lex_scan_ident()  MY_lex_scan_ident(aTHX)
static SV *MY_lex_scan_ident(pTHX)
{
  /* Inspired by
   *   https://metacpan.org/source/MAUKE/Function-Parameters-1.0705/Parameters.xs#L265
   */
  I32 c;
  bool at_start;
  SV *ret = newSVpvs("");
  if(lex_bufutf8())
    SvUTF8_on(ret);

  at_start = TRUE;

  c = lex_peek_unichar(0);

  while(c != -1) {
    if(at_start ? isIDFIRST_uni(c) : isALNUM_uni(c)) {
      at_start = FALSE;
      sv_cat_c(ret, lex_read_unichar(0));

      c = lex_peek_unichar(0);
    }
    else
      break;
  }

  if(SvCUR(ret))
    return ret;

  SvREFCNT_dec(ret);
  return NULL;
}

#define lex_scan_attr()  MY_lex_scan_attr(aTHX)
static SV *MY_lex_scan_attr(pTHX)
{
  SV *ret = lex_scan_ident();
  if(!ret)
    return ret;

  lex_read_space(0);

  if(lex_peek_unichar(0) != '(')
    return ret;
  sv_cat_c(ret, lex_read_unichar(0));

  int count = 1;
  I32 c = lex_peek_unichar(0);
  while(count && c != -1) {
    if(c == '(')
      count++;
    if(c == ')')
      count--;
    if(c == '\\') {
      /* The next char does not bump count even if it is ( or );
       * the \\ is still captured
       */
      sv_cat_c(ret, lex_read_unichar(0));
      c = lex_peek_unichar(0);
      if(c == -1)
        goto unterminated;
    }

    sv_cat_c(ret, lex_read_unichar(0));
    c = lex_peek_unichar(0);
  }

  if(c != -1)
    return ret;

unterminated:
  croak("Unterminated attribute parameter in attribute list");
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

static int async_keyword_plugin(pTHX_ OP **op_ptr)
{
  lex_read_space(0);

  /* At this point we want to parse the sub NAME BLOCK or sub BLOCK
   * We can't just call parse_fullstmt because that will do too much that we
   *   can't hook into. We'll have to go a longer way round.
   */

  /* async must be immediately followed by 'sub' */
  if(!lex_consume("sub"))
    croak("Expected async to be followed by sub");
  lex_read_space(0);

  /* Might be named or anonymous */
  SV *name = lex_scan_ident();
  lex_read_space(0);

  I32 floor_ix = start_subparse(FALSE, name ? 0 : CVf_ANON);
  SAVEFREESV(PL_compcv);

  /* Parse subroutine attrs
   * These are supplied to newATTRSUB() as an OP_LIST containing OP_CONSTs,
   *   one attribute in each as a plain SV. Note that we don't have to parse
   *   inside the contents of the parens; that is handled by the attribute
   *   handlers themselves
   */
  OP *attrs = NULL;
  if(lex_peek_unichar(0) == ':') {
    SV *attr;
    lex_read_unichar(0);
    lex_read_space(0);

    while((attr = lex_scan_attr())) {
      lex_read_space(0);

      if(!attrs)
        attrs = newLISTOP(OP_LIST, 0, NULL, NULL);

      attrs = op_append_elem(OP_LIST, attrs, newSVOP(OP_CONST, 0, attr));
    }
  }

#ifdef HAVE_PARSE_SUBSIGNATURE
  OP *sigop = NULL;
  if(lex_peek_unichar(0) == '(') {
    lex_read_unichar(0);

    sigop = parse_subsignature(0);
    lex_read_space(0);

    if(PL_parser->error_count)
      return 0;

    if(lex_peek_unichar(0) != ')')
      croak("Expected ')'");
    lex_read_unichar(0);
    lex_read_space(0);
  }
#endif

  if(lex_peek_unichar(0) != '{')
    croak("Expected async sub %sto be followed by '{'", name ? "NAME " : "");

  /* Save the identity of the currently-compiling sub so that 
   * await_keyword_plugin() can check
   */
  PL_hints |= HINT_LOCALIZE_HH;
  SAVEHINTS();

  hv_stores(GvHV(PL_hintgv), "Future::AsyncAwait/PL_compcv", newSVuv(PTR2UV(PL_compcv)));

  I32 save_ix = block_start(TRUE);

  OP *body = parse_block(0);

  COP *last_cop = PL_curcop;
  check_optree(aTHX_ body, NO_FORBID, &last_cop);

  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

#ifdef HAVE_PARSE_SUBSIGNATURE
  if(sigop)
    body = op_append_list(OP_LINESEQ, sigop, body);
#endif

  /* turn block into
   *    NEXTSTATE; PUSHMARK; eval { BLOCK }; LEAVEASYNC
   */

  OP *op = newSTATEOP(0, NULL, NULL);
  op = op_append_elem(OP_LINESEQ, op, newOP(OP_PUSHMARK, 0));

  OP *try;
  op = op_append_elem(OP_LINESEQ, op, try = newUNOP(OP_ENTERTRY, 0, body));
  op_contextualize(try, G_ARRAY);

  op = op_append_elem(OP_LINESEQ, op, newLEAVEASYNCOP(OPf_WANT_SCALAR));

  CV *cv = newATTRSUB(floor_ix,
    name ? newSVOP(OP_CONST, 0, SvREFCNT_inc(name)) : NULL,
    NULL,
    attrs,
    op);

  if(CvLVALUE(cv))
    warn("Pointless use of :lvalue on async sub");

  if(name) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(name);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)cv));

    return KEYWORD_PLUGIN_EXPR;
  }
}

static int await_keyword_plugin(pTHX_ OP **op_ptr)
{
  SV **asynccvp = hv_fetchs(GvHV(PL_hintgv), "Future::AsyncAwait/PL_compcv", 0);
  if(!asynccvp || SvUV(*asynccvp) != PTR2UV(PL_compcv))
    croak(CvEVAL(PL_compcv) ?
      "await is not allowed inside string eval" :
      "Cannot 'await' outside of an 'async sub'");

  lex_read_space(0);

  OP *expr;
  /* await TERMEXPR wants a single term expression
   * await( FULLEXPR ) will be a full expression */
  if(lex_peek_unichar(0) == '(') {
    lex_read_unichar(0);

    expr = parse_fullexpr(0);

    lex_read_space(0);

    if(lex_peek_unichar(0) != ')')
      croak("Expected ')'");
    lex_read_unichar(0);
  }
  else
    expr = parse_termexpr(0);

  *op_ptr = newAWAITOP(0, expr);

  return KEYWORD_PLUGIN_EXPR;
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  HV *hints = GvHV(PL_hintgv);

  if((PL_parser && PL_parser->error_count) ||
     !hints)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);

  if(kwlen == 5 && strEQ(kw, "async") &&
      hv_fetchs(hints, "Future::AsyncAwait/async", 0))
    return async_keyword_plugin(aTHX_ op_ptr);

  if(kwlen == 5 && strEQ(kw, "await") &&
      hv_fetchs(hints, "Future::AsyncAwait/async", 0))
    return await_keyword_plugin(aTHX_ op_ptr);

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);
}

MODULE = Future::AsyncAwait    PACKAGE = Future::AsyncAwait

int
__cxstack_ix()
  CODE:
    RETVAL = cxstack_ix;
  OUTPUT:
    RETVAL

BOOT:
  XopENTRY_set(&xop_leaveasync, xop_name, "leaveasync");
  XopENTRY_set(&xop_leaveasync, xop_desc, "leaveasync()");
  XopENTRY_set(&xop_leaveasync, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_leaveasync, &xop_leaveasync);

  XopENTRY_set(&xop_await, xop_name, "await");
  XopENTRY_set(&xop_await, xop_desc, "await()");
  XopENTRY_set(&xop_await, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_await, &xop_await);

  next_keyword_plugin = PL_keyword_plugin;
  PL_keyword_plugin = &my_keyword_plugin;
#ifdef HAVE_DMD_HELPER
  DMD_SET_MAGIC_HELPER(&vtbl, dumpmagic);
#endif
