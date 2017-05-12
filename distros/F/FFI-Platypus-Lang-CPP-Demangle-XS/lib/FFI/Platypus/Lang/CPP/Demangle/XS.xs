#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ffi_pl_lang_cpp_demangle.h"

MODULE = FFI::Platypus::Lang::CPP::Demangle::XS   PACKAGE = FFI::Platypus::Lang::CPP::Demangle::XS

void
demangle(c_symbol)
    SV *c_symbol
  PREINIT:
    const char *demangled;
  CODE:
    if(!SvOK(c_symbol))
    {
      ffi_pl_lang_cpp_demangle(NULL);
      XSRETURN_EMPTY;
    }
  
    demangled = ffi_pl_lang_cpp_demangle((const char *)SvPV_nolen(c_symbol));
    
    if(demangled == NULL)
    {
      switch(ffi_pl_lang_cpp_demangle_status)
      {
        case 0:
          croak("oops shouldn't get here");
          break;
        case -1:
          croak("C++ ABI API memory allocation failure\n");
          break;
        case -2:
          XSRETURN_EMPTY;
          break;
        case -3:
          croak("C++ ABI API invalid arguments\n");
          break;
        default:
          croak("C++ ABI API unknown error\n");
          break;
      }
    }
    
    XSRETURN_PV(demangled);
