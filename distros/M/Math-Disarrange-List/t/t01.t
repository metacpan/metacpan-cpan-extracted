use Test::More qw(no_plan);

use Math::Disarrange::List;

=pod

There are no disarrangements of a set with just one member

=cut

my $a = '';

ok 0 == disarrange {$a .= "@_\n"} 1..1;

ok $a eq << 'end';
end

