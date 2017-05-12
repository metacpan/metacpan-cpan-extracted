#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


MODULE = Sys::CpuAffinity        PACKAGE = Sys::CpuAffinity

int
xs_fortytwo()
  CODE:
    /* The purpose of this trivial code snippet is to
       see whether you can compile something, anything,
       during this build process.

       If this doesn't compile, then you probably don't have
       a compiler or it is badly misconfigured, and you
       won't be able to generate any XS code with this
       distribution.

       If this is the ONLY thing that compiles, then your
       system-specific snippets might be incorrect, or your
       system might be obscure enough that no system-specific
       snippets have been developed for it yet. */
    RETVAL = 42;
  OUTPUT:
    RETVAL




