/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * Magic that we attach to suspended CVs, that contains state required to restore
 * them
 */

typedef struct SuspendedFrame SuspendedFrame;
struct SuspendedFrame {
  SuspendedFrame *next;
  U8 type;
  U8 gimme;

  U32 stacklen;
  SV **stack;

  U32 marklen;
  I32 *marks;

  union {
    struct {
      OP *retop;
    } eval;
    struct {
      LOOP *loopop;
    } loop;
  };
};

typedef struct {
  SV *awaiting_future;   /* the Future that 'await' is currently waiting for */
  SV *returning_future;  /* the Future that its contining CV will eventually return */
  SuspendedFrame *frames;

  U32 padlen;
  SV **padslots;
} SuspendedState;

static MGVTBL vtbl = {
  NULL, /* get   */
  NULL, /* set   */
  NULL, /* len   */
  NULL, /* clear */
  NULL, /* free  - TODO?? */
};

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

  sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &vtbl, (char *)ret, 0);

  return ret;
}

#define suspend_block(frame, cx)  MY_suspend_block(aTHX_ frame, cx)
static void MY_suspend_block(pTHX_ SuspendedFrame *frame, PERL_CONTEXT *cx)
{
  /* The base of the stack within this context */
  SV **bp = PL_stack_base + cx->blk_oldsp + 1;
  I32 *markbase = PL_markstack + cx->blk_oldmarksp + 1;

  frame->stacklen = (I32)(PL_stack_sp - PL_stack_base)  - cx->blk_oldsp;
  if(frame->stacklen) {
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
    I32 i;
    Newx(frame->marks, frame->marklen, I32);
    for(i = 0; i < frame->marklen; i++) {
      /* Translate mark value relative to bp */
      I32 relmark = markbase[i] - cx->blk_oldsp;
      frame->marks[i] = relmark;
    }
    PL_markstack_ptr = PL_markstack + cx->blk_oldmarksp;
  }

  I32 old_saveix = cx->blk_oldsaveix;
  while(PL_savestack_ix > old_saveix) {
    /* Useful references
     *   scope.h
     *   scope.c: Perl_leave_scope()
     */

    /* TODO: cope with more things
     * Right now all we can handle is a single SAVEt_ALLOC that implies zero size
     */
    UV uv = PL_savestack[PL_savestack_ix].any_uv;
    U8 type = (U8)uv & SAVE_MASK;

    switch(type) {
      case SAVEt_ALLOC: {
        U8 size = (type >> SAVE_TIGHT_SHIFT);
        if(size > 0)
          croak("TODO: Handle SAVEt_ALLOC of non-zero size %d", size);

        /* At this point we know it's safe to just ignore it */
        PL_savestack_ix--;
        break;
      }

      default:
        croak("TODO: Top of PL_savestack is not SAVEt_ALLOC but %d", type);
    }
  }

  if(cx->blk_oldsaveix != PL_savestack_ix)
    croak("TODO: handle cx->blk_oldsaveix");
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

    suspend_block(frame, cx);

    /* ref:
     *   https://perl5.git.perl.org/perl.git/blob/HEAD:/cop.h
     */
    switch(CxTYPE(cx)) {
      case CXt_LOOP_PLAIN: {
        frame->type = CXt_LOOP_PLAIN;
        frame->loop.loopop = cx->blk_loop.my_op;

        continue;
      }

      case CXt_EVAL: {
        if(!(cx->cx_type & CXp_TRYBLOCK))
          croak("TODO: handle CXt_EVAL without CXp_TRYBLOCK");
        if(cx->blk_eval.old_namesv)
          croak("TODO: handle cx->blk_eval.old_namesv");
        if(cx->blk_eval.old_eval_root)
          croak("TODO: handle cx->blk_eval.old_eval_root");
        if(cx->blk_eval.cur_text)
          croak("TODO: handle cx->blk_eval.cur_text");
        if(cx->blk_eval.cv)
          croak("TODO: handle cx->blk_eval.cv");
        if(cx->blk_eval.cur_top_env != PL_top_env)
          croak("TODO: handle cx->blk_eval.cur_top_env");

        frame->type = CXt_EVAL;
        frame->gimme = cx->blk_gimme;

        frame->eval.retop = cx->blk_eval.retop;

        continue;
      }

      default:
        croak("TODO: unsure how to handle a context frame of type %d\n", CxTYPE(cx));
    }
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

    /* Only the lexicals that have names; if there's no name then skip it. */
    if(!pname || !PadnameLEN(pname)) {
      state->padslots[i-1] = NULL;
      continue;
    }

    /* Don't fiddle refcount */
    state->padslots[i-1] = PadARRAY(pad)[i];
    PadARRAY(pad)[i] = newSV(0);
  }

  dounwind(cxix);
}

#define resume_block(frame, cx)  MY_resume_block(aTHX_ frame, cx)
static void MY_resume_block(pTHX_ SuspendedFrame *frame, PERL_CONTEXT *cx)
{
  if(frame->stacklen) {
    dSP;
    I32 i;
    EXTEND(SP, frame->stacklen);

    for(i = 0; i < frame->stacklen; i++) {
      PUSHs(frame->stack[i]);
    }

    Safefree(frame->stack);
    PUTBACK;
  }

  if(frame->marklen) {
    I32 i;

    for(i = 0; i < frame->marklen; i++) {
      PUSHMARK(PL_stack_base + frame->marks[i] - cx->blk_oldsp);
    }

    Safefree(frame->marks);
  }
}

#define suspendedstate_resume(state, cv)  MY_suspendedstate_resume(aTHX_ state, cv)
static void MY_suspendedstate_resume(pTHX_ SuspendedState *state, CV *cv)
{
  SuspendedFrame *frame, *next;
  for(frame = state->frames; frame; frame = next) {
    next = frame->next;

    PERL_CONTEXT *cx;

    switch(frame->type) {
      case CXt_LOOP_PLAIN:
        cx = cx_pushblock(CXt_LOOP_PLAIN, G_VOID, PL_stack_sp, PL_savestack_ix);
        /* don't call cx_pushloop_plain() because it will get this wrong */
        cx->blk_loop.my_op = frame->loop.loopop;
        break;

      case CXt_EVAL:
        cx = cx_pushblock(CXt_EVAL|CXp_TRYBLOCK, frame->gimme,
          PL_stack_sp, PL_savestack_ix);
        cx_pusheval(cx, frame->eval.retop, NULL);
        PL_in_eval = EVAL_INEVAL;
        CLEAR_ERRSV();
        break;

      default:
        croak("TODO: Unsure how to restore a %d frame\n", frame->type);
    }

    resume_block(frame, cx);

    Safefree(frame);
  }

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
  }
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

  ENTER;
  SAVETMPS;

  PUSHMARK(mark);
  SV **bottom = mark + 1;

  /* splice the class name 'Future' in to the start of the stack */

  for (svp = SP; svp >= bottom; svp--) {
    *(svp+1) = *svp;
  }
  if(f)
    *bottom = SvREFCNT_inc(f);
  else
    *bottom = sv_2mortal(newSVpvn("Future", 6));
  SP++;
  PUTBACK;

  call_method("done", G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE;

  return ret;
}

#define future_fail(f, failure)  MY_future_fail(aTHX_ f, failure)
static SV *MY_future_fail(pTHX_ SV *f, SV *failure)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  if(f)
    PUSHs(SvREFCNT_inc(f));
  else
    mPUSHp("Future", 6);
  mPUSHs(newSVsv(failure));
  PUTBACK;

  call_method("fail", G_SCALAR);

  SPAGAIN;

  SV *ret = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE;

  return ret;
}

#define future_new_from_proto(proto)  MY_future_new_from_proto(aTHX_ proto)
static SV *MY_future_new_from_proto(pTHX_ SV *proto)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  PUSHs(proto);
  PUTBACK;

  call_method("new", G_SCALAR);

  SPAGAIN;

  SV *f = SvREFCNT_inc(POPs);

  FREETMPS;
  LEAVE;

  return f;
}

#define future_is_ready(f)  MY_future_is_ready(aTHX_ f)
static int MY_future_is_ready(pTHX_ SV *f)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(f);
  PUTBACK;

  call_method("is_ready", G_SCALAR);

  SPAGAIN;

  int is_ready = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return is_ready;
}

#define future_get_to_stack(f, gimme)  MY_future_get_to_stack(aTHX_ f, gimme)
static void MY_future_get_to_stack(pTHX_ SV *f, I32 gimme)
{
  dSP;

  ENTER;

  PUSHMARK(SP);
  XPUSHs(f);
  PUTBACK;

  call_method("get", gimme);

  LEAVE;
}

#define future_on_ready(f, code)  MY_future_on_ready(aTHX_ f, code)
static void MY_future_on_ready(pTHX_ SV *f, CV *code)
{
  dSP;

  ENTER;

  PUSHMARK(SP);
  XPUSHs(f);
  mXPUSHs(newRV_inc((SV *)code));
  PUTBACK;

  call_method("on_ready", G_VOID);

  LEAVE;
}

/*
 * Custom ops
 */

static XOP xop_leaveasync;
static OP *pp_leaveasync(pTHX)
{
  dSP;
  dMARK;

  SV *f = NULL;

  SuspendedState *state = suspendedstate_get(find_runcv(0));
  if(state && state->returning_future)
    f = state->returning_future;

  if(SvTRUE(ERRSV)) {
    PUSHs(future_fail(f, ERRSV));
  }
  else {
    PUSHs(future_done_from_stack(f, mark));
  }

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

  SuspendedState *state = suspendedstate_get(curcv);

  if(state && state->awaiting_future) {
    I32 orig_height;

    f = state->awaiting_future;
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
  }
  else {
    f = POPs;
    PUTBACK;
  }

  if(!sv_isobject(f))
    croak("Expected a blessed object reference to await");

  if(future_is_ready(f)) {
    assert(CvDEPTH(curcv) > 0);
    /* This might throw */
    future_get_to_stack(f, GIMME_V);
    return PL_op->op_next;
  }

  if(!state) {
    /* Clone the CV and then attach suspendedstate magic to it */
    curcv = cv_clone(curcv);
    state = suspendedstate_new(curcv);
  }

  suspendedstate_suspend(state, origcv);

  CvSTART(curcv) = PL_op; /* resume from here */
  future_on_ready(f, curcv);

  state->awaiting_future = SvREFCNT_inc(f);

  if(!state->returning_future)
    state->returning_future = future_new_from_proto(f);

  PUSHMARK(SP);
  PUSHs(state->returning_future);
  PUTBACK;

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

  if(lex_peek_unichar(0) != '{')
    croak("Expected async sub %sto be followed by '{'", name ? "NAME " : "");

  I32 floor_ix = start_subparse(FALSE, name ? 0 : CVf_ANON);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  OP *body = parse_block(0);

  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  /* turn block into
   *    PUSHMARK; eval { BLOCK }; LEAVEASYNC
   */

  OP *op = newLISTOP(OP_LINESEQ, 0, newOP(OP_PUSHMARK, 0), NULL);

  OP *try;
  op = op_append_elem(OP_LINESEQ, op, try = newUNOP(OP_ENTERTRY, 0, body));
  op_contextualize(try, G_ARRAY);

  op = op_append_elem(OP_LINESEQ, op, newLEAVEASYNCOP(OPf_WANT_SCALAR));

  CV *cv = newATTRSUB(floor_ix,
    name ? newSVOP(OP_CONST, 0, SvREFCNT_inc(name)) : NULL,
    NULL,
    NULL,
    op);

  if(name) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(name);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    /* Placate Perl RT#131519
     * cv_clone() doesn't set CvOUTSIDE if !CvHASEVAL, and in doing so causes a
     * subsequent cv_clone() on *that* CV to SEGV
     */
    CvHASEVAL_on(cv);

    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)cv));

    return KEYWORD_PLUGIN_EXPR;
  }
}

static int await_keyword_plugin(pTHX_ OP **op_ptr)
{
  /* TODO: Forbid this except inside 'async sub' */

  lex_read_space(0);

  /* await EXPR wants a single term expression */
  OP *expr = parse_termexpr(0);

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
