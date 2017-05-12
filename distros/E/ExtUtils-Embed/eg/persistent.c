#include <EXTERN.h> 
#include <perl.h> 

/* 1 = clean out filename's symbol table after each request, 0 = don't */
#ifndef DO_CLEAN
#define DO_CLEAN 0
#endif
 
static PerlInterpreter *perl = NULL;
 
int
main(int argc, char **argv, char **env)
{
    char *embedding[] = { "", "persistent.pl" };
    char *args[] = { "", DO_CLEAN, NULL };
    char filename [1024];
    int exitstatus = 0;

    if((perl = perl_alloc()) == NULL) {
	fprintf(stderr, "no memory!");
	exit(1);
    }
    perl_construct(perl); 
    
    exitstatus = perl_parse(perl, NULL, 2, embedding, NULL);

    if(!exitstatus) { 
	exitstatus = perl_run(perl);
  
	while(printf("Enter file name: ") && gets(filename)) {

	    /* call the subroutine, passing it the filename as an argument */
	    args[0] = filename;
	    perl_call_argv("Embed::Persistent::eval_file", 
			   G_DISCARD | G_EVAL, args);

	    /* check $@ */
	    if(SvTRUE(GvSV(errgv))) 
		fprintf(stderr, "eval error: %s\n", SvPV(GvSV(errgv),na));
	}
    }
    
    perl_destruct_level = 0;
    perl_destruct(perl); 
    perl_free(perl); 
    exit(exitstatus);
}

