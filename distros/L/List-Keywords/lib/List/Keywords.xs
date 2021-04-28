/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

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

  SAVE_DEFSV;

  SV *src = PL_stack_base[TOPMARK];

  if(SvPADTMP(src)) {
    src = PL_stack_base[TOPMARK] = sv_mortalcopy(src);
    PL_tmps_floor++;
  }
  SvTEMP_off(src);
  DEFSV_set(src);

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

  bool ret = SvTRUE_NN(sv);

  (*PL_markstack_ptr)++;

  if((mode & FIRST_STOP_ON_FALSE) ? !ret : ret) {
    /* Stop */

    /* Technically this means that `first` will not necessarily return the
     * value from the list, but instead returns whatever $_ was set to after
     * the block has run; differing if the block modified it.
     * I'm unsure how I feel about this, but both `CORE::grep` and
     * `List::Util::first` do the same thing, so we are in good company
     */
    SV *ret = (mode & FIRST_RET_NO ) ? &PL_sv_no :
              (mode & FIRST_RET_YES) ? &PL_sv_yes :
                                       sv_mortalcopy(DEFSV);
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
  DEFSV_set(src);

  PUTBACK;

  return cLOGOP->op_other;
}

static int build_first(pTHX_ OP **out, XSParseKeywordPiece *args, size_t npieces, void *hookdata)
{
  OP *block = op_contextualize(op_scope(args[0].op), G_SCALAR);
  OP *list  = op_contextualize(args[1].op, G_ARRAY);

  /* Follow the same optree shape as grep:
   *   LOGOP firstwhile
   *     LISTOP firststart
   *       NULOP pushmark
   *       UNOP null
   *         {block scope goes here}
   *       ... {list values go here}
   *
   * the null op protects the block body from being executed initially,
   * allowing it to be deferred
   * firstwhile's ->op_other points at the start of the block
   */

  /* Link block in execution order and remember its start */
  OP *blockstart = LINKLIST(block);

  /* Hide the block inside an OP_NULL with no execution */
  block = newUNOP(OP_NULL, 0, block);
  block->op_next = block;

  /* Make firststart op as the list with (shielded) block prepended */
  OP *firststart = list;
  if(firststart->op_type != OP_LIST)
    firststart = newLISTOP(OP_LIST, 0, firststart, NULL);
  op_sibling_splice(firststart, cLISTOPx(firststart)->op_first, 0, block);
  firststart->op_type = OP_CUSTOM;
  firststart->op_ppaddr = &pp_firststart;

  LOGOP *firstwhile = allocLOGOP_CUSTOM(&pp_firstwhile, 0, firststart, blockstart);
  firstwhile->op_private = firststart->op_private = SvIV((SV *)hookdata);

  OpLASTSIB_set(firststart, (OP *)firstwhile);

  firstwhile->op_next = LINKLIST(firststart);
  firststart->op_next = (OP *)firstwhile;
  cUNOPx(block)->op_first->op_next = (OP *)firstwhile;

  /* Since the body of the block is now hidden from the peephole optimizer
   * we'll have to run that manually now */
  PL_rpeepp(aTHX_ blockstart);

  *out = (OP *)firstwhile;
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordPieceType pieces_blocklist[] = {
  XPK_BLOCK,
  XPK_LISTEXPR,
  0,
};

static const struct XSParseKeywordHooks hooks_first = {
  .permit_hintkey = "List::Keywords/first",

  .pieces = pieces_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_any = {
  .permit_hintkey = "List::Keywords/any",
  .pieces = pieces_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_all = {
  .permit_hintkey = "List::Keywords/all",
  .pieces = pieces_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_none = {
  .permit_hintkey = "List::Keywords/none",
  .pieces = pieces_blocklist,
  .build = &build_first,
};

static const struct XSParseKeywordHooks hooks_notall = {
  .permit_hintkey = "List::Keywords/notall",
  .pieces = pieces_blocklist,
  .build = &build_first,
};

MODULE = List::Keywords    PACKAGE = List::Keywords

BOOT:
  boot_xs_parse_keyword(0);

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
