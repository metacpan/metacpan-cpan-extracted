/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AsyncAwait.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"
#include "forbid_outofblock_ops.c.inc"
#include "newOP_CUSTOM.c.inc"

enum {
  HOOK_SUSPEND = 1,
  HOOK_RESUME,
};

static void S_call_block_noargs(pTHX_ SV *blocksv)
{
  OP *start = NUM2PTR(OP *, SvUV(blocksv));
  I32 was_cxstack_ix = cxstack_ix;

  cx_pushblock(CXt_BLOCK, G_VOID, PL_stack_sp, PL_savestack_ix);
  ENTER;
  SAVETMPS;

  SAVEOP();
  PL_op = start;
  CALLRUNOPS(aTHX);

  FREETMPS;
  LEAVE;

  if(cxstack_ix != was_cxstack_ix + 1) {
    croak("panic: A non-local control flow operation exited a suspend/resume block");
  }

  PERL_CONTEXT *cx = CX_CUR();
  PL_stack_sp = PL_stack_base + cx->blk_oldsp;

  dounwind(was_cxstack_ix);
}
#define call_block_noargs(blocksv)  S_call_block_noargs(aTHX_ blocksv)

static void hook_pre_suspend(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  SV **svp = hv_fetchs(modhookdata, "Future::AsyncAwait::Hooks/hooklist", 0);
  if(!svp)
    return;

  AV *hooklist = (AV *)*svp;
  svp = AvARRAY(hooklist);

  I32 i;
  for(i = 0; i <= AvFILL(hooklist); i += 2) {
    int type = SvIV(svp[i]);
    if(type == HOOK_SUSPEND)
      call_block_noargs(svp[i+1]);
  }
}

static void hook_post_resume(pTHX_ CV *cv, HV *modhookdata, void *hookdata)
{
  SV **svp = hv_fetchs(modhookdata, "Future::AsyncAwait::Hooks/hooklist", 0);
  if(!svp)
    return;

  AV *hooklist = (AV *)*svp;
  svp = AvARRAY(hooklist);

  I32 i;
  for(i = AvFILL(hooklist)-1; i >= 0; i -= 2) {
    int type = SvIV(svp[i]);
    if(type == HOOK_RESUME)
      call_block_noargs(svp[i+1]);
  }
}

static const struct AsyncAwaitHookFuncs faa_hooks = {
  .pre_suspend = &hook_pre_suspend,
  .post_resume = &hook_post_resume,
};

#define SAVEAVLEN(av)  S_save_avlen(aTHX_ av)
/* This would be a lot neater if perl had a SAVEFUNCANY2() */
struct AvWithLength {
  AV *av;
  U32 len;
};
void restore_av_len(pTHX_ void *_avl)
{
  struct AvWithLength *avl = _avl;
  AV *av = avl->av;

  while(av_count(av) > avl->len)
    SvREFCNT_dec(av_pop(av));

  Safefree(avl);
}
static void S_save_avlen(pTHX_ AV *av)
{
  struct AvWithLength *avl;
  Newx(avl, 1, struct AvWithLength);

  avl->av = av;
  avl->len = av_count(av);

  SAVEDESTRUCTOR_X(restore_av_len, avl);
}

static OP *pp_pushhook(pTHX)
{
  OP *blockstart = cLOGOP->op_other;
  int type = PL_op->op_private;

  HV *modhookdata = future_asyncawait_get_modhookdata(find_runcv(0), FAA_MODHOOK_CREATE, PL_op->op_targ);
  if(!modhookdata)
    croak("panic: expected modhookdata");

  AV *hooklist;
  SV **svp = hv_fetchs(modhookdata, "Future::AsyncAwait::Hooks/hooklist", 0);
  if(svp)
    hooklist = (AV *)*svp;
  else
    hv_stores(modhookdata, "Future::AsyncAwait::Hooks/hooklist", (SV *)(hooklist = newAV()));

  SAVEAVLEN(hooklist);

  av_push(hooklist, newSViv(type));
  /* We can't push an OP * to the AV, but we can wrap it */
  av_push(hooklist, newSVuv(PTR2UV(blockstart)));

  return PL_op->op_next;
}

static OP *build_pushhook_op(pTHX_ OP *block, int phase, const char *name)
{
  forbid_outofblock_ops(block, name);

  OP *o = newLOGOP_CUSTOM(&pp_pushhook, 0,
    newOP(OP_NULL, 0), block);

  /* The actual pp_pushhook LOGOP is the op_first of o */
  LOGOP *pushhooko = (LOGOP *)cUNOPo->op_first;
  pushhooko->op_targ = future_asyncawait_make_precreate_padix();
  pushhooko->op_private = phase;

  /* ensure the block will terminate properly */
  block->op_next = NULL;

  return o;
}

static int build_suspend(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *block = arg0->op;

  *out = build_pushhook_op(aTHX_ block, HOOK_SUSPEND, "a suspend block");

  return KEYWORD_PLUGIN_STMT;
}

static int build_resume(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *block = arg0->op;

  *out = build_pushhook_op(aTHX_ block, HOOK_RESUME, "a resume block");

  return KEYWORD_PLUGIN_STMT;
}

static const struct XSParseKeywordHooks hooks_suspend = {
  .permit_hintkey = "Future::AsyncAwait::Hooks/suspend",
  .piece1 = XPK_BLOCK,
  .build1 = &build_suspend,
};

static const struct XSParseKeywordHooks hooks_resume = {
  .permit_hintkey = "Future::AsyncAwait::Hooks/resume",
  .piece1 = XPK_BLOCK,
  .build1 = &build_resume,
};

MODULE = Future::AsyncAwait::Hooks    PACKAGE = Future::AsyncAwait::Hooks

BOOT:
  boot_future_asyncawait(0.64);
  boot_xs_parse_keyword(0.13);

  register_future_asyncawait_hook(&faa_hooks, NULL);

  register_xs_parse_keyword("suspend", &hooks_suspend, NULL);
  register_xs_parse_keyword("resume",  &hooks_resume,  NULL);
