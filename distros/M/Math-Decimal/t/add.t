use warnings;
use strict;

use Test::More tests => 16363;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_add dec_sub); }

foreach(
	[qw(    0      0       0    )],
	[qw(  123    456     579    )],
	[qw(    1.23   4.56    5.79 )],
	[qw(  123      4.56  127.56 )],
	[qw( 1234     56    1290    )],
	[qw(  123.4    5.6   129    )],
	[qw(   12.34   0.56   12.9  )],
	[qw(   -1      1       0    )],
	[qw(   -1.3    1.3     0    )],
	[qw( -123.4   -5.6  -129    )],
	[qw(  123.4   -5.6   117.8  )],
	[qw( -123.4    5.6  -117.8  )],
	[qw( -123.4    5.4  -118    )],
	[qw(    7.4    2.7    10.1  )],
) {
	my($a, $b, $c) = @$_;
	my @af = num_forms($a);
	my @bf = num_forms($b);
	my @cf = num_forms($c);
	foreach my $af (@af) {
		foreach my $bf (@bf) {
			is dec_add($af, $bf), $c;
			is dec_add($bf, $af), $c;
		}
	}
	foreach my $cf (@cf) {
		foreach my $bf (@bf) {
			is dec_sub($cf, $bf), $a;
		}
		foreach my $af (@af) {
			is dec_sub($cf, $af), $b;
		}
	}
}

1;
