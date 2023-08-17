/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT
/* needed on latest perl to get optimize_optree/finalize_optree */
#define PERL_USE_VOLATILE_API

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"
#include "op_sibling_splice.c.inc"

#ifndef optimize_optree
#  if HAVE_PERL_VERSION(5,28,0)
#    define optimize_optree(op)  Perl_optimize_optree(aTHX_ op)
#  else
#    define optimize_optree(op)
#  endif
#endif

#ifndef finalize_optree
#  if HAVE_PERL_VERSION(5,16,0)
#    define finalize_optree(op)  Perl_finalize_optree(aTHX_ op)
#  else
#    define finalize_optree(op)
#  endif
#endif

#if HAVE_PERL_VERSION(5,28,0)
#  define XPUSHzero  XPUSHs(&PL_sv_zero)
#else
   /* perls before 5.28 do not have PL_sv_zero */
#  define XPUSHzero  mXPUSHi(0)
#endif

/* We can't newLOGOP because that will force scalar context */
#define allocLOGOP_CUSTOM(func, flags, first, other)  MY_allocLOGOP_CUSTOM(aTHX_ func, flags, first, other)
static LOGOP *MY_allocLOGOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *other)
{
  LOGOP *logop;
  NewOp(1101, logop, 1, LOGOP);

  logop->op_type = OP_CUSTOM;
  logop->op_ppaddr = func;
  logop->op_flags = OPf_KIDS | (U8)(flags);
  logop->op_first = first;
  logop->op_other = other;

  return logop;
}

static OP *build_blocklist(pTHX_ PADOFFSET varix, OP *block, OP *list,
  OP *(*pp_start)(pTHX), OP *(*pp_while)(pTHX), U8 op_private)
{
  /* Follow the same optree shape as grep:
   *   LOGOP whileop
   *     LISTOP startop
   *       NULOP pushmark
   *       UNOP null
   *         {block scope goes here}
   *       ... {list values go here}
   *
   * the null op protects the block body from being executed initially,
   * allowing it to be deferred
   * whileop's ->op_other points at the start of the block
   */

  /* Link block in execution order and remember its start */
  OP *blockstart = LINKLIST(block);

  /* Hide the block inside an OP_NULL with no execution */
  block = newUNOP(OP_NULL, 0, block);
  block->op_next = block;

  /* Make startop op as the list with (shielded) block prepended */
  OP *startop = list;
  if(startop->op_type != OP_LIST)
    startop = newLISTOP(OP_LIST, 0, startop, NULL);
  op_sibling_splice(startop, cLISTOPx(startop)->op_first, 0, block);
  startop->op_type = OP_CUSTOM;
  startop->op_ppaddr = pp_start;
  startop->op_targ = varix;

  LOGOP *whileop = allocLOGOP_CUSTOM(pp_while, 0, startop, blockstart);
  whileop->op_private = startop->op_private = op_private;
  whileop->op_targ = varix;

  OpLASTSIB_set(startop, (OP *)whileop);

  /* Temporarily set the whileop's op_next to NULL so as not to confuse
   * a custom RPEEP that might be set. We'll store the real start value in
   * there afterwards. See also
   *   https://rt.cpan.org/Ticket/Display.html?id=142471
   */
  OP *whilestart = LINKLIST(startop);
  whileop->op_next = NULL;
  startop->op_next = (OP *)whileop;
  cUNOPx(block)->op_first->op_next = (OP *)whileop;

  /* Since the body of the block is now hidden from the peephole optimizer
   * we'll have to run that manually now */
  optimize_optree(block);
  PL_rpeepp(aTHX_ blockstart);
  finalize_optree(block);

  whileop->op_next = whilestart;
  return (OP *)whileop;
}

/* The same ppfuncs that implement `first` can also do `any` and `all` with
 * minor changes of behaviour
 */
enum {
  FIRST_EMPTY_NO      = (1<<0), /* \  */
  FIRST_EMPTY_YES     = (1<<1), /* - if neither, returns undef */
  FIRST_RET_NO        = (1<<2), /* \  */
  FIRST_RET_YES       = (1<<3), /* - if neither, returns $_ itself */
  FIRST_STOP_ON_FALSE = (1<<4),
};

static XOP xop_firststart;
static XOP xop_firstwhile;

static OP *pp_firststart(pTHX)
{
  /* Insired by perl core's pp_grepstart() */
  dSP;
  PADOFFSET targ = PL_op->op_targ;

  if(PL_stack_base + TOPMARK == SP) {
    /* Empty */
    U8 mode = PL_op->op_private;
    (void)POPMARK;
    XPUSHs((mode & FIRST_EMPTY_NO ) ? &PL_sv_no :
           (mode & FIRST_EMPTY_YES) ? &PL_sv_yes :
                                      &PL_sv_undef);
    RETURNOP(PL_op->op_next->op_next);
  }

  PL_stack_sp = PL_stack_base + TOPMARK + 1;
  PUSHMARK(PL_stack_sp); /* current src item */

  ENTER_with_name("first");

  SV *src = PL_stack_base[TOPMARK];

  if(SvPADTMP(src)) {
    src = PL_stack_base[TOPMARK] = sv_mortalcopy(src);
    PL_tmps_floor++;
  }
  SvTEMP_off(src);

  if(targ) {
    SV **padentry = &PAD_SVl(targ);
    save_sptr(padentry);
    *padentry = SvREFCNT_inc(src);
  }
  else {
    SAVE_DEFSV;
    DEFSV_set(src);
  }

  PUTBACK;

  /* Jump to body of block */
  return (cLOGOPx(PL_op->op_next))->op_other;
}

static OP *pp_firstwhile(pTHX)
{
  /* Inspired by perl core's pp_grepwhile() */
  dSP;
  dPOPss;
  U8 mode = PL_op->op_private;
  PADOFFSET targ = PL_op->op_targ;
  SV *targsv = targ ? PAD_SVl(targ) : DEFSV;

  bool ret = SvTRUE_NN(sv);

  (*PL_markstack_ptr)++;

  if((mode & FIRST_STOP_ON_FALSE) ? !ret : ret) {
    /* Stop */

    /* Technically this means that `first` will not necessarily return the
     * value from the list, but instead returns whatever the var was set to
     * after the block has run; differing if the block modified it.
     * I'm unsure how I feel about this, but both `CORE::grep` and
     * `List::Util::first` do the same thing, so we are in good company
     */
    SV *ret = (mode & FIRST_RET_NO ) ? &PL_sv_no :
              (mode & FIRST_RET_YES) ? &PL_sv_yes :
                                       SvREFCNT_inc(targsv);
    if(targ)
      SvREFCNT_dec(targsv);

    LEAVE_with_name("first");
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;
    PUSHs(ret);
    RETURN;
  }

  if(UNLIKELY(PL_stack_base + *PL_markstack_ptr > SP)) {
    /* Empty */
    LEAVE_with_name("first");
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;
    PUSHs((mode & FIRST_EMPTY_NO ) ? &PL_sv_no :
          (mode & FIRST_EMPTY_YES) ? &PL_sv_yes :
                                     &PL_sv_undef);
    RETURN;
  }

  SV *src = PL_stack_base[TOPMARK];

  if(SvPADTMP(src)) {
    src = PL_stack_base[TOPMARK] = sv_mortalcopy(src);
    PL_tmps_floor++;
  }
  SvTEMP_off(src);

  if(targ) {
    SV **padentry = &PAD_SVl(targ);
    SvREFCNT_dec(*padentry);
    *padentry = SvREFCNT_inc(src);
  }
  else
    DEFSV_set(src);

  PUTBACK;

  return cLOGOP->op_other;
}

static int build_first(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  size_t argi = 0;
  PADOFFSET varix = 0;

  bool has_optvar = args[argi++]->i;
  if(has_optvar) {
    varix = args[argi++]->padix;
  }

  OP *block = op_contextualize(op_scope(args[argi++]->op), G_SCALAR);
  OP *list  = args[argi++]->op;

  *out = build_blocklist(aTHX_ varix, block, list,
    &pp_firststart, &pp_firstwhile, SvIV((SV *)hookdata));
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordPieceType pieces_optvar_blocklist[] = {
  XPK_PREFIXED_BLOCK(
    XPK_OPTIONAL(XPK_KEYWORD("my"), XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR))
  ),
  XPK_LISTEXPR_LISTCTX,
  {0},
};

static const struct XSParseKeywordHooks hooks_first = {
  .permit_hintkey = "List::Keywords/first",

  .pieces = pieces_optvar_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_any = {
  .permit_hintkey = "List::Keywords/any",
  .pieces = pieces_optvar_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_all = {
  .permit_hintkey = "List::Keywords/all",
  .pieces = pieces_optvar_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_none = {
  .permit_hintkey = "List::Keywords/none",
  .pieces = pieces_optvar_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_notall = {
  .permit_hintkey = "List::Keywords/notall",
  .pieces = pieces_optvar_blocklist,
  .build = &build_first,
};

static XOP xop_reducestart;
static XOP xop_reducewhile;

enum {
  REDUCE_REDUCE,
  REDUCE_REDUCTIONS,
};

static OP *pp_reducestart(pTHX)
{
  dSP;
  U8 mode = PL_op->op_private;

  if(PL_stack_base + TOPMARK == SP) {
    /* Empty */
    (void)POPMARK;
    if(GIMME_V == G_SCALAR)
      XPUSHs(&PL_sv_undef);
    RETURNOP(PL_op->op_next->op_next);
  }

  if(PL_stack_base + TOPMARK + 1 == SP) {
    /* Single item */
    (void)POPMARK;
    /* Leave the singleton there it will be fine */
    RETURNOP(PL_op->op_next->op_next);
  }

  PL_stack_sp = PL_stack_base + TOPMARK + 1;
  if(mode == REDUCE_REDUCTIONS)
    PUSHMARK(PL_stack_sp);
  PUSHMARK(PL_stack_sp);

  ENTER_with_name("reduce");

  GV *firstgv  = gv_fetchpvs("a", GV_ADD|GV_NOTQUAL, SVt_PV);
  GV *secondgv = gv_fetchpvs("b", GV_ADD|GV_NOTQUAL, SVt_PV);

  save_gp(firstgv, 0); save_gp(secondgv, 0);
  GvINTRO_off(firstgv); GvINTRO_off(secondgv);
  SAVEGENERICSV(GvSV(firstgv)); SAVEGENERICSV(GvSV(secondgv));
  SvREFCNT_inc(GvSV(firstgv)); SvREFCNT_inc(GvSV(secondgv));

  /* Initial accumulator */
  SV *sv = PL_stack_base[TOPMARK];

  if(mode == REDUCE_REDUCTIONS)
    PL_stack_base[PL_markstack_ptr[-1]++] = sv_mortalcopy(sv);

  if(SvPADTMP(sv)) {
    sv = PL_stack_base[TOPMARK] = sv_mortalcopy(sv);
    PL_tmps_floor++;
  }
  SvTEMP_off(sv);
  GvSV(firstgv) = SvREFCNT_inc(sv);

  (*PL_markstack_ptr)++;

  /* value */
  sv = PL_stack_base[TOPMARK];

  if(SvPADTMP(sv)) {
    sv = PL_stack_base[TOPMARK] = sv_mortalcopy(sv);
    PL_tmps_floor++;
  }
  SvTEMP_off(sv);
  GvSV(secondgv) = SvREFCNT_inc(sv);

  PUTBACK;

  /* Jump to body of block */
  return (cLOGOPx(PL_op->op_next))->op_other;
}

static OP *pp_reducewhile(pTHX)
{
  dSP;
  U8 mode = PL_op->op_private;
  dPOPss;

  if(mode == REDUCE_REDUCTIONS)
    PL_stack_base[PL_markstack_ptr[-1]++] = SvPADTMP(sv) ? sv_mortalcopy(sv) : sv;

  (*PL_markstack_ptr)++;

  if(UNLIKELY(PL_stack_base + *PL_markstack_ptr > SP)) {
    U8 gimme = GIMME_V;
    LEAVE_with_name("reduce");

    if(mode == REDUCE_REDUCTIONS) {
      (void)POPMARK;
      I32 retcount = --*PL_markstack_ptr - PL_markstack_ptr[-1];
      (void)POPMARK;
      SP = PL_stack_base + POPMARK;
      if(gimme == G_SCALAR) {
        SP[1] = SP[retcount];
        SP += 1;
      }
      else if(gimme == G_ARRAY)
        SP += retcount;
    }
    else {
      (void)POPMARK;
      SP = PL_stack_base + POPMARK;
      PUSHs(SvREFCNT_inc(sv));
    }
    RETURN;
  }

  GV *firstgv  = gv_fetchpvs("a", GV_ADD|GV_NOTQUAL, SVt_PV);
  GV *secondgv = gv_fetchpvs("b", GV_ADD|GV_NOTQUAL, SVt_PV);

  SvREFCNT_dec(GvSV(firstgv));
  GvSV(firstgv) = SvREFCNT_inc(sv);

  /* next value */
  sv = PL_stack_base[TOPMARK];

  if(SvPADTMP(sv)) {
    sv = PL_stack_base[TOPMARK] = sv_mortalcopy(sv);
    PL_tmps_floor++;
  }
  SvTEMP_off(sv);
  GvSV(secondgv) = SvREFCNT_inc(sv);

  PUTBACK;

  return cLOGOP->op_other;
}

static int build_reduce(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
#if !HAVE_PERL_VERSION(5,20,0)
  GV *firstgv  = gv_fetchpvs("a", GV_ADD|GV_NOTQUAL, SVt_PV);
  GV *secondgv = gv_fetchpvs("b", GV_ADD|GV_NOTQUAL, SVt_PV);

  GvMULTI_on(firstgv);
  GvMULTI_on(secondgv);
#endif

  *out = build_blocklist(aTHX_ 0, args[0]->op, args[1]->op,
    &pp_reducestart, &pp_reducewhile, SvIV((SV *)hookdata));
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordPieceType pieces_blocklist[] = {
  XPK_BLOCK_SCALARCTX,
  XPK_LISTEXPR_LISTCTX,
  {0},
};

static const struct XSParseKeywordHooks hooks_reduce = {
  .permit_hintkey = "List::Keywords/reduce",

  .pieces = pieces_blocklist,
  .build = &build_reduce,
};

static const struct XSParseKeywordHooks hooks_reductions = {
  .permit_hintkey = "List::Keywords/reductions",

  .pieces = pieces_blocklist,
  .build = &build_reduce,
};

static XOP xop_ngrepstart;
static XOP xop_ngrepwhile;

/* During the operation of ngrep, the top two marks on the markstack keep
 * track of the input values and return values, respectively */
#define VALMARK  (PL_markstack_ptr[0])
#define RETMARK  (PL_markstack_ptr[-1])

static OP *pp_ngrepstart(pTHX)
{
  /* Inspired by perl core's pp_grepstart() */
  dSP;
  PADOFFSET targ = PL_op->op_targ;
  U8 targcount = PL_op->op_private;

  if(PL_stack_base + TOPMARK == SP) {
    /* Empty */
    (void)POPMARK;
    if(GIMME_V == G_SCALAR)
      XPUSHzero;
    RETURNOP(PL_op->op_next->op_next);
  }

  PL_stack_sp = PL_stack_base + TOPMARK + 1;
  PUSHMARK(PL_stack_sp);
  PUSHMARK(PL_stack_sp);

  ENTER_with_name("ngrep");

  for(U8 targi = 0; targi < targcount; targi++) {
    SV **svp = PL_stack_base + TOPMARK;
    SV *sv = svp <= SP ? *svp : &PL_sv_undef;
    if(SvPADTMP(sv)) {
      sv = PL_stack_base[TOPMARK] = sv_mortalcopy(sv);
      PL_tmps_floor++;
    }
    SvTEMP_off(sv);

    SV **padentry = &PAD_SVl(targ + targi);
    save_sptr(padentry);
    *padentry = SvREFCNT_inc(sv);

    VALMARK++;
  }

  PUTBACK;

  /* Jump to body of block */
  return (cLOGOPx(PL_op->op_next))->op_other;
}

static OP *pp_ngrepwhile(pTHX)
{
  dSP;
  PADOFFSET targ = PL_op->op_targ;
  U8 targcount = PL_op->op_private;
  dPOPss;

  if(SvTRUE_NN(sv)) {
    /* VALMARK has already been updated to point at next chunk;
     * we'll have to look backwards */
    SV **chunksvs = PL_stack_base + VALMARK - targcount;

    for(U8 targi = 0; targi < targcount; targi++) {
      if(chunksvs + targi > SP)
        break;

      PL_stack_base[RETMARK++] = chunksvs[targi];
    }
  }

  if(UNLIKELY(PL_stack_base + VALMARK > SP)) {
    U8 gimme = GIMME_V;
    I32 retcount = --RETMARK - PL_markstack_ptr[-2]; /* origmark */

    LEAVE_with_name("ngrep");

    (void)POPMARK;
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;

    if(gimme == G_SCALAR) {
      /* No need to X this because we know we consumed at least one stack item */
      mPUSHi(retcount);
    }
    else if(gimme == G_LIST)
      SP += retcount;

    RETURN;
  }

  /* next round */

  for(U8 targi = 0; targi < targcount; targi++) {
    SV **svp = PL_stack_base + VALMARK;
    SV *sv = svp <= SP ? *svp : &PL_sv_undef;
    if(SvPADTMP(sv)) {
      sv = PL_stack_base[VALMARK] = sv_mortalcopy(sv);
      PL_tmps_floor++;
    }
    SvTEMP_off(sv);

    SV **padentry = &PAD_SVl(targ + targi);
    SvREFCNT_dec(*padentry);
    *padentry = SvREFCNT_inc(sv);

    VALMARK++;
  }

  PUTBACK;

  return cLOGOP->op_other;
}

#undef VALMARK
#undef RETMARK

static XOP xop_nmapstart;
static XOP xop_nmapwhile;

static OP *pp_nmapstart(pTHX)
{
  /* Inspired by perl core's pp_grepstart() */
  dSP;
  PADOFFSET targ = PL_op->op_targ;
  U8 targcount = PL_op->op_private;

  if(PL_stack_base + TOPMARK == SP) {
    /* Empty */
    (void)POPMARK;
    if(GIMME_V == G_SCALAR)
      XPUSHzero;
    RETURNOP(PL_op->op_next->op_next);
  }

  PL_stack_sp = PL_stack_base + TOPMARK + 1;
  PUSHMARK(PL_stack_sp);
  PUSHMARK(PL_stack_sp);

  ENTER_with_name("nmap");

  SAVETMPS;

  ENTER_with_name("nmap_item");

  for(U8 targi = 0; targi < targcount; targi++) {
    SV **svp = PL_stack_base + TOPMARK;
    SV *sv = svp <= SP ? *svp : &PL_sv_undef;
    if(SvPADTMP(sv)) {
      sv = PL_stack_base[TOPMARK] = sv_mortalcopy(sv);
      PL_tmps_floor++;
    }
    SvTEMP_off(sv);

    SV **padentry = &PAD_SVl(targ + targi);
    save_sptr(padentry);
    *padentry = SvREFCNT_inc(sv);

    (*PL_markstack_ptr)++;
  }

  PUTBACK;

  PUSHMARK(PL_stack_sp);

  /* Jump to body of block */
  return (cLOGOPx(PL_op->op_next))->op_other;
}

/* During the operation of ngrep_while, the top three marks on the markstack
 * keep track of the block result list, the input values, and the output
 * values, respectively */
#define BLOCKMARK  (PL_markstack_ptr[0])
#define VALMARK    (PL_markstack_ptr[-1])
#define RETMARK    (PL_markstack_ptr[-2])

static OP *pp_nmapwhile(pTHX)
{
  /* Inspired by perl core's pp_mapwhile() */
  dSP;
  U8 gimme = GIMME_V;
  PADOFFSET targ = PL_op->op_targ;
  U8 targcount = PL_op->op_private;

  I32 items = (SP - PL_stack_base) - BLOCKMARK;

  if(items && gimme != G_VOID) {
    if(items > (VALMARK - RETMARK)) {
      I32 shift = items - (VALMARK - RETMARK);
      I32 count = (SP - PL_stack_base) - (VALMARK - targcount);
      /* avoid needing to reshuffle the stack too often, even at the cost of
       * making holes in it */
      if(shift < count)
        shift = count;

      /* make a hole 'shift' SV*s wide */
      EXTEND(SP, shift);
      SV **src = SP;
      SV **dst = (SP += shift);
      VALMARK += shift;
      BLOCKMARK += shift;

      /* move the values up into it */
      while(count--)
        *(dst--) = *(src--);
    }

    SV **dst = PL_stack_base + (RETMARK += items) - 1;

    if(gimme == G_LIST) {
      EXTEND_MORTAL(items);
      I32 tmpsbase = PL_tmps_floor + 1;
      Move(PL_tmps_stack + tmpsbase, PL_tmps_stack + tmpsbase + items, PL_tmps_ix - PL_tmps_floor, SV *);
      PL_tmps_ix += items;

      I32 i = items;
      while(i-- > 0) {
        SV *sv = POPs;
        if(!SvTEMP(sv))
          sv = sv_mortalcopy(sv);
        *dst-- = sv;
        PL_tmps_stack[tmpsbase++] = SvREFCNT_inc_simple(sv);
      }
      PL_tmps_floor += items;
      FREETMPS;
      i = items;
      while(i-- > 0)
        SvTEMP_on(PL_tmps_stack[--tmpsbase]);
    }
    else {
      /* No point mortalcopying temporary values in scalar context */
      I32 i = items;
      while(i-- > 0) {
        (void)POPs;
        *dst-- = &PL_sv_undef;
      }
      FREETMPS;
    }
  }
  else {
    FREETMPS;
  }

  LEAVE_with_name("nmap_item");

  if(UNLIKELY(PL_stack_base + VALMARK > SP)) {
    I32 retcount = --RETMARK - PL_markstack_ptr[-3]; /* origmark */
    (void)POPMARK;
    LEAVE_with_name("nmap");

    (void)POPMARK;
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;

    if(gimme == G_SCALAR) {
      /* No need to X this because we know we consumed at least one stack item */
      mPUSHi(retcount);
    }
    else if(gimme == G_LIST)
      SP += retcount;

    RETURN;
  }

  /* next round */

  ENTER_with_name("nmap_item");

  for(U8 targi = 0; targi < targcount; targi++) {
    SV **svp = PL_stack_base + VALMARK;
    SV *sv = svp <= SP ? *svp : &PL_sv_undef;
    if(SvPADTMP(sv)) {
      sv = PL_stack_base[VALMARK] = sv_mortalcopy(sv);
      PL_tmps_floor++;
    }
    SvTEMP_off(sv);

    SV **padentry = &PAD_SVl(targ + targi);
    SvREFCNT_dec(*padentry);
    *padentry = SvREFCNT_inc(sv);

    VALMARK++;
  }

  PUTBACK;

  return cLOGOP->op_other;
}

#undef BLOCKMARK
#undef VALMARK
#undef RETMARK

enum {
  NITER_NGREP,
  NITER_NMAP,
};

static int build_niter(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  size_t argi = 0;
  int varcount = args[argi++]->i;

  /* It's very unlikely but lets just check */
  if(varcount > 255)
    croak("Using more than 255 lexical variables to an iterated block function is not currently supported");

  PADOFFSET varix = args[argi++]->padix;
  /* Because of how these vars were constructed, it really ought to be the
   * case that they have consequitive padix values. Lets just check to be sure
   */
  for(int vari = 1; vari < varcount; vari++)
    if(args[argi++]->padix != varix + vari)
      croak("ARGH: Expected consequitive padix for lexical variables");

  OP *block = op_scope(args[argi++]->op);
  OP *list  = args[argi++]->op;

  switch(SvIV((SV *)hookdata)) {
    case NITER_NGREP:
      block = op_contextualize(block, G_SCALAR);
      *out = build_blocklist(aTHX_ varix, block, list,
        &pp_ngrepstart, &pp_ngrepwhile, (U8)varcount);
      break;

    case NITER_NMAP:
      block = op_contextualize(block, G_LIST);
      *out = build_blocklist(aTHX_ varix, block, list,
        &pp_nmapstart, &pp_nmapwhile, (U8)varcount);
      break;
  }
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_ngrep = {
  .permit_hintkey = "List::Keywords/ngrep",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PREFIXED_BLOCK(
      XPK_KEYWORD("my"),
      XPK_PARENS(XPK_COMMALIST(XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR)))
    ),
    XPK_LISTEXPR_LISTCTX,
    {0},
  },
  .build = &build_niter,
};

static const struct XSParseKeywordHooks hooks_nmap = {
  .permit_hintkey = "List::Keywords/nmap",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PREFIXED_BLOCK(
      XPK_KEYWORD("my"),
      XPK_PARENS(XPK_COMMALIST(XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR)))
    ),
    XPK_LISTEXPR_LISTCTX,
    {0},
  },
  .build = &build_niter,
};

MODULE = List::Keywords    PACKAGE = List::Keywords

BOOT:
  boot_xs_parse_keyword(0.35);

  register_xs_parse_keyword("first", &hooks_first, newSViv(0));

  /* Variations on first */
  register_xs_parse_keyword("any", &hooks_any,
    newSViv(FIRST_EMPTY_NO |FIRST_RET_YES));
  register_xs_parse_keyword("all", &hooks_all,
    newSViv(FIRST_EMPTY_YES|FIRST_RET_NO|FIRST_STOP_ON_FALSE));
  register_xs_parse_keyword("none", &hooks_none,
    newSViv(FIRST_EMPTY_YES|FIRST_RET_NO));
  register_xs_parse_keyword("notall", &hooks_notall,
    newSViv(FIRST_EMPTY_NO |FIRST_RET_YES|FIRST_STOP_ON_FALSE));

  XopENTRY_set(&xop_firststart, xop_name, "firststart");
  XopENTRY_set(&xop_firststart, xop_desc, "first");
  XopENTRY_set(&xop_firststart, xop_class, OA_LISTOP);
  Perl_custom_op_register(aTHX_ &pp_firststart, &xop_firststart);

  XopENTRY_set(&xop_firstwhile, xop_name, "firstwhile");
  XopENTRY_set(&xop_firstwhile, xop_desc, "first iter");
  XopENTRY_set(&xop_firstwhile, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_firstwhile, &xop_firstwhile);

  register_xs_parse_keyword("reduce",     &hooks_reduce,     newSViv(REDUCE_REDUCE));
  register_xs_parse_keyword("reductions", &hooks_reductions, newSViv(REDUCE_REDUCTIONS));

  XopENTRY_set(&xop_reducestart, xop_name, "reducestart");
  XopENTRY_set(&xop_reducestart, xop_desc, "reduce");
  XopENTRY_set(&xop_reducestart, xop_class, OA_LISTOP);
  Perl_custom_op_register(aTHX_ &pp_reducestart, &xop_reducestart);

  XopENTRY_set(&xop_reducewhile, xop_name, "reducewhile");
  XopENTRY_set(&xop_reducewhile, xop_desc, "reduce iter");
  XopENTRY_set(&xop_reducewhile, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_reducewhile, &xop_reducewhile);

  register_xs_parse_keyword("ngrep", &hooks_ngrep, newSViv(NITER_NGREP));

  XopENTRY_set(&xop_ngrepstart, xop_name, "ngrepstart");
  XopENTRY_set(&xop_ngrepstart, xop_desc, "ngrep");
  XopENTRY_set(&xop_ngrepstart, xop_class, OA_LISTOP);
  Perl_custom_op_register(aTHX_ &pp_ngrepstart, &xop_ngrepstart);

  XopENTRY_set(&xop_ngrepwhile, xop_name, "ngrepwhile");
  XopENTRY_set(&xop_ngrepwhile, xop_desc, "ngrep iter");
  XopENTRY_set(&xop_ngrepwhile, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_ngrepwhile, &xop_ngrepwhile);

  register_xs_parse_keyword("nmap", &hooks_nmap, newSViv(NITER_NMAP));

  XopENTRY_set(&xop_nmapstart, xop_name, "nmapstart");
  XopENTRY_set(&xop_nmapstart, xop_desc, "nmap");
  XopENTRY_set(&xop_nmapstart, xop_class, OA_LISTOP);
  Perl_custom_op_register(aTHX_ &pp_nmapstart, &xop_nmapstart);

  XopENTRY_set(&xop_nmapwhile, xop_name, "nmapwhile");
  XopENTRY_set(&xop_nmapwhile, xop_desc, "nmap iter");
  XopENTRY_set(&xop_nmapwhile, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_nmapwhile, &xop_nmapwhile);
