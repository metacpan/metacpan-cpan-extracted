use warnings;
use strict;

use Test::More tests => 650;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_sgn dec_abs dec_neg); }

foreach(
	[qw(    0     0    0    )],
	[qw(    0.03  1   -0.03 )],
	[qw(   -0.03 -1    0.03 )],
	[qw(    0.1   1   -0.1  )],
	[qw(    1     1   -1    )],
	[qw(   -1    -1    1    )],
	[qw(    1.3   1   -1.3  )],
	[qw(    1.31  1   -1.31 )],
	[qw(  120     1 -120    )],
	[qw( -120    -1  120    )],
	[qw(  120.01  1 -120.01 )],
	[qw(  123     1 -123    )],
	[qw( -123    -1  123    )],
	[qw( -123.4  -1  123.4  )],
) {
	my($a, $sgn, $neg) = @$_;
	my $abs = $sgn eq "-1" ? $neg : $a;
	foreach(num_forms($a)) {
		is dec_sgn($_), $sgn;
		is dec_abs($_), $abs;
		is dec_neg($_), $neg;
	}
}

is_deeply [ sort { dec_sgn($a - $b) } (5, -3, 2, -20) ],
	[ -20, -3, 2, 5 ];

1;
