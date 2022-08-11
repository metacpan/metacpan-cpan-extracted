/* This file is used after regeneration of libmarpa from the 'tested' branch: */
/*
  pushd ~/git/libmarpa_orig
  make clean dist
  #
  # We copy the generated *.c and *.h files except config.h
  #
  cp work/stage/*.[ch] ~/git/c-marpaWrapper/libmarpa/work/stage
  rm ~/git/c-marpaWrapper/libmarpa/work/stage/config.h
  #
  # We copy also marpa.w and marpa_ami.w to give a change to debugger ou kcachegrind to find the source
  #
  cp work/dev/marpa.w work/ami/marpa_ami.w ~/git/c-marpaWrapper/libmarpa/work/stage
  popd
*/

#ifndef MARPA_LINKAGE
#  define MARPA_LINKAGE static
#endif
#ifndef MARPA_AVL_LINKAGE
#  define MARPA_AVL_LINKAGE static
#endif
#ifndef MARPA_TAVL_LINKAGE
#  define MARPA_TAVL_LINKAGE static
#endif
#ifndef MARPA_OBS_LINKAGE
#  define MARPA_OBS_LINKAGE static
#endif

#include "../libmarpa/work/stage/marpa_ami.c"
#include "../libmarpa/work/stage/marpa_avl.c"
#include "../libmarpa/work/stage/marpa.c"
#include "../libmarpa/work/stage/marpa_codes.c"
#include "../libmarpa/work/stage/marpa_obs.c"
#include "../libmarpa/work/stage/marpa_tavl.c"
#include "../src/asf.c"
#include "../src/grammar.c"
#include "../src/recognizer.c"
#include "../src/value.c"
