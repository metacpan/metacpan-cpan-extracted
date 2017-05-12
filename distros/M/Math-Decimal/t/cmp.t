use warnings;
use strict;

use Test::More tests => 62210;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_cmp dec_min dec_max); }

my @values = qw(
	-100.1 -100 -99.31 -99.309 -99
	0
	99.308 99.309 99.31 100
);
for(my $ia = @values; $ia--; ) { for(my $ib = @values; $ib--; ) {
	my $cmp_expect = $ia < $ib ? "-1" : $ia == $ib ? "0" : "1";
	my $a = $values[$ia];
	my $b = $values[$ib];
	my @af = num_forms($a);
	my @bf = num_forms($b);
	foreach my $af (@af) { foreach my $bf (@bf) {
		is dec_cmp($af, $bf), $cmp_expect;
		is dec_min($af, $bf), $cmp_expect eq "-1" ? $a : $b;
		is dec_max($af, $bf), $cmp_expect eq "1" ? $a : $b;
	} }
} }

is_deeply [ sort { dec_cmp($a, $b) } qw(-99.31 99.309 -100.1 0 100) ],
	[ qw(-100.1 -99.31 0 99.309 100) ];

1;
