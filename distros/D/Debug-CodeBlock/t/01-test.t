use Test::More;

{
	package Odea;

	use Debug::CodeBlock qw/all/;

	our $DEBUG = 0;

	sub new {
		bless {}, $_[0];
	}

	sub thing {
		my $variable = 1;
		DEBUG {
			$variable = 2;
		};
		DEBUG {
			warn Dump($variable);
		};
		return $variable;
	}

	sub turn_off_debug {
		$DEBUG = 0;
	}

	sub turn_on_debug {
		$DEBUG = 1;
	}

	sub DEBUG_ENABLED {
		return $DEBUG;
	}

	1;
}

my $odea = Odea->new();
is($odea->thing(), 1);
ok($odea->turn_on_debug);
is(Odea->thing(), 2);

done_testing();
