#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif


#include "Expression.h"
#include "Evaluator.h"




MODULE = Math::SymbolicX::FastEvaluator		PACKAGE = Math::SymbolicX::FastEvaluator

FastEval::Evaluator *
FastEval::Evaluator::new()
 
void
FastEval::Evaluator::DESTROY()

double
FastEval::Evaluator::Evaluate(expr, ...)
  FastEval::Expression* expr
  PREINIT:
    SV* values=NULL;
    unsigned int pnum, nvars;
    bool isUndef = false;
    int i;
    double* cvalues;
    SV **item;
    AV* array;
  INIT:
    if( items > 2 )
      values = ST(2);
    else
      isUndef = true;

    if ( isUndef || !SvOK(values) )
      isUndef = true;
    else if ( !(SvRV(values) && SvTYPE(SvRV(values)) == SVt_PVAV) )
      croak("Reference to an array expected as second argument"); 

    nvars = expr->GetNVars();
    if ( nvars != 0 && isUndef )
      croak("No parameters (variable values) passed to Evaluate(expr, ...), but the expression contains variables!");
  CODE:
    if (isUndef)
      RETVAL = THIS->Evaluate(expr, NULL); /* kinda asking for trouble, ain't I */
    else {
      array = (AV*) SvRV(values);
      pnum = av_len(array)+1;
      if ( pnum != nvars )
        croak("Number of parameters passed to Evaluate(expr, ...) does not match the number of variables in the expressiom!");
      cvalues = (double*)safemalloc( pnum * sizeof( double ) );
      for (i = 0; i < pnum; ++i) {
        if ((item = av_fetch(array, i, 0)) && SvOK(*item))
          cvalues[i] = SvNV(*item);
        else {
          safefree((char*)cvalues);
          croak("Value not defined or not a double");
        }
      }
      RETVAL = THIS->Evaluate(expr, cvalues);
      safefree((char*)cvalues);
    }
  OUTPUT:
    RETVAL


MODULE = Math::SymbolicX::FastEvaluator		PACKAGE = Math::SymbolicX::FastEvaluator::Expression


FastEval::Expression*
FastEval::Expression::new()
 
void
FastEval::Expression::DESTROY()

void
FastEval::Expression::AddOp(op)
  FastEval::op_t* op
  CODE:
    THIS->AddOp(op);

void
FastEval::Expression::SetNVars(nvars)
  int nvars
  CODE:
    THIS->SetNVars((unsigned int)nvars);

unsigned int
FastEval::Expression::GetNVars()
  CODE:
    RETVAL = THIS->GetNVars();
  OUTPUT:
    RETVAL

 #    void SetOps(const unsigned int nops, const op_t* ops);
 #    void SetOps(const std::vector<op_t>& ops) {fOps = ops;}

 #    unsigned int GetNOps() const {return fOps.size();}
 #    const op_t* GetOps() const {return &fOps.front();}

double
FastEval::Expression::Evaluate(...)
  PREINIT:
    /* FIXME this whole mess is a duplication of the Evaluator::Evaluate method. Not good */
    SV* values=NULL;
    unsigned int pnum, nvars;
    bool isUndef = false;
    int i;
    double* cvalues;
    SV **item;
    AV* array;
    FastEval::Evaluator eval;
  INIT:
    if( items > 1 )
      values = ST(1);
    else
      isUndef = true;

    if ( isUndef || !SvOK(values) )
      isUndef = true;
    else if ( !(SvRV(values) && SvTYPE(SvRV(values)) == SVt_PVAV) )
      croak("Reference to an array expected as argument to Evaluate"); 

    nvars = THIS->GetNVars();
    if ( nvars != 0 && isUndef )
      croak("No parameters (variable values) passed to Evaluate(...), but the expression contains variables!");
  CODE:
    if (isUndef)
      RETVAL = eval.Evaluate(THIS, NULL); /* kinda asking for trouble, ain't I */
    else {
      array = (AV*) SvRV(values);
      pnum = av_len(array)+1;
      if ( pnum != nvars )
        croak("Number of parameters passed to Evaluate(...) does not match the number of variables in the expressiom!");
      cvalues = (double*)safemalloc( pnum * sizeof( double ) );
      for (i = 0; i < pnum; ++i) {
        if ((item = av_fetch(array, i, 0)) && SvOK(*item))
          cvalues[i] = SvNV(*item);
        else {
          safefree((char*)cvalues);
          croak("Value not defined or not a double");
        }
      }
      RETVAL = eval.Evaluate(THIS, cvalues);
      safefree((char*)cvalues);
    }
  OUTPUT:
    RETVAL


MODULE = Math::SymbolicX::FastEvaluator		PACKAGE = Math::SymbolicX::FastEvaluator::Op

FastEval::op_t *
new(CLASS)
  char *CLASS
  CODE:
    RETVAL = (FastEval::op_t*)safemalloc( sizeof( FastEval::op_t) );
    if( RETVAL == NULL ){
      warn("unable to allocate FastEval::op_t");
      XSRETURN_UNDEF;
    }
  OUTPUT:
    RETVAL

void
DESTROY(self)
  FastEval::op_t* self
  CODE:
    safefree( (char*)self );


void
SetValue(op,val)
  FastEval::op_t *op
  double val
  CODE:
    op->content = val;
    

void
SetOpType(op,type)
  FastEval::op_t *op
  unsigned char type
  CODE:
    op->type = type+2; /* +2 since Math::Symbolic doesn't have the number and var enums */
    
void
SetVariable(op)
  FastEval::op_t *op
  CODE:
    op->type = FastEval::eVariable;
    
    
void
SetNumber(op)
  FastEval::op_t *op
  CODE:
    op->type = FastEval::eNumber;


