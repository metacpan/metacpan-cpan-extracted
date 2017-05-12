#include "Expression.h"

namespace FastEval {

  unsigned char Expression::fgOpArity[] = {
    0, // eNumber
    0, // eVariable
    2, // B_SUM, /* this has an offset of two vs. the Math::Symbolic constant! */
    2, // B_DIFFERENCE,
    2, // B_PRODUCT,
    2, // B_DIVISION,
    1, // U_MINUS,
    1, // U_P_DERIVATIVE,
    1, // U_T_DERIVATIVE,
    2, // B_EXP,
    2, // B_LOG,
    1, // U_SINE,
    1, // U_COSINE,
    1, // U_TANGENT,
    1, // U_COTANGENT,
    1, // U_ARCSINE,
    1, // U_ARCCOSINE,
    1, // U_ARCTANGENT,
    1, // U_ARCCOTANGENT,
    1, // U_SINE_H,
    1, // U_COSINE_H,
    1, // U_AREASINE_H,
    1, // U_AREACOSINE_H,
    2, // B_ARCTANGENT_TWO,
  };

  Expression::Expression() :
    fNVars(0)
  {
  }

  Expression::Expression(const unsigned int nvars, const std::vector<op_t>& ops) :
    fNVars(nvars),
    fOps(ops)
  {
  }

  Expression::Expression(const unsigned int nvars, const unsigned int nops, op_t* ops) :
    fNVars(nvars)
  {
    fOps.resize(nops);
    for (unsigned int i = 0; i < nops; i++)
      fOps[i] = ops[i];
  }

  void Expression::SetOps(const unsigned int nops, const op_t* ops) {
    fOps.resize(nops);
    for (unsigned int i = 0; i < nops; i++) {
      fOps[i] = ops[i];
    }
  }

} // end namespace

