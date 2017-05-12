
#include <iostream>
#include <string>
#include <cstdlib>

#include "Expression.h"
#include "Evaluator.h"

using namespace FastEval;
using namespace std;

int main(int argc, char** argv) {
  unsigned int n = argc > 1 ? (unsigned int)atoi(argv[1]) : 10;
  if (!(n%2))
    n++;

  op_t* ops;
  ops = (op_t*) malloc(n * sizeof(op_t));
  ops[0].type = eNumber;
  ops[0].content= 1.0;
  for (unsigned int i = 1; i < n; i+=2) {
    ops[i].type = eNumber;
    ops[i].content = 2.0;
    ops[i+1].type = B_PRODUCT;
  }

  Expression e(0,n,ops);
  Evaluator ev;
  const double res = ev.Evaluate(&e, NULL);
  cout << res << endl;

  return 0;
}

