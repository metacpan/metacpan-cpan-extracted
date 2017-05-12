use strict;
use warnings;
use Test::More 0.88;

BEGIN {
    plan skip_all => 'statement modifier syntax not supported on versions of perl before 5.13.8'
        if "$]" < 5.013008;
}

use List::Gather;

{
    my @foo = (0 .. 9);
    is_deeply [gather while (defined (my $e = shift @foo)) {
        take $e;
    }], [0 .. 9];
}

{
    my @foo = (0 .. 9);
    is_deeply [gather while (defined (my $e = shift @foo)) {
        take $e;
    }, 23], [0 .. 9, 23];
}

{
    no warnings 'void';

    my @foo = (0 .. 9);
    my @ret = gather while (defined (my $e = shift @foo)) {
        take $e;
    }, 42;

    is_deeply \@ret, [0 .. 9];
}

done_testing;
