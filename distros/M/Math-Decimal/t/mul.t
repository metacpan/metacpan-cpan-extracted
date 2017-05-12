use warnings;
use strict;

use Test::More tests => 5995;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_mul); }

foreach(
	[qw(    0      0       0    )],
	[qw(    0      2.7     0    )],
	[qw(    0     -2.7     0    )],
	[qw(    1      2.7     2.7  )],
	[qw(   -2.55   2      -5.1  )],
	[qw(  123    456   56088    )],
	[qw( -123     -3.1   381.3  )],
	[qw(   99     88.8  8791.2  )],
	[qw(  104     88.8  9235.2  )],
) {
	my($a, $b, $c) = @$_;
	my @af = num_forms($a);
	my @bf = num_forms($b);
	foreach my $af (@af) {
		foreach my $bf (@bf) {
			is dec_mul($af, $bf), $c;
			is dec_mul($bf, $af), $c;
		}
	}
}

1;
