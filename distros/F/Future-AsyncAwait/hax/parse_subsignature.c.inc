/* vi: set ft=c inde=: */

#ifndef parse_subsignature

#define PERL_EXT
#include "feature.h"

/*
 * Need to grab some things that aren't quite core perl API
 */

/* yyerror() is a long function and hard to emulate or copy-paste for our
 * purposes; we'll reïmplement a smaller version of it
 */

#define LEX_IGNORE_UTF8_HINTS   0x00000002

#define PL_linestr (PL_parser->linestr)

#ifdef USE_UTF8_SCRIPTS
#   define UTF cBOOL(!IN_BYTES)
#else
#   define UTF cBOOL((PL_linestr && DO_UTF8(PL_linestr)) || ( !(PL_parser->lex_flags & LEX_IGNORE_UTF8_HINTS) && (PL_hints & HINT_UTF8)))
#endif

#define yyerror(s)  S_yyerror(aTHX_ s)
void S_yyerror(pTHX_ const char *s)
{
  SV *message = sv_2mortal(newSVpvs_flags("", 0));

  char *context = PL_parser->oldbufptr;
  STRLEN contlen = PL_parser->bufptr - PL_parser->oldbufptr;

  sv_catpvf(message, "%s at %s line %" IVdf,
      s, OutCopFILE(PL_curcop), CopLINE(PL_curcop));

  if(context)
    sv_catpvf(message, ", near \"%" UTF8f "\"",
        UTF8fARG(UTF, contlen, context));

  sv_catpvf(message, "\n");

  PL_parser->error_count++;
  warn(SvPVX(message));
}

/* Stolen from op.c */
#define OpTYPE_set(op, type)         \
  STMT_START {                       \
    op->op_type   = (OPCODE)type;    \
    op->op_ppaddr = PL_ppaddr[type]; \
  } STMT_END

#define alloc_LOGOP(a,b,c)  S_alloc_LOGOP(aTHX_ a,b,c)
static LOGOP *S_alloc_LOGOP(pTHX_ I32 type, OP *first, OP* other)
{
  dVAR;
  LOGOP *logop;
  OP *kid = first;
  NewOp(1101, logop, 1, LOGOP);
  OpTYPE_set(logop, type);
  logop->op_first = first;
  logop->op_other = other;
  if (first)
    logop->op_flags = OPf_KIDS;
  while (kid && OpHAS_SIBLING(kid))
    kid = OpSIBLING(kid);
  if (kid)
    OpLASTSIB_set(kid, (OP*)logop);
  return logop;
}

#define parse_sigelem()  S_parse_sigelem(aTHX)
static OP *S_parse_sigelem(pTHX)
{
  yy_parser *parser = PL_parser;

  int c = lex_peek_unichar(0);
  int flags;

  switch(c) {
    case '$': flags = OPpARGELEM_SV; break;
    case '@': flags = OPpARGELEM_AV; break;
    case '%': flags = OPpARGELEM_HV; break;
    default:
      return NULL;
  }

  char *lexname = parser->bufptr;
  OP *varop = NULL;

  /* Consume sigil */
  lex_read_unichar(0);

  if(isIDFIRST_uni(lex_peek_unichar(0))) {
    lex_read_unichar(0);
    while(isALNUM_uni(lex_peek_unichar(0)))
      lex_read_unichar(0);
    lex_read_space(0);

    varop = newUNOP_AUX(OP_ARGELEM, 0, NULL, INT2PTR(UNOP_AUX_item *, (parser->sig_elems)));
    varop->op_private |= flags;

    varop->op_targ = pad_add_name_pvn(lexname, PL_parser->bufptr - lexname, 0, NULL, NULL);
  }

  if(c == '$') {
    if(parser->sig_slurpy)
      yyerror("Slurpy parameters not last");

    parser->sig_elems++;

    if(lex_peek_unichar(0) == '=') {
      lex_read_unichar(0);
      lex_read_space(0);

      parser->sig_optelems++;

      OP *defexpr = parse_termexpr(0);

      OP *defop = (OP *)alloc_LOGOP(OP_ARGDEFELEM, defexpr, LINKLIST(defexpr));
      defop->op_targ = (PADOFFSET)(parser->sig_elems - 1);

      varop->op_flags |= OPf_STACKED;
      op_sibling_splice(varop, NULL, 0, defop);
      defop = op_contextualize(defop, G_SCALAR);

      LINKLIST(varop);

      varop->op_next = defop;
      defexpr->op_next = varop;
    }
    else {
      if(parser->sig_optelems)
        yyerror("Mandatory parameter follows optional parameter");
    }
  }
  else {
    if(parser->sig_slurpy)
      yyerror("Multiple slurpy parameters not allowed");

    parser->sig_slurpy = c;

    if(lex_peek_unichar(0) == '=')
      yyerror("A slurpy parameter may not have a default value");
  }

  return varop ? newSTATEOP(0, NULL, varop) : NULL;
}

#define parse_subsignature(flags)  S_parse_subsignature(aTHX_ flags)
static OP *S_parse_subsignature(pTHX_ int flags)
{
  /* Mostly reconstructed logic from perl 5.28.0's toke.c and perly.y
   */
  yy_parser *parser = PL_parser;

  ENTER;
  SAVEIV(parser->sig_elems);
  SAVEIV(parser->sig_optelems);
  SAVEI8(parser->sig_slurpy);

  parser->sig_elems = 0;
  parser->sig_optelems = 0;
  parser->sig_slurpy = 0;

  OP *elems = NULL;
  while(lex_peek_unichar(0) != ')') {
    OP *elem = parse_sigelem();
    elems = op_append_list(OP_LINESEQ, elems, elem);

    if(PL_parser->error_count) {
      LEAVE;
      return NULL;
    }

    lex_read_space(0);
    switch(lex_peek_unichar(0)) {
      case ')': goto endofelems;
      case ',': break;
      default:
        fprintf(stderr, "ARGH unsure how to proceed parse_subsignature at <%s>\n",
            parser->bufptr);
        croak("ARGH");
        break;
    }

    lex_read_unichar(0);
    lex_read_space(0);
  }
endofelems:

  if(!elems) {
    LEAVE;
    return NULL;
  }

  if (!FEATURE_SIGNATURES_IS_ENABLED)
    croak("Experimental subroutine signatures not enabled");

  Perl_ck_warner_d(aTHX_ packWARN(WARN_EXPERIMENTAL__SIGNATURES),
    "The signatures feature is experimental");

  UNOP_AUX_item *aux = (UNOP_AUX_item *)PerlMemShared_malloc(sizeof(UNOP_AUX_item) * 3);
  aux[0].iv = parser->sig_elems;
  aux[1].iv = parser->sig_optelems;
  aux[2].iv = parser->sig_slurpy;

  OP *checkop = newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux);

  LEAVE;

  return op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
      op_prepend_elem(OP_LINESEQ, checkop, elems));
}

#endif
