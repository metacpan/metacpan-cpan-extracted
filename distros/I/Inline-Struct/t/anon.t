use Test::More;
require 't/common.pl';

use Inline C => <<'END', structs => 1, force_build => 1;
typedef struct {
    int inum;
    double dnum;
    char *str;
} Foo;
void suppress_warnings() {}
END

run_struct_tests();

done_testing;
