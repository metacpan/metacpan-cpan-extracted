use Test::More;
use lib '.';
BEGIN { require 't/common.pl'; }

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
  int inum;
  double dnum;
  char *str;
};
/*typedef struct Foo Foo;*/
void suppress_warnings() {}
END

run_struct_tests();

done_testing;
