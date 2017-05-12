#include <stdio.h>
#include <stdlib.h>
#include "config.h"
#include "test2_cmdline.h"

struct gengetopt_args_info args;

int main (int argc, char **argv) {
  if (cmdline_parser(argc,argv,&args) != 0) {
    printf(">> cmdline_parser() failed.\n");
    exit(1);
  }
  cmdline_parser_envdefaults(&args);

  // -- check out what we got:
  printf("functme    : given=%d\n", args.functme_given);
  printf("flagme2    : given=%d ; value=%d\n", args.flagme2_given, args.flagme2_flag);
  printf("x(toggle)  : given=%d ; value=%d\n", args.x_given, args.x_flag);
  printf("stringme   : given=%d ; value='%s'\n", args.stringme_given, args.stringme_arg);
  printf("fileme     : given=%d ; value='%s'\n", args.fileme_given, args.fileme_arg);
  printf("verbose    : given=%d ; value='%d'\n", args.verbose_given, args.verbose_arg);
  printf("floatme    : given=%d ; value='%g'\n", args.floatme_given, args.floatme_arg);

  return 0;
}
