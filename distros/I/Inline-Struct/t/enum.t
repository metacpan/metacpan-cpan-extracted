use Test::More;
use lib '.';
BEGIN { require 't/common.pl'; }

use Inline C => <<'END', structs => 1, force_build => 1;
struct Foo {
  enum {X,Y,Z} inum;
  double dnum;
  char *str;
};

typedef enum {X2,Y2,Z2} inum2_t;
struct Foo2 {
  inum2_t inum;
  double dnum;
  char *str;
};

enum inum3_e {X3,Y3,Z3};
struct Foo3 {
  enum inum3_e inum;
  double dnum;
  char *str;
};

typedef enum inum4_e {X4,Y4,Z4} inum4_t;
struct Foo4 {
  inum4_t inum;
  double dnum;
  char *str;
};
void suppress_warnings() {}
END

run_struct_tests();
run_struct_tests('Foo2');
run_struct_tests('Foo3');
run_struct_tests('Foo4');

done_testing;
