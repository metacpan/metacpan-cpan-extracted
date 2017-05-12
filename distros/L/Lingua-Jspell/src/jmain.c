/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/**
 * @file
 * @brief Main file for jspell binary
 */

/** define we are in the main file */
/* #define MAIN */

/* jmain.c
 *
 * Copyright 1994-2009
 *   Ulisses Pinto 
 *   José João Almeida
 *   Alberto Simões
 */

#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"

#include "myterm.h"

/**
 * @brief Main jspell code
 *
 * @param argc number of arguments in the command line
 * @param argv array of the arguments passed in the command line
 */
int main(int argc, char *argv[])
{
    int nopts;
  
    if ((nopts = my_main(argc, argv, 0))) {
    
#ifndef NOCURSES
        initscr(); cbreak(); noecho();
        terminit();
#endif

        /* adavance options */
        while (nopts--) {
            argc--;
            argv++;
        }
    
        while (argc--) {
            dofile(*argv++);
        }

        done(0); /* end term as well */
        /* NOTREACHED */
    }
    return 0;
}
