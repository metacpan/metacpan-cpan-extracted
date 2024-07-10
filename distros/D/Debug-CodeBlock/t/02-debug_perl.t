use Test::More;

my $set;
unless ($ENV{DEBUG_PERL}) {
	$set = 1;
	$ENV{DEBUG_PERL} = 1;
}



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

	1;
}

my $odea = Odea->new();
is(Odea->thing(), 2);

if ($set) {
	delete $ENV{DEBUG_PERL};
}

done_testing();
