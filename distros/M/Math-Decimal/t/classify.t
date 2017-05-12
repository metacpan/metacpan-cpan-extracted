use warnings;
use strict;

use Test::More tests => 1324;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(
	$dec_number_rx $dec_integer_rx $dec_zero_rx $dec_one_rx $dec_negone_rx
	is_dec_number check_dec_number
); }

# This only checks classification of valid decimals.  For non-decimal test
# values, see t/error.t.

foreach my $num (qw(
	0 1 1.1 -1 3 3.1 30.01 -30.01 0.1 0.01 -0.01 -34070.01043
)) {
	foreach(num_forms($num)) {
		ok $_ =~ /\A$dec_number_rx\z/o;
		ok($_ =~ /\A$dec_integer_rx\z/o xor $num =~ /\./);
		ok($_ =~ /\A$dec_zero_rx\z/o xor $num ne "0");
		ok($_ =~ /\A$dec_one_rx\z/o xor $num ne "1");
		ok($_ =~ /\A$dec_negone_rx\z/o xor $num ne "-1");
		ok is_dec_number($_);
		eval { check_dec_number($_); }; is $@, "";
	}
}

1;
