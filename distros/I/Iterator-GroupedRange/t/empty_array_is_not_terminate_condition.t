use strict;
use warnings;

use Test::More;
use Iterator::GroupedRange;

my @ds = (
    [ 1 .. 5 ],
    [],
    [ 6.. 7 ],
);

my $iterator = Iterator::GroupedRange->new(
    sub { shift @ds },
    10,
);

is( $iterator->has_next, 1, 'has_next is ok' );
is_deeply( scalar $iterator->next, [ 1..7 ], 'next is ok' );

is( $iterator->has_next, 0, 'has_next is ok' );
is_deeply( scalar $iterator->next, undef, 'next is ok' );

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:

