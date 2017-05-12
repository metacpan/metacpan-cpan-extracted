/*
 *  Example C source code to demonstrate Inline::Wrapper
 *
 *  Doesn't do much.  See the docs in examples/sample.pl to use it.
 *
 *  $Id: sample.c 5 2008-12-27 11:25:48Z infidel $
 */

#include <stdio.h>

void proverb( char *noun1, char *noun2 ) {
    printf( "Man's %s should exceed his %s.\n", noun1, noun2 );
}

int answer( int foo, int bar ) {
    return foo * 2 + bar;
}

/* END */
