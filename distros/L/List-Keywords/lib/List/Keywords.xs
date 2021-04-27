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

static XOP xop_anystart;
static XOP xop_anywhile;

static OP *pp_anystart(pTHX)
{
  /* Insired by perl core's pp_grepstart() */
  dSP;

  PL_stack_sp = PL_stack_base + TOPMARK + 1;
  PUSHMARK(PL_stack_sp); /* current src item */

  ENTER_with_name("any");

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

static OP *pp_anywhile(pTHX)
{
  /* Inspired by perl core's pp_grepwhile() */
  dSP;
  dPOPss;
  U8 mode = PL_op->op_private;

  bool ret = SvTRUE_NN(sv);

  (*PL_markstack_ptr)++;

  if(mode ^ ret) {
    LEAVE_with_name("any");
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;
    PUSHs(mode ? &PL_sv_no : &PL_sv_yes);
    RETURN;
  }

  if(UNLIKELY(PL_stack_base + *PL_markstack_ptr > SP)) {
    LEAVE_with_name("any");
    (void)POPMARK;
    SP = PL_stack_base + POPMARK;
    PUSHs(mode ? &PL_sv_yes : &PL_sv_no);
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

static int build_any(pTHX_ OP **out, XSParseKeywordPiece *args, size_t npieces, void *hookdata)
{
  OP *block = op_contextualize(op_scope(args[0].op), G_SCALAR);
  OP *list  = op_contextualize(args[1].op, G_ARRAY);

  /* Follow the same optree shape as grep:
   *   LOGOP anywhile
   *     LISTOP anystart
   *       NULOP pushmark
   *       UNOP null
   *         {block scope goes here}
   *       ... {list values go here}
   *
   * the null op protects the block body from being executed initially,
   * allowing it to be deferred
   * anywhile's ->op_other points at the start of the block
   */

  /* Link block in execution order and remember its start */
  OP *blockstart = LINKLIST(block);

  /* Hide the block inside an OP_NULL with no execution */
  block = newUNOP(OP_NULL, 0, block);
  block->op_next = block;

  /* Make anystart op as the list with (shielded) block prepended */
  OP *anystart = list;
  if(anystart->op_type != OP_LIST)
    anystart = newLISTOP(OP_LIST, 0, anystart, NULL);
  op_sibling_splice(anystart, cLISTOPx(anystart)->op_first, 0, block);
  anystart->op_type = OP_CUSTOM;
  anystart->op_ppaddr = &pp_anystart;

  /* We can't newLOGOP because that will force anystart into scalar context */
  LOGOP *anywhile;
  NewOp(1101, anywhile, 1, LOGOP);
  anywhile->op_type = OP_CUSTOM;
  anywhile->op_ppaddr = &pp_anywhile;
  anywhile->op_first = anystart;
  anywhile->op_flags = OPf_KIDS;
  anywhile->op_other = blockstart;

  OpLASTSIB_set(anystart, (OP *)anywhile);

  anywhile->op_next = LINKLIST(anystart);
  anystart->op_next = (OP *)anywhile;
  cUNOPx(block)->op_first->op_next = (OP *)anywhile;

  anywhile->op_private = SvIV((SV *)hookdata);

  /* Since the body of the block is now hidden from the peephole optimizer
   * we'll have to run that manually now */
  PL_rpeepp(aTHX_ blockstart);

  *out = (OP *)anywhile;
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_any = {
  .permit_hintkey = "List::Keywords/any",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BLOCK,
    XPK_LISTEXPR,
    0,
  },
  .build = &build_any,
};

static const struct XSParseKeywordHooks hooks_all = {
  .permit_hintkey = "List::Keywords/all",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BLOCK,
    XPK_LISTEXPR,
    0,
  },
  .build = &build_any,
};

MODULE = List::Keywords    PACKAGE = List::Keywords

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("any", &hooks_any, newSViv(0));
  register_xs_parse_keyword("all", &hooks_all, newSViv(1));

  XopENTRY_set(&xop_anystart, xop_name, "anystart");
  XopENTRY_set(&xop_anystart, xop_desc, "any");
  XopENTRY_set(&xop_anystart, xop_class, OA_LISTOP);
  Perl_custom_op_register(aTHX_ &pp_anystart, &xop_anystart);

  XopENTRY_set(&xop_anywhile, xop_name, "anywhile");
  XopENTRY_set(&xop_anywhile, xop_desc, "any iter");
  XopENTRY_set(&xop_anywhile, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_anywhile, &xop_anywhile);
