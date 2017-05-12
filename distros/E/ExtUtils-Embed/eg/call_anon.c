#include <EXTERN.h>
#include <perl.h>
static PerlInterpreter *my_perl;

/* this is an example of how to create and call 
 * an anonymous subroutine in C.  Originally it did 
 * the work of perl_eval_pv, which is now part of the 
 * standard Perl API.  there still may be some use bits here...
 */

void call_anon(AV *av, char *code)
{
    int i;
    dSP;
    /* normally you should cache the compiled sub! */
    SV *sub = perl_eval_pv(code, TRUE);

    ENTER;
    PUSHMARK(sp);

    for(i=0; i<=av_len(av); i++) {
	XPUSHs(sv_2mortal(*av_fetch(av, i, FALSE))); 
    }

    PUTBACK;
    (void)perl_call_sv(sub, G_VOID | G_EVAL);
    SPAGAIN;

    if(SvTRUE(GvSV(errgv))) 
	fprintf(stderr, "Error: %s\n", SvPV(GvSV(errgv),na));

    PUTBACK;
    LEAVE;
}    

int main(int argc, char **argv, char **env)
{
    char *embedding[] = { "", "-e", "0" };
    AV *av = newAV();
    SV *sv;
    int i;

    /* configuration file type stuff, 
       normally read from a file on disk */
    av_push(av, newSVpv("#comment",0));
    av_push(av, newSVpv("  Foo = Bar \n",0));

    my_perl = perl_alloc();
    perl_construct(my_perl);
    perl_parse(my_perl, NULL, 3, embedding, (char **)NULL);
    perl_run(my_perl);

    call_anon(av, "sub {
    for(@_) {
	chomp;                 #get rid of \n
	s/^#.*//;              #strip comments
        s/^\\s*//; s/\\s*$//;  #strip leading and trailing whitespace
    }
}");

    for(i=0; i<=av_len(av); i++) {
	sv = *av_fetch(av, i, FALSE); 
	printf("parsed: `%s'\n", SvPV(sv,na));
    }
} 
