#include <string.h>
#include "exprtype.h"

struct expr_parser;

/* Function types  */
typedef double (*func_t_dd) (double);
typedef double (*func_t_ddd) (double,double);
typedef struct exprval (*func_t_ee) (struct expr_parser* exprobj, struct exprval);

#define SYMREC(X) X, sizeof(X)-1

/* memory is allocated at compile time. it is also thread safe */
struct symrec_const
{
  char *name;  /* name of symbol */
  int len;     /* symbol length */
  int type;    /* type of symbol: either VAR or FNCT */
  double var;      /* value of a VAR */
  void* fnctptr;  /* value of a FNCT */
};

typedef struct symrec_const symrec_const;

/*
  Local Variables:
  mode: c
  End:
*/
