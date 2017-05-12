use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok "Memoize::Once", qw(once); }

sub cc($) {
	my($v) = @_;
	my $z = once($v);
	$v = undef;
	return $z;
}
is cc(2), 2;
is cc(3), 2;
is cc(4), 2;

1;
