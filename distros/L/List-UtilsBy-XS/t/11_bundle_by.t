use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw(bundle_by);

my @gots;
my $expected;

@gots = bundle_by { $_[0] } 1, (1, 2, 3);
is_deeply(\@gots, [ 1, 2, 3 ], 'bundle_by 1');

@gots = bundle_by { $_[0] } 2, (1, 2, 3, 4);
is_deeply(\@gots, [ 1, 3 ], 'bundle_by 2 first');

@gots = bundle_by { @_ } 2, (1, 2, 3, 4);
is_deeply(\@gots, [ 1, 2, 3, 4 ], 'bundle_by 2 all') || diag explain \@gots;

@gots = bundle_by { [ @_ ] } 2, (1, 2, 3, 4);
is_deeply(\@gots, [ [ 1, 2 ], [ 3, 4 ] ], 'bundle_by 2 [all]');

my %gots = bundle_by { uc $_[1] => $_[0] } 2, qw( a b c d );
is_deeply(\%gots, { B => "a", D => "c" }, 'bundle_by 2 constructing hash');

done_testing;
