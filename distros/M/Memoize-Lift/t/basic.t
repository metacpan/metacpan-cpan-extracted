use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

our($a, @a);
is $a, 1;
for(my $i = 0; $i != 5; $i++) {
	push @a, [ $i, lift(10 + ++$a) ];
}
is $a, 1;
is_deeply \@a, [
	[ 0, 11 ],
	[ 1, 11 ],
	[ 2, 11 ],
	[ 3, 11 ],
	[ 4, 11 ],
];

our($b, @b);
is $b, 1;
for(my $i = 0; $i != 0; $i++) {
	push @b, [ $i, lift(10 + ++$b) ];
}
is $b, 1;
is_deeply \@b, [];

our $c;
BEGIN { $c = 1; }
sub cc() { lift($c) }
$c = 2;
is cc(), 1;
$c = 3;
is cc(), 1;

1;
