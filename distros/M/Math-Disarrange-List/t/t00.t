use Test::More qw(no_plan);

=pod

An important test: the code block supplied to disarrange should be called 
once on the empty set, as no element can be found that retains its original 
position and thus the empty set is an disarrangement of itself.

=cut

use Math::Disarrange::List;

my $a = '';

ok 1 == disarrange {$a .= 1} ();

ok $a eq 1;

