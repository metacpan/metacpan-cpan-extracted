
#include <EXTERN.h> 
#include <perl.h>   

/* this example shows how to create a hash in C, 
 * modify it, push a reference to it onto the stack,
 * call a subroutine which modifies it, 
 * then see the changes when we're back inside C
 */

void
hash_stuff(HV *hv)
{
    dSP;

    hv_store(hv, "foo", 3, newSVpv("val",3), FALSE);
    hv_store(hv, "me", 2, newSVpv("dougm",5), FALSE);

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    XPUSHs(newRV_noinc((SV*)hv)); /* don't mortalize here */
    PUTBACK;

    perl_call_pv("My::subroutine", G_SCALAR | G_EVAL);

    if (SvTRUE(GvSV(errgv)))
        fprintf(stderr, "eval error: %s\n", SvPVx(GvSV(errgv), na));

    FREETMPS;
    LEAVE;
}

int main(int argc, char **argv, char **env)
{
    HV *hv;
    SV *val;
    char *key;
    I32 klen;

    char *embedding[] = { "", "hashref.pl" };
    PerlInterpreter *my_perl = perl_alloc();

    perl_construct(my_perl);
    perl_destruct_level = 1;

    perl_parse(my_perl, NULL, 2, embedding, (char **)NULL);
    perl_run(my_perl);

    hv = newHV();
    hash_stuff(hv); 

    (void)hv_iterinit(hv);
    while ((val = hv_iternextsv(hv, &key, &klen))) 
	printf("in C:    %s=`%s'\n", key, SvPV(val,na));

    /* now release hv */
    hv_undef(hv);
    SvREFCNT_dec((SV*)hv); 

    perl_destruct(my_perl);
    perl_free(my_perl);
}



