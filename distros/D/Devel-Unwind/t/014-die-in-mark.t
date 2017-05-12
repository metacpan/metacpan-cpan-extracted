use strict;
use warnings;

use Test::More;
use Devel::Unwind;

my $x;
mark FOO {
    die "died in mark";
    fail "Execution resumed in mark";
    1;
} or do {
    $x = 'foo';
    like($@, qr/^died in mark/);
};
is($x,'foo', 'Variable correctly set after mark block');
done_testing;
