/*
Adding a Perl interpreter to your C program 

In a sense, perl (the C program) is a good example of embedding Perl (the language), so I'll demonstrate embedding with
miniperlmain.c, from the source distribution. Here's a bastardized, non-portable version of miniperlmain.c containing the
essentials of embedding: 
*/

#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
static PerlInterpreter *my_perl;  /***    The Perl interpreter    ***/

int main(int argc, char **argv, char **env)
{
  my_perl = perl_alloc();
  perl_construct(my_perl);
  perl_parse(my_perl, NULL, argc, argv, (char **)NULL);
  perl_run(my_perl);
  perl_destruct(my_perl);
  perl_free(my_perl);
}



