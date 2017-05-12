#ifndef __Evaluator_h
#define __Evaluator_h

#include "Expression.h"
#include <stack>

namespace FastEval {
  class Evaluator {
    public:
      Evaluator();

      double Evaluate(const Expression * const expr, const double* values);

    private:
      void calcOp(std::stack<double>& st, const op_t* op);
  };

} // end namespace FastEval

#endif
