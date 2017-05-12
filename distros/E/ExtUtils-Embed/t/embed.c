#include <EXTERN.h>
#include <perl.h>                

void xs_init _((void));

static PerlInterpreter *my_perl;

int main(int argc, char **argv, char **env)
{
  my_perl = perl_alloc();
  perl_construct(my_perl);
  
  perl_parse(my_perl, xs_init, argc, argv, NULL);
    
  perl_run(my_perl);
  perl_destruct(my_perl);
  perl_free(my_perl);
  exit(0);
}

