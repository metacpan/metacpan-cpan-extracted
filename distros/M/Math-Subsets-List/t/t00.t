use Test::More qw(no_plan);

use Math::Subsets::List;

=pod

There is one subset of the empty set: the empty set.

=cut

my $a = '';

ok 1 == subsets {$a .= "@_\n"} ();

ok $a eq "\n";
