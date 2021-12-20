use Test::More;
use lib '.';
require 't/common.pl';

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
  enum {X,Y,Z} inum;
  double dnum;
  char *str;
};

typedef enum {X2,Y2,Z2} inum_t;
struct Foo2 {
  inum_t inum;
  double dnum;
  char *str;
};
void suppress_warnings() {}
END

run_struct_tests();
run_struct_tests('Foo2');

done_testing;
