#include <EXTERN.h>
#include <perl.h>

/* we'll do this until 5.004 final */
#include "patchlevel.h"
#if (PATCHLEVEL < 4) && (SUBVERSION < 98)
#include "perl_eval_pv.c"
#endif

static PerlInterpreter *my_perl;

/** match(string, pattern)
**
** Used for matches in a scalar context.
**
** Returns 1 if the match was successful; 0 otherwise.
**/

char match(char *string, char *pattern)
{
  char *command;
  command = malloc(sizeof(char) * strlen(string) + strlen(pattern) + 37);
  sprintf(command, "$string = '%s'; $return = $string =~ %s",
	  string, pattern);
  perl_eval_pv(command, TRUE);
  free(command);
  return SvIV(perl_get_sv("return", FALSE));
}

/** substitute(string, pattern)
**
** Used for =~ operations that modify their left-hand side (s/// and tr///)
**
** Returns the number of successful matches, and
** modifies the input string if there were any.
**/

int substitute(char *string[], char *pattern)
{
  char *command;
  STRLEN length;
  command = malloc(sizeof(char) * strlen(*string) + strlen(pattern) + 35);
  sprintf(command, "$string = '%s'; $ret = ($string =~ %s)",
	  *string, pattern);
     perl_eval_pv(command, TRUE);
     free(command);
     *string = SvPV(perl_get_sv("string", FALSE), length);
     return SvIV(perl_get_sv("ret", FALSE));
}

/** matches(string, pattern, matches)
**
** Used for matches in an array context.
**
** Returns the number of matches,
** and fills in **matches with the matching substrings (allocates memory!)
**/

int matches(char *string, char *pattern, char **match_list[])
{
  char *command;
  SV *current_match;
  AV *array;
  I32 num_matches;
  STRLEN length;
  int i;
  command = malloc(sizeof(char) * strlen(string) + strlen(pattern) + 38);
  sprintf(command, "$string = '%s'; @array = ($string =~ %s)",
	  string, pattern);
  perl_eval_pv(command, TRUE);
  free(command);
  array = perl_get_av("array", FALSE);
  num_matches = av_len(array) + 1; /** assume $[ is 0 **/
  *match_list = (char **) malloc(sizeof(char *) * num_matches);
  for (i = 0; i <= num_matches; i++) {
    current_match = av_shift(array);
    (*match_list)[i] = SvPV(current_match, length);
  }
  return num_matches;
}

main (int argc, char **argv, char **env)
{
  char *embedding[] = { "", "-e", "0" };
  char *text, **match_list;
  int num_matches, i;
  int j;
  my_perl = perl_alloc();
  perl_construct( my_perl );
  perl_parse(my_perl, NULL, 3, embedding, NULL);
  text = (char *) malloc(sizeof(char) * 486); /** A long string follows! **/
  sprintf(text, "%s", "When he is at a convenience store and the bill comes to some amount like 76 cents, Maynard is aware that there is something he *should* do, something that will enable him to get back a quarter, but he has no idea *what*.  He fumbles through his red squeezey changepurse and gives the boy three extra pennies with his dollar, hoping that he might luck into the correct amount.  The boy gives him back two of his own pennies and then the big shiny quarter that is his prize. -RICHH");
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
    printf("match: %s\n", match_list[i]);
  printf("\n");
  for (i = 0; i < num_matches; i++) {
    free(match_list[i]);
  }
  free(match_list);
  /** Remove all vowels from text **/
  num_matches = substitute(&text, "s/[aeiou]//gi");
  if (num_matches) {
    printf("substitute: s/[aeiou]//gi...%d substitutions made.\n",
	   num_matches);
    printf("Now text is: %s\n\n", text);
  }
  /** Attempt a substitution **/
  if (!substitute(&text, "s/Perl/C/")) {
    printf("substitute: s/Perl/C...No substitution made.\n\n");
  }
  free(text);
  perl_destruct(my_perl);
  perl_free(my_perl);
}







