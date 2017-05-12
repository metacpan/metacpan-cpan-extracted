#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "callparser.h"
#include "XSUB.h"
#include "ppport.h"

#define SVt_PADNAME SVt_PVMG

#ifndef COP_SEQ_RANGE_LOW_set
# ifdef newPADNAMEpvn
#  define COP_SEQ_RANGE_LOW_set(sv,val) \
  do { (sv)->xpadn_low = (val); } while (0)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) \
  do { (sv)->xpadn_high = (val); } while (0)
# else
#  define COP_SEQ_RANGE_LOW_set(sv,val) \
  do { ((XPVNV *)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = val; } while (0)
#  define COP_SEQ_RANGE_HIGH_set(sv,val) \
  do { ((XPVNV *)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = val; } while (0)
# endif
#endif

#ifndef PERL_PADSEQ_INTRO
# define PERL_PADSEQ_INTRO I32_MAX
#endif /* !PERL_PADSEQ_INTRO */

#ifndef pad_findmy_pvs
# define pad_findmy_pvs(n,f) pad_findmy((""n""), (sizeof(""n"") - 1), f)
#endif

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if PERL_VERSION_GE(5,13,0)
# define lex_stuff_sv_(sv, flags) lex_stuff_sv((sv), (flags))
# define lex_stuff_pvn_(pv, len, flags) lex_stuff_pvn((pv), (len), (flags))
#else /* <5.13.0 */
# define lex_stuff_fixup() \
  SvCUR_set(PL_parser->linestr, \
            PL_parser->bufend - SvPVX(PL_parser->linestr))
# define lex_stuff_sv_(sv, flags) \
  (lex_stuff_sv((sv), (flags)), lex_stuff_fixup())
# define lex_stuff_pvn_(pv, len, flags) \
  (lex_stuff_pvn((pv), (len), (flags)), lex_stuff_fixup())
#endif

#define lex_stuff_pvs_(s, flags) \
  lex_stuff_pvn_((""s""), sizeof(""s"")-1, (flags))

#ifndef padnamelist_store
# define padnamelist_store av_store
#endif

#define QPARSE_DIRECTLY PERL_VERSION_GE(5,13,8)

static PADOFFSET
pad_add_my_array_pvn (pTHX_ const char *namepv, STRLEN namelen)
{
  PADOFFSET offset;
#ifdef newPADNAMEpvn
  PADNAME *namesv;
#else
  SV *namesv;
#endif
  SV *myvar;

  myvar = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, 1);
  sv_upgrade(myvar, SVt_PVAV);
  offset = AvFILLp(PL_comppad);
  SvPADMY_on(myvar);

  PL_curpad = AvARRAY(PL_comppad);
#ifdef newPADNAMEpvn
  namesv = newPADNAMEpvn(namepv, namelen);
#else
  namesv = newSV_type(SVt_PADNAME);
  sv_setpvn(namesv, namepv, namelen);
#endif

  COP_SEQ_RANGE_LOW_set(namesv, PL_cop_seqmax);
  COP_SEQ_RANGE_HIGH_set(namesv, PERL_PADSEQ_INTRO);
  PL_cop_seqmax++;

  padnamelist_store(PL_comppad_name, offset, namesv);
#if PERL_VERSION_GE(5,19,3)
  PadnamelistMAXNAMED(PL_comppad_name) = offset;
#endif

  return offset;
}

static void
finish_gathering (pTHX_ AV *gatherer)
{
  SvREADONLY_on(gatherer);
}

static OP *
pp_my_padav (pTHX)
{
  dTARGET;
  SvREADONLY_off(TARG);
  SAVEDESTRUCTOR_X(finish_gathering, TARG);
  return PL_ppaddr[OP_PADAV](aTHX);
}

static PADOFFSET
pad_findgatherer (pTHX_ GV *namegv)
{
  PADOFFSET offset = pad_findmy_pvs("@List::Gather::gatherer", 0);
  if (offset == NOT_IN_PAD)
    croak("illegal use of %s outside of gather", GvNAME(namegv));

  return offset;
}

#define GENOP_GATHER_INTRO 0x1

static OP *
mygenop_padav (pTHX_ U32 flags, GV *op_namegv)
{
  OP *pvarop = newOP(OP_PADAV,
                     (flags & GENOP_GATHER_INTRO) ? (OPpLVAL_INTRO<<8) : 0);

  if (flags & GENOP_GATHER_INTRO) {
    pvarop->op_targ = pad_add_my_array_pvn(aTHX_ STR_WITH_LEN("@List::Gather::gatherer"));
    pvarop->op_ppaddr = pp_my_padav;
    PL_hints |= HINT_BLOCK_SCOPE;
    return pvarop;
  }

  pvarop->op_targ = pad_findgatherer(aTHX_ op_namegv);
  return pvarop;
}

static OP *
pp_take (pTHX)
{
  dSP;
  dMARK;
  dORIGMARK;
  dTARGET;

  if (SvREADONLY(TARG))
    croak("attempting to take after gathering already completed");

  while (MARK < SP)
    av_push((AV *)TARG, newSVsv(*++MARK));

  if (GIMME != G_ARRAY) {
    MARK = ORIGMARK;
    *++MARK = SP > ORIGMARK ? *SP : &PL_sv_undef;
    SP = MARK;
  }

  RETURN;
}

static OP *
gen_take_op (pTHX_ OP *listop, PADOFFSET gatherer_offset)
{
  OP *takeop;

  NewOpSz(0, takeop, sizeof(LISTOP));
  takeop->op_type = OP_SPLICE;
  takeop->op_ppaddr = pp_take;
  takeop->op_targ = gatherer_offset;
  cUNOPx(takeop)->op_flags = OPf_KIDS;
#ifdef op_sibling_splice
  cLISTOPx(takeop)->op_first = cLISTOPx(takeop)->op_last = NULL;
  op_sibling_splice(takeop, NULL, 0, listop);
#else
  cLISTOPx(takeop)->op_first = cLISTOPx(takeop)->op_last = listop;
#endif

  return takeop;
}

#if !QPARSE_DIRECTLY
SV *methodwrapper_sv;

static OP *(*methodwrapper_nxck_entersub)(pTHX_ OP *o);

static OP *
methodwrapper_myck_entersub (pTHX_ OP *entersubop)
{
  OP *parent = entersubop;
  OP *pushop, *sigop, *realop, *methop;

  pushop = cUNOPx(entersubop)->op_first;
  if(!OpHAS_SIBLING(pushop)) {
    parent = pushop;
    pushop = cUNOPx(pushop)->op_first;
  }

  if( (sigop = OpSIBLING(pushop)) && sigop->op_type == OP_CONST &&
     cSVOPx_sv(sigop) == methodwrapper_sv &&
     (realop = OpSIBLING(sigop)) &&
     (methop = OpSIBLING(realop)) &&
     !OpHAS_SIBLING(methop) &&
     methop->op_type == OP_METHOD_NAMED)
  {
#ifdef op_sibling_splice
    op_sibling_splice(parent, sigop, 1, NULL);
#else
    sigop->op_sibling = realop->op_sibling;
    realop->op_sibling = NULL;
#endif
    op_free(entersubop);
    return realop;
  }

  return methodwrapper_nxck_entersub(aTHX_ entersubop);
}

static OP *
myck_entersub_gatherer_intro (pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
  PERL_UNUSED_ARG(protosv);
  op_free(entersubop);
  return mygenop_padav(aTHX_ GENOP_GATHER_INTRO, namegv);
}
#endif

static OP *
myck_entersub_gather (pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
  OP *rv2cvop, *pushop, *blkop, *parent;

  PERL_UNUSED_ARG(namegv);
  PERL_UNUSED_ARG(protosv);

  pushop = cUNOPx((parent = entersubop))->op_first;
  if (!OpHAS_SIBLING(pushop))
    pushop = cUNOPx((parent = pushop))->op_first;

  blkop = OpSIBLING(pushop);

#ifdef op_sibling_splice
  op_sibling_splice(parent, pushop, 1, NULL);
#else
  rv2cvop = blkop->op_sibling;
  blkop->op_sibling = NULL;
  pushop->op_sibling = rv2cvop;
#endif
  op_free(entersubop);

  return blkop;
}

static OP *
myck_entersub_take (pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
  OP *listop, *lastop, *rv2cvop;
  PADOFFSET gatherer_offset;

  PERL_UNUSED_ARG(protosv);

  gatherer_offset = pad_findgatherer(aTHX_ namegv);

  entersubop = ck_entersub_args_list(entersubop);
  listop = cUNOPx(entersubop)->op_first;
  if (!listop)
    return entersubop;

  entersubop->op_flags &= ~OPf_KIDS;
  cUNOPx(entersubop)->op_first = NULL;
  op_free(entersubop);

  lastop = cLISTOPx(listop)->op_first;
  while (OpSIBLING(lastop) != cLISTOPx(listop)->op_last)
    lastop = OpSIBLING(lastop);
  rv2cvop = OpSIBLING(lastop);

#ifdef op_sibling_splice
  op_sibling_splice(listop, lastop, -1, NULL);
#else
  lastop->op_sibling = NULL;
  cLISTOPx(listop)->op_last = lastop;
#endif
  op_free(rv2cvop);

  return gen_take_op(aTHX_ listop, gatherer_offset);
}

static OP *
myck_entersub_gathered (pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
  PERL_UNUSED_ARG(protosv);
  op_free(entersubop);
  return mygenop_padav(aTHX_ 0, namegv);
}

static OP *
myparse_args_gather (pTHX_ GV *namegv, SV *psobj, U32 *flagsp)
{
  bool had_paren, is_modifier;
#if QPARSE_DIRECTLY
  int blk_floor;
  OP *blkop, *initop;
#else
  PERL_UNUSED_ARG(namegv);
#endif

  PERL_UNUSED_ARG(psobj);

  lex_read_space(0);
  had_paren = lex_peek_unichar(0) == '(';
  if (had_paren) {
    lex_read_unichar(0);
    lex_read_space(0);
  }

  is_modifier = lex_peek_unichar(0) != '{';

  if (is_modifier && had_paren)
    croak("syntax error");

#if QPARSE_DIRECTLY
  blk_floor = Perl_block_start(aTHX_ 1);
  initop = mygenop_padav(aTHX_ GENOP_GATHER_INTRO, namegv);
  blkop = op_prepend_elem(OP_LINESEQ, initop,
                          is_modifier ? parse_barestmt(0) : parse_block(0));
  blkop = op_append_elem(OP_LINESEQ, blkop,
                         newSTATEOP(0, NULL, mygenop_padav(aTHX_ 0, namegv)));
  blkop = Perl_block_end(aTHX_ blk_floor, blkop);

  if (had_paren) {
    lex_read_space(0);
    if (lex_peek_unichar(0) != ')')
      croak("syntax error");
    lex_read_unichar(0);
    *flagsp |= CALLPARSER_PARENS;
  }

  return op_scope(blkop);
#else
  if (is_modifier)
    croak("syntax error (statement modifier syntax not supported on perls before 5.13.8)");
  lex_read_unichar(0);

  lex_stuff_pvs_("}}", 0);
  lex_stuff_pvs_("List::Gather::_stuff(';List::Gather::gathered;}')", 0);
  if (had_paren)
    *flagsp |= CALLPARSER_PARENS;
  else
    lex_stuff_pvs_("List::Gather::_stuff(')');", 0);
  lex_stuff_pvs_("BEGIN{B::Hooks::EndOfScope::on_scope_end{", 0);
  lex_stuff_pvs_("->x(do{List::Gather::_gatherer_intro;do{", 0);

  return newSVOP(OP_CONST, 0, SvREFCNT_inc(methodwrapper_sv));
#endif
}

MODULE = List::Gather  PACKAGE = List::Gather

void
gather (...)
  CODE:
    PERL_UNUSED_VAR(items);
    croak("gather called as a function");

void
take (...)
  CODE:
    PERL_UNUSED_VAR(items);
    croak("take called as a function");

void
gathered (...)
  PROTOTYPE:
  CODE:
    PERL_UNUSED_VAR(items);
    croak("gathered called as a function");

#if !QPARSE_DIRECTLY

void
_stuff(SV *sv)
  PROTOTYPE: $
  CODE:
    lex_stuff_sv_(sv, 0);

void
_gatherer_intro (...)
  PROTOTYPE:
  CODE:
    PERL_UNUSED_VAR(items);
    croak("_gatherer_intro called as a function");

#endif

bool
_QPARSE_DIRECTLY ()
  CODE:
    RETVAL = QPARSE_DIRECTLY;
  OUTPUT:
    RETVAL

BOOT:
{
  CV *gather_cv, *take_cv, *gathered_cv;
#if !QPARSE_DIRECTLY
  CV *gatherer_intro_cv;

  methodwrapper_sv = newSVpvs("");
  methodwrapper_nxck_entersub = PL_check[OP_ENTERSUB];
  PL_check[OP_ENTERSUB] = methodwrapper_myck_entersub;

  gatherer_intro_cv = get_cv("List::Gather::_gatherer_intro", 0);
  cv_set_call_checker(gatherer_intro_cv, myck_entersub_gatherer_intro,
                      (SV*)gatherer_intro_cv);
#endif

  gather_cv = get_cv("List::Gather::gather", 0);
  take_cv = get_cv("List::Gather::take", 0);
  gathered_cv = get_cv("List::Gather::gathered", 0);

  cv_set_call_parser(gather_cv, myparse_args_gather, &PL_sv_undef);

  cv_set_call_checker(gather_cv, myck_entersub_gather, (SV*)gather_cv);
  cv_set_call_checker(take_cv, myck_entersub_take, (SV*)take_cv);
  cv_set_call_checker(gathered_cv, myck_entersub_gathered, (SV*)gathered_cv);
}
