#include <string>
#include <iostream>
#include <cmath>

#include "Evaluator.h"

using namespace std;

namespace FastEval {

  Evaluator::Evaluator()
  {
  }

  double Evaluator::Evaluate(const Expression* const expr, const double* values) {
    stack<double> st;
      
    const unsigned int nOps = expr->GetNOps();
    const op_t* ops = expr->GetOps();
    const op_t* endOps = ops + nOps;
    
    for (op_t* iOp = (op_t*)ops; iOp != endOps; ++iOp) {
      switch (iOp->type) {
        case eNumber:
          st.push(iOp->content);
          break;
        case eVariable:
          st.push(values[(unsigned int)iOp->content]);
          break;
        default:
          calcOp(st, iOp);
          break;
      };
    }
    return st.top();
  }

  void Evaluator::calcOp(stack<double>& st, const op_t* op) {
    register double v1;
    register double v2;
    switch (Expression::fgOpArity[op->type]) {
      case 2:
        v2 = st.top();
        st.pop();
      case 1:
        v1 = st.top();
        st.pop();
        break;
      default:
        cerr << "BARF!" << endl;
        break;
    };

    switch (op->type) {
      case B_SUM:
        st.push(v1+v2); break;
      case B_DIFFERENCE:
        st.push(v1-v2); break;
      case B_PRODUCT:
        st.push(v1*v2); break;
      case B_DIVISION:
        st.push(v1/v2); break;
      case U_MINUS:
        st.push(-v1); break;
/* These are fatal!
 *    case U_P_DERIVATIVE
        break;
      case U_T_DERIVATIVE
        break;
*/

      case B_EXP:
        st.push(pow(v1, v2)); break;
      case B_LOG:
        st.push(log(v2)/log(v1)); break;
      case U_SINE:
        st.push(sin(v1)); break;
      case U_COSINE:
        st.push(cos(v1)); break;
      case U_TANGENT: // verify
        st.push(tan(v1)); break;
      case U_COTANGENT:
        st.push(cos(v1)/sin(v1)); break;
      case U_ARCSINE: // verify
        st.push(atan2( v1, sqrt(1.-v1*v1) )); break;
      case U_ARCCOSINE: // verify
        st.push(atan2( sqrt(1.-v1*v1), v1 )); break;
      case U_ARCTANGENT: // verify
        st.push(atan2(v1, 1.)); break;
      case U_ARCCOTANGENT: // verify
        st.push(atan2(1./v1, 1.)); break;
      case U_SINE_H: // verify
        st.push( 0.5 * (exp(v1) - exp(-v1)) ); break;
      case U_COSINE_H: // verify
        st.push( 0.5 * (exp(v1) + exp(-v1)) ); break;
      case U_AREASINE_H: // verify
        st.push( log( v1 + sqrt(v1*v1+1.) ) ); break;
      case U_AREACOSINE_H: // verify
        st.push( log( v1 + sqrt(v1*v1-1.) ) ); break;
      case B_ARCTANGENT_TWO: // verify
        st.push( atan2( v1, v2 ) ); break;

      default:
        cerr << "funny op" << endl;
        break;
    };
  }

} // end namespace FastEval

