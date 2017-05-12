%pure-parser
%lex-param {struct tmplpro_state* state}
%lex-param {struct expr_parser* exprobj}
%parse-param {struct tmplpro_state* state}
%parse-param {struct expr_parser* exprobj}
%parse-param {PSTRING* expr_retval_ptr}
%{
#include <math.h>  /* For math functions, cos(), sin(), etc.  */
#include <stdio.h> /* for printf */
#include <stdlib.h> /* for malloc */
#include <ctype.h> /* for yylex alnum */
#include "calc.h"  /* Contains definition of `symrec'.  */
#include "tmpllog.h"
#include "pabstract.h"
#include "prostate.h"
#include "provalue.h"
#include "pparam.h"
#include "pmiscdef.h"
/* for expr-specific only */
#include "exprtool.h"
#include "exprpstr.h"
#include "parse_expr.h"
  /* Remember unsigned char assert on win32
Debug Assertion Failed! f:\dd\vctools\crt_bld\self_x86\crt\src \isctype.c Expression:(unsigned)(c + 1) <= 256 
   */
  %}
%union {
  struct exprval numval;   /* For returning numbers.  */
  const symrec_const  *tptr;   /* For returning symbol-table pointers.  */
  struct user_func_call extfunc;  /* for user-defined function name */
  PSTRING uservar;
}
%{
  /* the second section is required as we use YYSTYPE here */
  static void yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *);
  static int yylex (YYSTYPE *lvalp, struct tmplpro_state* state, struct expr_parser* exprobj);
%}
%start line
%token <numval>  NUM        /*  poly type.  */
%token <extfunc> EXTFUNC    /* user-defined function */
%token <tptr> BUILTIN_VAR	    /* built-in Variable  */
%token <tptr> BUILTIN_FNC_DD /* built-in D Function (D).  */
%token <tptr> BUILTIN_FNC_DDD /* built-in D Function (D,D).  */
%token <tptr> BUILTIN_FNC_EE /* built-in E Function (E).  */
%token <uservar> VAR    /* user-supplied variable.  */
%type  <numval>  numEXP
%type  <extfunc> arglist

/*%right '='*/
%left OR
%left AND
%nonassoc strGT strGE strLT strLE strEQ strNE strCMP
%nonassoc numGT numGE numLT numLE numEQ numNE '<' '>'
%nonassoc reLIKE reNOTLIKE
%left '-' '+'
%left '*' '/' '%'
%left  '!' NOT NEG /* negation--unary minus */
%right '^'    /* exponentiation */
%% /* The grammar follows.  */

line: numEXP		
		 { 
		   expr_to_str1(state, &$1);
		   *expr_retval_ptr=$1.val.strval;
		 }
;
/* | error { yyerrok;                  } */

numEXP: NUM			{ $$ = $1;			}
| BUILTIN_VAR			{ $$.type=EXPR_TYPE_DBL; $$.val.dblval = $1->var; }
/*| BUILTIN_VAR '=' numEXP 		{ $$ = $3; $1->value.var = $3;	} */
| VAR		{
		  PSTRING varvalue=_get_variable_value(state->param, $1);
		  if (varvalue.begin==NULL) {
		    int loglevel = state->param->warn_unused ? TMPL_LOG_ERROR : TMPL_LOG_INFO;
		    log_expr(exprobj,loglevel, "non-initialized variable %.*s\n",(int)($1.endnext-$1.begin),$1.begin);
		  }
		  $$.type=EXPR_TYPE_PSTR;
		  $$.val.strval=varvalue;
  }
| arglist ')'
                 {
		   $$ = call_expr_userfunc(exprobj, state->param, $1);
		 }
| EXTFUNC '(' ')'
                 {
		   $1.arglist=state->param->InitExprArglistFuncPtr(state->param->ext_calluserfunc_state);
		   $$ = call_expr_userfunc(exprobj, state->param, $1);
		 }
| BUILTIN_FNC_EE '(' ')'
                 {
		   struct exprval e = NEW_EXPRVAL(EXPR_TYPE_PSTR);
		   e.val.strval.begin = NULL;
		   e.val.strval.endnext = NULL;
		   $$ = (*((func_t_ee)$1->fnctptr))(exprobj, e);
		 }
| BUILTIN_FNC_DD '(' numEXP ')'	
                 {
		   $$.type=EXPR_TYPE_DBL;
		   expr_to_dbl1(exprobj, &$3);
		   $$.val.dblval = (*((func_t_dd)$1->fnctptr))($3.val.dblval); 
		 }
| BUILTIN_FNC_DDD '(' numEXP ',' numEXP ')'
                 {
		   $$.type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &$3, &$5);
		   $$.val.dblval = (*((func_t_ddd)$1->fnctptr))($3.val.dblval,$5.val.dblval);
		 }
| BUILTIN_FNC_EE '(' numEXP ')'
                 {
		   $$ = (*((func_t_ee)$1->fnctptr))(exprobj,$3);
		 }
| numEXP '+' numEXP		{ DO_MATHOP(exprobj, $$,+,$1,$3);	}
| numEXP '-' numEXP		{ DO_MATHOP(exprobj, $$,-,$1,$3);	}
| numEXP '*' numEXP		{ DO_MATHOP(exprobj, $$,*,$1,$3);	}
| numEXP '%' numEXP
		 { 
		   $$.type=EXPR_TYPE_INT;
		   expr_to_int(exprobj, &$1,&$3);
		   $$.val.intval = $1.val.intval % $3.val.intval;
		 }
/* old division; now always return double (due to compains 1/3==0)
| numEXP '/' numEXP
                 {
		   switch ($$.type=expr_to_int_or_dbl(&$1,&$3)) {
		   case EXPR_TYPE_INT: 
                   if ($3.val.intval)
                     $$.val.intval = $1.val.intval / $3.val.intval;
                   else
                     {
                       $$.val.intval = 0;
		       log_expr(exprobj, TMPL_LOG_ERROR, "%s\n", "division by zero");
                     }
		   ;break;
		   case EXPR_TYPE_DBL: 
                   if ($3.val.dblval)
                     $$.val.dblval = $1.val.dblval / $3.val.dblval;
                   else
                     {
                       $$.val.dblval = 0;
		       log_expr(exprobj, TMPL_LOG_ERROR, "%s\n", "division by zero");
                     }
		   }
		   ;break;
		 }
*/
| numEXP '/' numEXP
                 {
		   $$.type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &$1,&$3);
                   if ($3.val.dblval)
                     $$.val.dblval = $1.val.dblval / $3.val.dblval;
                   else
                     {
                       $$.val.dblval = 0;
		       log_expr(exprobj, TMPL_LOG_ERROR, "%s\n", "division by zero");
                     }
		 }
| '-' numEXP  %prec NEG
		 { 
		   switch ($$.type=$2.type) {
		   case EXPR_TYPE_INT: 
		     $$.val.intval = -$2.val.intval;
		   ;break;
		   case EXPR_TYPE_DBL: 
		     $$.val.dblval = -$2.val.dblval;
		   ;break;
		   }
		 }
| numEXP '^' numEXP 		
                 { 
		   $$.type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &$1,&$3);
		   $$.val.dblval = pow ($1.val.dblval, $3.val.dblval);
                 }
| numEXP OR numEXP
 		 {
		   if (exprobj->is_tt_like_logical) {
		     $$=$1;
		     switch (expr_to_int_or_dbl_logop1(exprobj, &$$)) {
		     case EXPR_TYPE_INT: $$= ($1.val.intval ? $1 : $3); break;
		     case EXPR_TYPE_DBL: $$= ($1.val.dblval ? $1 : $3); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, $$,||,$1,$3);
		   }
		 }
| numEXP AND numEXP
 		 {
		   if (exprobj->is_tt_like_logical) {
		     $$=$1;
		     switch (expr_to_int_or_dbl_logop1(exprobj, &$$)) {
		     case EXPR_TYPE_INT: $$= ($1.val.intval ? $3 : $1); break;
		     case EXPR_TYPE_DBL: $$= ($1.val.dblval ? $3 : $1); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, $$,&&,$1,$3);
		   }
		 }
| numEXP numGE numEXP 		{ DO_CMPOP(exprobj, $$,>=,$1,$3);	}
| numEXP numLE numEXP 		{ DO_CMPOP(exprobj, $$,<=,$1,$3);	}
| numEXP numNE numEXP 		{ DO_CMPOP(exprobj, $$,!=,$1,$3);	}
| numEXP numEQ numEXP 		{ DO_CMPOP(exprobj, $$,==,$1,$3);	}
| numEXP '>' numEXP %prec numGT	{ DO_CMPOP(exprobj, $$,>,$1,$3);	}
| numEXP '<' numEXP %prec numLT	{ DO_CMPOP(exprobj, $$,<,$1,$3);	}
| '!' numEXP  %prec NOT		{ DO_LOGOP1(exprobj, $$,!,$2);		}
| NOT numEXP			{ DO_LOGOP1(exprobj, $$,!,$2);		}
| '(' numEXP ')'		{ $$ = $2;			}
| numEXP strCMP numEXP 		{ 
  expr_to_str(state, &$1,&$3); 
  $$.type=EXPR_TYPE_INT; $$.val.intval = pstring_ge ($1.val.strval,$3.val.strval)-pstring_le ($1.val.strval,$3.val.strval);
}
| numEXP strGE numEXP 		{ DO_TXTOP($$,pstring_ge,$1,$3,state);}
| numEXP strLE numEXP 		{ DO_TXTOP($$,pstring_le,$1,$3,state);}
| numEXP strNE numEXP 		{ DO_TXTOP($$,pstring_ne,$1,$3,state);}
| numEXP strEQ numEXP 		{ DO_TXTOP($$,pstring_eq,$1,$3,state);}
| numEXP strGT numEXP		{ DO_TXTOP($$,pstring_gt,$1,$3,state);}
| numEXP strLT numEXP		{ DO_TXTOP($$,pstring_lt,$1,$3,state);}
| numEXP reLIKE numEXP		{ DO_TXTOPLOG($$,re_like,$1,$3,exprobj);}
| numEXP reNOTLIKE numEXP	{ DO_TXTOPLOG($$,re_notlike,$1,$3,exprobj);}
;

arglist: EXTFUNC '(' numEXP 	 	{
  $1.arglist=state->param->InitExprArglistFuncPtr(state->param->expr_func_map);
  pusharg_expr_userfunc(exprobj,state->param,$1,$3);
  $$ = $1;
}
| arglist ',' numEXP	 { pusharg_expr_userfunc(exprobj,state->param,$1,$3); $$ = $1;	}
;

/* End of grammar.  */
%%

/* Called by yyparse on error.  */
static void
yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *s)
{
  log_expr(exprobj, TMPL_LOG_ERROR, "not a valid expression: %s\n", s);
}

#include "calc.inc"

static
const symrec_const
#ifndef __cplusplus
const 
#endif
builtin_funcs_symrec[] =
  {
    /* built-in funcs */
    {SYMREC("sin"), BUILTIN_FNC_DD,	0,	  sin},
    {SYMREC("cos"), BUILTIN_FNC_DD,	0,	  cos},
    {SYMREC("atan"), BUILTIN_FNC_DD,	0,	 atan},
    {SYMREC("log"), BUILTIN_FNC_DD,	0,	  log},
    {SYMREC("exp"), BUILTIN_FNC_DD,	0,	  exp},
    {SYMREC("sqrt"), BUILTIN_FNC_DD,	0,	 sqrt},
    {SYMREC("atan2"), BUILTIN_FNC_DDD,	0,	atan2},
    {SYMREC("abs"), BUILTIN_FNC_EE,	0,	builtin_abs},
    {SYMREC("defined"), BUILTIN_FNC_EE,	0,	builtin_defined},
    {SYMREC("int"), BUILTIN_FNC_EE,	0,	builtin_int},
    {SYMREC("hex"), BUILTIN_FNC_EE,	0,	builtin_hex},
    {SYMREC("length"), BUILTIN_FNC_EE,	0,	builtin_length},
    {SYMREC("oct"), BUILTIN_FNC_EE,	0,	builtin_oct},
    {SYMREC("rand"), BUILTIN_FNC_EE,	0,	builtin_rand},
    {SYMREC("srand"), BUILTIN_FNC_EE,	0,	builtin_srand},
    {SYMREC("version"), BUILTIN_FNC_EE,	0,	builtin_version},
    /* end mark */
    {0, 0, 0}
  };

static
const symrec_const
#ifndef __cplusplus
const 
#endif
builtin_ops_symrec[] =
  {
    /* built-in ops */
    {SYMREC("eq"),  strEQ,	0,	NULL},
    {SYMREC("ne"),  strNE,	0,	NULL},
    {SYMREC("gt"),  strGT,	0,	NULL},
    {SYMREC("ge"),  strGE,	0,	NULL},
    {SYMREC("lt"),  strLT,	0,	NULL},
    {SYMREC("le"),  strLE,	0,	NULL},
    {SYMREC("cmp"), strCMP,	0,	NULL},
    {SYMREC("or"),  OR,	0,	NULL},
    {SYMREC("and"),AND,	0,	NULL},
    {SYMREC("not"),NOT,	0,	NULL},
    /* end mark */
    {0, 0, 0}
  };

TMPLPRO_LOCAL
PSTRING 
parse_expr(PSTRING expression, struct tmplpro_state* state)
{
  PSTRING expr_retval;
  struct expr_parser exprobj;
  expr_retval.begin=expression.begin;
  expr_retval.endnext=expression.begin;
  exprobj.expr_curpos=expression.begin;
  exprobj.exprarea=expression;
  exprobj.state = state;
  exprobj.is_expect_quote_like=1;
  // TODO!!
  exprobj.is_tt_like_logical=0;
  yyparse (state, &exprobj, &expr_retval);
  if (NULL!=expr_retval.begin && NULL==expr_retval.endnext) log_expr(&exprobj, TMPL_LOG_ERROR, "parse_expr internal warning: %s\n", "endnext is null pointer");
  return expr_retval;
}

static
void 
log_expr(struct expr_parser* exprobj, int loglevel, const char* fmt, ...)
{
  va_list vl;
  va_start(vl, fmt);
  log_state(exprobj->state, loglevel, "in EXPR:at pos " MOD_TD " [" MOD_TD "]: ", 
	   TO_PTRDIFF_T((exprobj->expr_curpos)-(exprobj->state->top)),
	   TO_PTRDIFF_T((exprobj->expr_curpos)-(exprobj->exprarea).begin));
  tmpl_vlog(loglevel, fmt, vl);
  va_end(vl);
}

static
PSTRING 
fill_symbuf (struct expr_parser* exprobj, int is_accepted(unsigned char)) {
  /* skip first char, already tested */
  PSTRING retval = {exprobj->expr_curpos++};
  while (exprobj->expr_curpos < (exprobj->exprarea).endnext && is_accepted(*exprobj->expr_curpos)) exprobj->expr_curpos++;
  retval.endnext= exprobj->expr_curpos;
  return retval;
}

static 
int 
is_alnum_lex (unsigned char c)
{
  return (c == '_' || isalnum (c));
}

static 
int 
is_not_identifier_ext_end (unsigned char c)
{ 
  return (c != '}');
} 

#define TESTOP(c1,c2,z)  if (c1 == c) { char d=*++(exprobj->expr_curpos); if (c2 != d) return c; else (exprobj->expr_curpos)++; return z; }
#define TESTOP3(c1,c2,c3,num2,str3)  if (c1 == c) { char d=*++(exprobj->expr_curpos); if (c2 == d) {(exprobj->expr_curpos)++; return num2;} else if (c3 == d) {(exprobj->expr_curpos)++; exprobj->is_expect_quote_like=1; return str3;} else return c; }

static 
int
yylex (YYSTYPE *lvalp, struct tmplpro_state* state, struct expr_parser* exprobj)
{
  register unsigned char c = 0;
  int is_identifier_ext; 
  /* TODO: newline? */
  /* Ignore white space, get first nonwhite character.  */
  while ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && ((c = *(exprobj->expr_curpos)) == ' ' || c == '\t')) (exprobj->expr_curpos)++;
  if ((exprobj->expr_curpos)>=(exprobj->exprarea).endnext) return 0;

  /* Char starts a quote => read a string */
  if ('\''==c || '"'==c || (exprobj->is_expect_quote_like && '/'==c) ) {
    PSTRING strvalue;
    unsigned char terminal_quote=c;
    int escape_flag = 0;
    c =* ++(exprobj->expr_curpos);
    strvalue.begin = exprobj->expr_curpos;
    strvalue.endnext = exprobj->expr_curpos;

    while ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && c != terminal_quote) {
      /* any escaped char with \ , incl. quote */
      if ('\\' == c) {
	escape_flag = 1;
	exprobj->expr_curpos+=2;
	c =*(exprobj->expr_curpos);
      } else {
	c = * ++(exprobj->expr_curpos);
      }
    }

    strvalue.endnext = exprobj->expr_curpos;
    if ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && ((c = *(exprobj->expr_curpos)) == terminal_quote)) (exprobj->expr_curpos)++;
    if (escape_flag) {
      (*lvalp).numval.type=EXPR_TYPE_UPSTR;
    } else {
      (*lvalp).numval.type=EXPR_TYPE_PSTR;
    }
    (*lvalp).numval.val.strval=strvalue;
    exprobj->is_expect_quote_like=0;
    return NUM;
  }
	
  exprobj->is_expect_quote_like=0;
  /* Char starts a number => parse the number.         */
  if (c == '.' || isdigit (c))
    {
      (*lvalp).numval=exp_read_number (exprobj, &(exprobj->expr_curpos), (exprobj->exprarea).endnext);
      return NUM;
    }

  /* 
   * Emiliano Bruni extension to Expr:
   * original HTML::Template allows almost arbitrary chars in parameter names,
   * but original HTML::Template::Expr (as to 0.04) allows only
   * var to be m![A-Za-z_][A-Za-z0-9_]*!.
   * with this extension, arbitrary chars can be used 
   * if bracketed in ${}, as, for example, EXPR="${foo.bar} eq 'a'".
   * first it was bracketing in {}, but it is changed 
   *
   * COMPATIBILITY WARNING.
   * Currently, this extension is not present in HTML::Template::Expr (as of 0.04).
   */
  /* Let's try to see if this is an identifier between two { } - Emiliano */
  is_identifier_ext = (int) (c == '{' || c == '$');

  /* Char starts an identifier => read the name.       */
  /* variables with _leading_underscore are allowed too */
  if (isalpha (c) || c=='_' || is_identifier_ext) {
    const symrec_const *s;
    PSTRING name;
    if (is_identifier_ext) {
      (exprobj->expr_curpos)++; /* jump over $ or { */
      if ('$' == c && '{' == *(exprobj->expr_curpos)) {
	(exprobj->expr_curpos)++; /* jump over { */
#ifndef ALLOW_OLD_BRACKETING_IN_EXPR
      } else {
      	log_expr(exprobj, TMPL_LOG_ERROR, "{} bracketing is deprecated. Use ${} bracketing.\n");
#endif
      }
      name=fill_symbuf(exprobj, is_not_identifier_ext_end);
      if ((exprobj->expr_curpos)<(exprobj->exprarea).endnext) (exprobj->expr_curpos)++; /* Jump the last } - Emiliano */
    } else {
      name=fill_symbuf(exprobj, is_alnum_lex);
    }
    s = getsym (builtin_ops_symrec, name);
    if (s != 0) {
      (*lvalp).tptr = s;
      return s->type;
    }

    {
      const char* next_char= exprobj->expr_curpos;
      /* optimization: funcs is always followed by ( */
      while ((next_char<(exprobj->exprarea).endnext) && isspace(*next_char)) next_char++;
      if ((*next_char)=='(') {
	/* user-defined functions have precedence over buit-in */
	if (((*lvalp).extfunc.func=(state->param->IsExprUserfncFuncPtr)(state->param->expr_func_map, name))) {
	  return EXTFUNC;
	}
	s = getsym (builtin_funcs_symrec, name);
	if (s != 0) {
	  (*lvalp).tptr = s;
	  return s->type;
	}
      }
      (*lvalp).uservar=name;
      /*log_expr(exprobj,TMPL_LOG_DEBUG2, "yylex: returned variable name %.*s\n",(int)(name.endnext-name.begin),name.begin);*/
      return VAR;
    }
  }

  TESTOP3('=','=','~',numEQ,reLIKE)
  TESTOP3('!','=','~',numNE,reNOTLIKE)
  TESTOP('>','=',numGE)
  TESTOP('<','=',numLE)
  TESTOP('&','&',AND)
  TESTOP('|','|',OR)

  /* Any other character is a token by itself. */
  (exprobj->expr_curpos)++;
  return c;
}

static
struct exprval
call_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call USERFUNC) {
  struct exprval emptyval = {EXPR_TYPE_PSTR};
  emptyval.val.strval.begin=NULL;
  emptyval.val.strval.endnext=NULL;
  exprobj->userfunc_call = emptyval;
  param->CallExprUserfncFuncPtr(param->ext_calluserfunc_state, USERFUNC.arglist, USERFUNC.func, &(exprobj->userfunc_call));
  if (param->debug>6) _tmplpro_expnum_debug (exprobj->userfunc_call, "EXPR: function call: returned ");
  param->FreeExprArglistFuncPtr(USERFUNC.arglist);
  USERFUNC.arglist = NULL;
  /* never happen; tmplpro_set_expr_as_* never set EXPR_TYPE_NULL *
   * if (exprobj->userfunc_call.type == EXPR_TYPE_NULL) exprobj->userfunc_call.type = EXPR_TYPE_PSTR;  */
  return exprobj->userfunc_call;
}

static
void
pusharg_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call USERFUNC, struct exprval arg) {
  if (arg.type == EXPR_TYPE_UPSTR) {
    arg.val.strval=expr_unescape_pstring_val(&(exprobj->state->expr_left_pbuffer),arg.val.strval);
    arg.type=EXPR_TYPE_PSTR;
  }
  exprobj->userfunc_call = arg;
  param->PushExprArglistFuncPtr(USERFUNC.arglist,&(exprobj->userfunc_call));
  if (param->debug>6) _tmplpro_expnum_debug (arg, "EXPR: arglist: pushed ");
}

#include "exprtool.inc"
#include "exprpstr.inc"
