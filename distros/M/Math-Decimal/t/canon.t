use warnings;
use strict;

use Test::More tests => 145;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_canonise); }

foreach my $num (qw(
	0 3 3.1 30.01 -30.01 0.1 0.01 -0.01 -34070.01043
)) {
	foreach(num_forms($num)) {
		is dec_canonise($_), $num;
	}
}

1;
