use Test2::V0;
use Loop::Util;

my $e_first = do {
	local $@;
	eval q{
		my @array = qw(foo bar baz);
		while (@array) {
			my $i = shift @array;
			iffirst { }
		}
	};
	$@;
};

like( $e_first, qr/iffirst only works in for\/foreach loops/, "iffirst in while dies" );

my $e_iflast = do {
	local $@;
	eval q{
		my @out;
		my @array = qw(foo bar baz);
		while (@array) {
			my $i = shift @array;
			iflast  { push @out, "FINAL"; }
		}
	};
	$@;
};

like( $e_iflast, qr/iflast/, "iflast in while dies" );

my $e_ifodd = do {
	local $@;
	eval q{
		my @array = qw(foo bar baz);
		while (@array) {
			my $i = shift @array;
			ifodd { }
		}
	};
	$@;
};

like( $e_ifodd, qr/ifodd only works in for\/foreach loops/, "ifodd in while dies" );

my $e_ifeven = do {
	local $@;
	eval q{
		my @array = qw(foo bar baz);
		while (@array) {
			my $i = shift @array;
			ifeven { }
		}
	};
	$@;
};

like( $e_ifeven, qr/ifeven only works in for\/foreach loops/, "ifeven in while dies" );

my $e = do {
	local $@;
	eval q{
		my @out;
		my @array = qw(foo bar baz);
		while (@array) {
			my $i = shift @array;
			push @out, $i;
			push @out, uc($i);
		}
	};
	$@;
};

is( $e, '', 'plain while loop still runs' );

done_testing;
