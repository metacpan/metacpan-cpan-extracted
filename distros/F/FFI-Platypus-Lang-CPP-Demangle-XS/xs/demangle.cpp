#include <stdlib.h>
#include <cxxabi.h>
#include "ffi_pl_lang_cpp_demangle.h"

int
ffi_pl_lang_cpp_demangle_status;

extern "C" const char *
ffi_pl_lang_cpp_demangle(const char *c_symbol)
{
  static char   *buffer = NULL;
  static size_t size    = 0;

  if(c_symbol == NULL)
  {
    if(buffer != NULL)
      free(buffer);
    return NULL;
  }

  ffi_pl_lang_cpp_demangle_status = 0;
  buffer = abi::__cxa_demangle(c_symbol, buffer, &size, &ffi_pl_lang_cpp_demangle_status);

  if(ffi_pl_lang_cpp_demangle_status == 0)
  {
    return buffer;
  }
  else
  {
    return NULL;
  }
}

