%module "Math::GSL::BSpline"
%include "typemaps.i"
%include "gsl_typemaps.i"
%include "renames.i"

#define  GSL_DISABLE_DEPRECATED 1

%include "gsl/gsl_math.h"
%include "gsl/gsl_vector.h"
#if MG_GSL_NUM_VERSION >= 2008
   %include "gsl/gsl_bspline.h"
#else
    %include "legacy/gsl-2.7/gsl_bspline.h"
#endif

%include "../pod/BSpline.pod"

%{
    #include "gsl/gsl_math.h"
    #include "gsl/gsl_vector.h"
    #include "gsl/gsl_bspline.h"
%}


