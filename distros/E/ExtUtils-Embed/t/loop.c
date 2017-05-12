#include <EXTERN.h>
#include <perl.h>

void xs_init _((void));

int main(int argc, char **argv, char **env)
{
    PerlInterpreter *perl;
    int i;

    perl_destruct_level = 1;

    for(i=1; i<=10; i++) {
	perl = perl_alloc();
	perl_construct(perl);
	perl_parse(perl, xs_init, argc, argv, (char **)NULL);
	perl_run(perl); 
	perl_destruct(perl); 
	perl_free(perl); 
    }
    return 1;
}



