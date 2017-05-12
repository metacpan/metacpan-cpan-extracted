#include <string.h>
#include <errno.h>
#include "EXTERN.h"
#include "perl.h"
#include "perl_error.hh"

namespace perl_error 
{
  void error (const char * msg) 
  {
    char * err = strerror(errno);
    warn ("%s: %s\n", msg, err);
  }
  
}
