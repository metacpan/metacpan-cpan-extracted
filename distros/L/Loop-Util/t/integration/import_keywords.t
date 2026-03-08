use Test2::V0;
no warnings 'once';

my @selected_out;
my $e_selected = do {
	local $@;
	eval q{
		package LoopUtilImportSelected;
		use Loop::Util qw( loop iffirst );
		our @OUT;
		loop (2) {
			iffirst { push @OUT, "first" }
			push @OUT, $Loop::Util::ITERATION;
		}
		1;
	};
	$@;
};

@selected_out = @LoopUtilImportSelected::OUT;

is( $e_selected, q{},
	"selected keyword import parses iffirst and works in loop" );
is( \@selected_out, [ "first", 0, 1 ], "iffirst works in loop" );

my $plain_iflast = eval q{
	package LoopUtilImportNoLast;
	use strict;
	use warnings;
	use Loop::Util qw( loop iffirst );
	sub iflast {
		return "plain-sub";
	}
	my $x = iflast +{ one => 1 };
	$x;
};

is( $plain_iflast, "plain-sub", "iflast is not parsed when not imported" );

my $plain_ifodd = eval q{
	package LoopUtilImportNoOdd;
	use strict;
	use warnings;
	use Loop::Util qw( loop iffirst );
	sub ifodd {
		return "plain-sub";
	}
	my $x = ifodd +{ one => 1 };
	$x;
};

is( $plain_ifodd, "plain-sub", "ifodd is not parsed when not imported" );

my $err_unknown = do {
	local $@;
	eval q{
		package LoopUtilImportUnknown;
		use Loop::Util qw( bananas );
		1;
	};
	$@;
};

like( $err_unknown, qr/Unknown Loop::Util keyword 'bananas'/,
	"unknown keyword is rejected" );

done_testing;
