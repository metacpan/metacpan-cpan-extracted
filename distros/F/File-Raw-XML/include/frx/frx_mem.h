#ifndef FRX_MEM_H
#define FRX_MEM_H

/* What Windows costs, on its own so a perl-free translation unit can say
 * it too.
 *
 * Strawberry / Win32 Perl is built with PERL_IMPLICIT_SYS, which makes
 * iperlsys.h redefine malloc/free/realloc/calloc as function-like macros
 * routed through PerlMem_*. The arena and the output buffer manage their
 * own memory and hand none of it to Perl, and the harnesses under tools/
 * compile the same headers with no PerlMem at all, so every core header
 * sees plain libc symbols. (File::Raw::JSON found this the hard way:
 * "macro 'PerlMem_free' passed 2 arguments, but takes just 1".)
 *
 * frx_compat.h includes this after perl.h; tools/mingw/implicit_sys.c
 * includes it after defining the macros itself, and proves they are gone.
 * Include before <stdlib.h>. */
#undef malloc
#undef free
#undef realloc
#undef calloc

#endif /* FRX_MEM_H */
