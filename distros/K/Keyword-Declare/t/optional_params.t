use warnings;
use strict;

use Test::More;

plan tests => 2;

use Keyword::Declare;

keyword opt_scalar ('is', Ident? $not, Num $n) {
    "ok " . (length $not ? 0 : 1) . ", 'opt_scalar $n';"
}

keyword opt_array ('is', Ident* @not, Num $n) {
    "ok " . (@not ? 0 : 1) . ", 'opt_array $n';"
}

opt_scalar is 1;
opt_array  is 2;


done_testing();

