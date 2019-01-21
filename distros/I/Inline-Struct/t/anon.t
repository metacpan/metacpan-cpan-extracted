use Test::More;
use lib '.';
require 't/common.pl';

use Inline C => <<'END', structs => 1, force_build => 1;
typedef struct {
    /* a comment */
    int inum;
    double dnum; // another comment
    char *str;
} Foo;
void suppress_warnings() {}
END

run_struct_tests();

done_testing;
