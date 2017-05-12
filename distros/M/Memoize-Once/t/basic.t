use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Memoize::Once", qw(once); }

our($a, @a);
is $a, undef;
for(my $i = 0; $i != 5; $i++) {
	push @a, [ $i, once(10 + ++$a) ];
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
is $b, undef;
for(my $i = 0; $i != 0; $i++) {
	push @b, [ $i, once(10 + ++$b) ];
}
is $b, undef;
is_deeply \@b, [];

our $c;
BEGIN { $c = 1; }
sub cc() { once($c) }
$c = 2;
is cc(), 2;
$c = 3;
is cc(), 2;

1;
