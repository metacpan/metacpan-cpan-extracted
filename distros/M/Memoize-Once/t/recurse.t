use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Once", qw(once); }

our @a;
our $ii;
sub foo($);
sub foo($) {
	my($i) = @_;
	push @a, $i;
	$ii = $i;
	return 50 + once($ii == 10 ? 10 : 100+foo($ii+1));
}
is_deeply \@a, [];
is foo(0), 60;
is_deeply \@a, [0,1,2,3,4,5,6,7,8,9,10];
is foo(5), 60;
is_deeply \@a, [0,1,2,3,4,5,6,7,8,9,10,5];

1;
