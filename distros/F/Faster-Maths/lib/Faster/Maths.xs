/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */
#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5,28,0)
#  define GET_UNOP_AUX_item_pv(aux)    ((aux).pv)
#  define SET_UNOP_AUX_item_pv(aux,v)  ((aux).pv = (v))
#else
#  define GET_UNOP_AUX_item_pv(aux)    INT2PTR(char *, (aux).uv)
#  define SET_UNOP_AUX_item_pv(aux,v)  ((aux).uv = PTR2UV(v))
#endif

static XOP xop_multimath;
static OP *pp_multimath(pTHX)
{
  dSP;
  dTARGET;
  UNOP_AUX_item *aux = cUNOP_AUX->op_aux;

  char *prog = GET_UNOP_AUX_item_pv(aux[0]) + 1; /* skip leading '(' */
  U32 ntmps = PL_op->op_private;

  U32 tmpi = 1;
  NV accum;

  U32 auxi = 1 + ntmps;

  switch(*(prog++)) {
    case 'p':
      accum = SvNV_nomg(PAD_SV(aux[auxi].pad_offset));
      auxi++;
      break;

    case 'c':
      accum = SvNV_nomg(aux[auxi].sv);
      auxi++;
      break;

    default:
      croak("ARGH: initial prog instruction");
  }

  while(*prog) {
    char op = *(prog++);
    switch(op) {
      case '+':
      case '-':
      case '*':
      case '/':
      {
        NV rhs;
        switch(*(prog++)) {
          case 'p':
            rhs = SvNV_nomg(PAD_SV(aux[auxi].pad_offset));
            auxi++;
            break;
          case 'c':
            rhs = SvNV_nomg(aux[auxi].sv);
            auxi++;
            break;
          case ')':
            rhs = accum;
            tmpi--;
            accum = SvNV_nomg(PAD_SV(aux[tmpi].pad_offset));
            break;
          default:
            croak("ARGH MULTIMATH arg %c\n", prog[-1]);
        }

        switch(op) {
          case '+':
            accum += rhs;
            break;
          case '-':
            accum -= rhs;
            break;
          case '*':
            accum *= rhs;
            break;
          case '/':
            accum /= rhs;
            break;
        }
        break;
      }

      case '(':
      {
        NV val;
        switch(*(prog++)) {
          case 'p':
            val = SvNV_nomg(PAD_SV(aux[auxi].pad_offset));
            auxi++;
            break;
          case 'c':
            val = SvNV_nomg(aux[auxi].sv);
            auxi++;
            break;
        }
        sv_setnv(PAD_SV(aux[tmpi].pad_offset), accum);
        tmpi++;
        accum = val;
        break;
      }

      default:
        croak("TODO: MULTIMATH %c\n", op);
    }
  }

  EXTEND(SP, 1);
  PUSHn(accum);
  RETURN;
}

#define optimize_maths(start, final)  MY_optimize_maths(aTHX_ start, final)
static OP *MY_optimize_maths(pTHX_ OP *start, OP *final)
{
  OP *o;

  /* Phase 1: just count the number of aux items we need
   * We'll need one for every constant or padix
   * Also count the maximum stack height
   */
  U32 nitems = 1; /* aux[0] is the program */
  U32 height = 0, maxheight = 0;

  for(o = start; o; o = o->op_next) {
    switch(o->op_type) {
      case OP_CONST:
      case OP_PADSV:
        nitems++;
        height++;
        break;

      case OP_ADD:
      case OP_SUBTRACT:
      case OP_MULTIPLY:
      case OP_DIVIDE:
        height--;
        break;
    }

    if(height > maxheight)
      maxheight = height;

    if(o == final)
      break;
  }

  U32 ntmps = maxheight - 1;

  UNOP_AUX_item *aux;
  Newx(aux, nitems + ntmps, UNOP_AUX_item);

  SV *prog = newSV(0);
  sv_setpvs(prog, "");

  U32 tmpi = 1;
  U32 auxi = 1 + ntmps;

  /* Phase 2: collect up the constants and padices, build the program string */
  char lastarg = ')';
  char operator;
  for(o = start; o; o = o->op_next) {
    switch(o->op_type) {
      case OP_CONST:
        if(lastarg != ')')
          sv_catpvf(prog, "(%c", lastarg);
        lastarg = 'c';
        aux[auxi++].sv = SvREFCNT_inc(cSVOPo->op_sv);
        break;

      case OP_PADSV:
        if(lastarg != ')')
          sv_catpvf(prog, "(%c", lastarg);
        lastarg = 'p';
        aux[auxi++].pad_offset = o->op_targ;
        break;

      case OP_ADD:
        operator = '+';
        goto do_BINOP;
      case OP_SUBTRACT:
        operator = '-';
        goto do_BINOP;
      case OP_MULTIPLY:
        operator = '*';
        goto do_BINOP;
      case OP_DIVIDE:
        operator = '/';
        goto do_BINOP;

do_BINOP:
        sv_catpvf(prog, "%c%c", operator, lastarg);
        lastarg = ')';

        /* Steal a padtmp because that won't be using it */
        if(tmpi <= ntmps)
          aux[tmpi++].pad_offset = o->op_targ;
        break;


      default:
        croak("ARGH unsure how to optimize this op\n");
    }

    if(o == final)
      break;
  }

  if(SvPVX(prog)[0] != '(')
    croak("ARGH: expected prog to begin (");

  /* Steal the buffer */
  SET_UNOP_AUX_item_pv(aux[0], SvPVX(prog)); SvLEN(prog) = 0;
  SvREFCNT_dec(prog);

  OP *retop = newUNOP_AUX(OP_CUSTOM, 0, NULL, aux);
  retop->op_ppaddr = &pp_multimath;
  retop->op_private = ntmps;
  retop->op_targ = final->op_targ;

  return retop;
}

static void rpeep_for_fastermaths(pTHX_ OP *o, bool init_enabled);
static void rpeep_for_fastermaths(pTHX_ OP *o, bool init_enabled)
{
  bool enabled = init_enabled;

  OP *prevo = NULL;

  /* In some cases (e.g.  while(1) { ... } ) the ->op_next chain actually
   * forms a closed loop. In order to detect this loop and break out we'll
   * advance the `slowo` pointer half as fast as o. If o is ever equal to
   * slowo then we have reached a cycle and should stop
   */
  OP *slowo = NULL;
  int slowotick = 0;

  while(o && o != slowo) {
    if(o->op_type == OP_NEXTSTATE) {
      SV *sv = cop_hints_fetch_pvs(cCOPo, "Faster::Maths/faster", 0);
      enabled = sv && sv != &PL_sv_placeholder && SvTRUE(sv);
      goto next_o;
    }
    if(!enabled)
      goto next_o;

    /* There are no BASEOP mathsy ops, so any optimizable sequence necessarily
     * starts with an argument
     */
    switch(o->op_type) {
      case OP_CONST:
      case OP_PADSV:
        break;

      case OP_OR:
      case OP_AND:
      case OP_DOR:
#if HAVE_PERL_VERSION(5,32,0)
      case OP_CMPCHAIN_AND:
#endif
      case OP_COND_EXPR:
      case OP_MAPWHILE:
      case OP_ANDASSIGN:
      case OP_ORASSIGN:
      case OP_DORASSIGN:
      case OP_RANGE:
      case OP_ONCE:
#if HAVE_PERL_VERSION(5,26,0)
      case OP_ARGDEFELEM:
#endif
        /* Optimize on the righthand side of `or` / `and` operators and other.
         * similar cases. This might catch more things than perl's own
         * recursion inside because simple expressions don't begin with an
         * OP_NEXTSTATE
         */
        if(cLOGOPo->op_other && cLOGOPo->op_other->op_type != OP_NEXTSTATE)
          rpeep_for_fastermaths(aTHX_ cLOGOPo->op_other, enabled);
        goto next_o;

      default:
        goto next_o;
    }

    /* Find a sequence of mathsy args/ops we can optimize */
    OP *final = NULL;       /* the final op in the optimizable chain */
    U32 final_opcount = 0;  /* total number of operations we found until final */
    {
      U32 opcount = 0;
      U32 height = 0; /* running height of the stack */

      OP *scout;
      for(scout = o; scout; scout = scout->op_next) {
        switch(scout->op_type) {
          /* OPs that push 1 argument */
          case OP_CONST:
          case OP_PADSV:
            height++;
            break;

          /* BINOPs that consume 2, push 1 */
          case OP_ADD:
          case OP_SUBTRACT:
          case OP_MULTIPLY:
          case OP_DIVIDE:
            if(height < 2)
              /* We never had enough arguments, meaning any of the initial
               * ones for this op must have been of a kind we don't recognise
               * Abort and go to the next outer loop; we'll pick up an
               * optimizable inner sub-chain again later
               */
              goto next_o;

            opcount++;
            height--;
            if(height == 1) {
              final = scout;
              final_opcount = opcount;
            }
            break;

          default:
            if(!final)
              /* We never finished on an op that would give us a height of 1,
               * which means we probably took too many initial argument ops.
               * Abort now and go to the next outer loop; we'll pick up an
               * optimizable inner sub-chain again later
               */
              goto next_o;

            goto done_scout;
        }
      }
done_scout:
      ;
    }

    /* If we found fewer than 2 operations there's no point optimizing them */
    if(final_opcount < 2)
      goto next_o;

    /* At this point we now know that the sequence o to final consists of
     * optimizable ops yielding a single final scalar answer.
     */
    OP *newo = optimize_maths(o, final);

    newo->op_next = final->op_next;
    if(prevo)
      prevo->op_next = o = newo;
    else {
      /* we optimized starting at the very first op in this chain */
      o->op_targ = o->op_type;
      o->op_type = OP_NULL;
      o->op_next = newo;

      o = newo;
    }

next_o:
    if(!slowo)
      slowo = o;
    else if((slowotick++) % 2)
      slowo = slowo->op_next;

    prevo = o;
    o = o->op_next;
  }
}

static void (*next_rpeepp)(pTHX_ OP *o);

static void
my_rpeepp(pTHX_ OP *o)
{
  if(!o)
    return;

  (*next_rpeepp)(aTHX_ o);

  rpeep_for_fastermaths(aTHX_ o, FALSE);
}

MODULE = Faster::Maths    PACKAGE = Faster::Maths

BOOT:
  /* TODO: find the correct wrapper function for this */
  next_rpeepp = PL_rpeepp;
  PL_rpeepp = &my_rpeepp;

  XopENTRY_set(&xop_multimath, xop_name, "multimath");
  XopENTRY_set(&xop_multimath, xop_desc,
    "combined maths operations");
  XopENTRY_set(&xop_multimath, xop_class, OA_UNOP_AUX);
  Perl_custom_op_register(aTHX_ &pp_multimath, &xop_multimath);
