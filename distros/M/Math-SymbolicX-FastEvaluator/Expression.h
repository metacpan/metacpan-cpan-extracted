#ifndef __Expression_h
#define __Expression_h

#include <vector>

/*
 Math::Symbolic 0.510:

use constant B_SUM            => 0;
use constant B_DIFFERENCE     => 1;
use constant B_PRODUCT        => 2;
use constant B_DIVISION       => 3;
use constant U_MINUS          => 4;
use constant U_P_DERIVATIVE   => 5;
use constant U_T_DERIVATIVE   => 6;
use constant B_EXP            => 7;
use constant B_LOG            => 8;
use constant U_SINE           => 9;
use constant U_COSINE         => 10;
use constant U_TANGENT        => 11;
use constant U_COTANGENT      => 12;
use constant U_ARCSINE        => 13;
use constant U_ARCCOSINE      => 14;
use constant U_ARCTANGENT     => 15;
use constant U_ARCCOTANGENT   => 16;
use constant U_SINE_H         => 17;
use constant U_COSINE_H       => 18;
use constant U_AREASINE_H     => 19;
use constant U_AREACOSINE_H   => 20;
use constant B_ARCTANGENT_TWO => 21;
*/

namespace FastEval {
  enum OpType {
    eNumber = 0,
    eVariable,
    B_SUM, /* this has an offset of two vs. the Math::Symbolic constant! */
    B_DIFFERENCE,
    B_PRODUCT,
    B_DIVISION,
    U_MINUS,
    U_P_DERIVATIVE,
    U_T_DERIVATIVE,
    B_EXP,
    B_LOG,
    U_SINE,
    U_COSINE,
    U_TANGENT,
    U_COTANGENT,
    U_ARCSINE,
    U_ARCCOSINE,
    U_ARCTANGENT,
    U_ARCCOTANGENT,
    U_SINE_H,
    U_COSINE_H,
    U_AREASINE_H,
    U_AREACOSINE_H,
    B_ARCTANGENT_TWO,
  };

  typedef struct {
    double content;
    unsigned char type; // OpType
  } op_t;

  class Expression {
    public:
      Expression();
      Expression(const unsigned int nvars, const unsigned int nops, op_t* ops);
      Expression(const unsigned int nvars, const std::vector<op_t>& ops);

      void AddOp(const op_t* op) {fOps.push_back(*op);}
      void SetNVars(const unsigned int nvars) {fNVars = nvars;}
      void SetOps(const unsigned int nops, const op_t* ops);
      void SetOps(const std::vector<op_t>& ops) {fOps = ops;}

      unsigned int GetNVars() const {return fNVars;}
      unsigned int GetNOps() const {return fOps.size();}
      const op_t* GetOps() const {return &fOps.front();}

      static unsigned char fgOpArity[];

    private:
      unsigned int fNVars;
      std::vector<op_t> fOps;
  };
} // end namespace FastEval

#endif
