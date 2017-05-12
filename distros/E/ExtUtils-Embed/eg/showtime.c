/*
Calling a Perl subroutine from your C program 

*/

#include <EXTERN.h>
#include <perl.h>

static PerlInterpreter *my_perl;

int main(int argc, char **argv, char **env)
{
  char *args[] = { NULL };
  my_perl = perl_alloc();
  perl_construct(my_perl);
  perl_parse(my_perl, NULL, argc, argv, NULL);

  /*** skipping perl_run() ***/

  perl_call_argv("showtime", G_DISCARD | G_NOARGS, args);

  perl_destruct(my_perl);
  perl_free(my_perl);
}
