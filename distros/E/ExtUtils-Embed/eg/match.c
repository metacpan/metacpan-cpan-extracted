#include <EXTERN.h>
#include <perl.h>

/** my_perl_eval_sv(code, error_check)
** kinda like perl_eval_sv(), 
** but we pop the return value off the stack 
**/
SV* my_perl_eval_sv(SV *sv, I32 croak_on_error)
{
    dSP;
    SV* retval;

    PUSHMARK(sp);
    perl_eval_sv(sv, G_SCALAR);

    SPAGAIN;
    retval = POPs;
    PUTBACK;

    if (croak_on_error && SvTRUE(GvSV(errgv)))
	croak(SvPVx(GvSV(errgv), na));

    return retval;
}

/** match(string, pattern)
**
** Used for matches in a scalar context.
**
** Returns 1 if the match was successful; 0 otherwise.
**/

I32 match(SV *string, char *pattern)
{
    SV *command = newSV(0), *retval;

    sv_setpvf(command, "my $string = '%s'; $string =~ %s",
	      SvPV(string,na), pattern);

    retval = my_perl_eval_sv(command, TRUE);
    SvREFCNT_dec(command);

    return SvIV(retval);
}

/** substitute(string, pattern)
**
** Used for =~ operations that modify their left-hand side (s/// and tr///)
**
** Returns the number of successful matches, and
** modifies the input string if there were any.
**/

I32 substitute(SV **string, char *pattern)
{
    SV *command = newSV(0), *retval;

    sv_setpvf(command, "$string = '%s'; ($string =~ %s)",
	      SvPV(*string,na), pattern);

    retval = my_perl_eval_sv(command, TRUE);
    SvREFCNT_dec(command);

    *string = perl_get_sv("string", FALSE);
    return SvIV(retval);
}

/** matches(string, pattern, matches)
**
** Used for matches in an array context.
**
** Returns the number of matches,
** and fills in **matches with the matching substrings
**/

I32 matches(SV *string, char *pattern, AV **match_list)
{
    SV *command = newSV(0);
    I32 num_matches;

    sv_setpvf(command, "my $string = '%s'; @array = ($string =~ %s)",
	      SvPV(string,na), pattern);

    my_perl_eval_sv(command, TRUE);
    SvREFCNT_dec(command);

    *match_list = perl_get_av("array", FALSE);
    num_matches = av_len(*match_list) + 1; /** assume $[ is 0 **/
    
    return num_matches;
}

main (int argc, char **argv, char **env)
{
    PerlInterpreter *my_perl = perl_alloc();
    char *embedding[] = { "", "-e", "0" };
    AV *match_list;
    I32 num_matches, i;
    SV *text = newSV(0);

    perl_construct(my_perl);
    perl_parse(my_perl, NULL, 3, embedding, NULL);

    sv_setpv(text, "When he is at a convenience store and the bill comes to some amount like 76 cents, Maynard is aware that there is something he *should* do, something that will enable him to get back a quarter, but he has no idea *what*.  He fumbles through his red squeezey changepurse and gives the boy three extra pennies with his dollar, hoping that he might luck into the correct amount.  The boy gives him back two of his own pennies and then the big shiny quarter that is his prize. -RICHH");

    if (match(text, "m/quarter/")) /** Does text contain 'quarter'? **/
	printf("match: Text contains the word 'quarter'.\n\n");
    else
	printf("match: Text doesn't contain the word 'quarter'.\n\n");

    if (match(text, "m/eighth/")) /** Does text contain 'eighth'? **/
	printf("match: Text contains the word 'eighth'.\n\n");
    else
	printf("match: Text doesn't contain the word 'eighth'.\n\n");

    /** Match all occurrences of /wi../ **/
    num_matches = matches(text, "m/(wi..)/g", &match_list);
    printf("matches: m/(wi..)/g found %d matches...\n", num_matches);

    for (i = 0; i < num_matches; i++)
	printf("match: %s\n", SvPV(*av_fetch(match_list, i, FALSE),na));
    printf("\n");

    /** Remove all vowels from text **/
    num_matches = substitute(&text, "s/[aeiou]//gi");
    if (num_matches) {
	printf("substitute: s/[aeiou]//gi...%d substitutions made.\n",
	       num_matches);
	printf("Now text is: %s\n\n", SvPV(text,na));
    }

    /** Attempt a substitution **/
    if (!substitute(&text, "s/Perl/C/")) {
	printf("substitute: s/Perl/C...No substitution made.\n\n");
    }

    SvREFCNT_dec(text);
    perl_destruct_level = 1;
    perl_destruct(my_perl);
    perl_free(my_perl);
}







