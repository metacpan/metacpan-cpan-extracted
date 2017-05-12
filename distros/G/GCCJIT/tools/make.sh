#!/bin/sh
# Helper to build using GCC installed under non-standard prefix.
GCC_ROOT="$1"
PERL_MM_OPT="$PERL_MM_OPT INC=-I$GCC_ROOT/include LIBS=\"-L$GCC_ROOT/lib -lgccjit\"" perl Makefile.PL
