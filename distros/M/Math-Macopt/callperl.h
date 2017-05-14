/*
 *  This is a test program for PGAPack.  The objective is to maximize the
 *  number of 1-bits in a chromosome.
*/
// #define PERLIO_NOT_STDIO 0 

#include <EXTERN.h>
#include <perl.h>

// Will SIGSEV if XSUB.h not used, need further investigation
#include <XSUB.h>

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <time.h>

/*******************************************************************
*           Static variable to hold the embedded perl              *
*******************************************************************/
extern PerlInterpreter *my_perl;

/*******************************************************************
*           function to interact with embedded perl                *
*                                                                  *
*   Arguments:                                                     *
*   sub - name of the perl subrountine to be invoked               *
*   AV* - list of args to be passed to the perl routine            *
*                                                                  *
*   Returns:                                                       *
*   AV* - list of return values form the perl routine              *
*******************************************************************/
AV* interactPerl(SV* callback, AV* args);
