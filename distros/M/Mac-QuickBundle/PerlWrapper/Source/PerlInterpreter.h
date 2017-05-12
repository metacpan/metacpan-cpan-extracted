/* PerlInterpreter.h: Embed a perl interpreter.
 * ------------------------------------------------------------------------
 * Defines a few helpful functions to embed a perl interpreter
 * ------------------------------------------------------------------------
 * $Id: PerlInterpreter.h 11 2004-10-17 22:19:26Z crenz $
 * Copyright (C) 2001, 2004 Christian Renz <crenz@web42.com>.
 * All rights reserved.
 */

/* Initialize perl interpreter */
void perl_init(int* argcp, char*** argvp, char*** envp);

/* Initialize ARGV */
void perl_init_argv(int argc, char **argv);

/* Destroy perl interpreter */
void perl_destroy();

/* Evaluate perl code */
void perl_exec(char *s);

/* Get a string from Perl */
char * perl_getstring(char *s);

/* eof *******************************************************************/
