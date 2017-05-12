#include <stdio.h>
#include <stdlib.h>
#include "test1_cmdline.h"

struct gengetopt_args_info args;

int main (int argc, char **argv) {
  if (cmdline_parser(argc,argv,&args) != 0) {
    printf(">> cmdline_parser() failed.\n");
    exit(1);
  }

  // -- check out what we got:
  printf("toggle-opt : given=%d\n", args.toggleme_given);
  printf("flag-opt   : given=%d ; value=%d\n", args.flagme_given, args.flagme_flag);
  printf("string-opt : given=%d ; value='%s'\n", args.stringme_given, args.stringme_arg);
  printf("verbose    : given=%d ; value='%d'\n", args.verbose_given, args.verbose_arg);
  printf("floatme    : given=%d ; value='%g'\n", args.floatme_given, args.floatme_arg);

  return 0;
}
