#!perl -w

use strict;

use constant HAS_THREADS   => eval q{ use threads; 1 };
use constant HAS_LEAKTRACE => eval q{use Test::LeakTrace 0.06; 1};
use Test::More;

BEGIN{
	if(HAS_THREADS && HAS_LEAKTRACE){
		plan tests => 2;
	}
	else{
		plan skip_all => 'require both threads and Test::LeakTrace';
	}
}
use Hash::FieldHash qw(:all);


{
	package A;

	sub new{
		bless [], shift;
	}
}


fieldhash my %hash;

leaks_cmp_ok{
	# NOTE: weaken({}) leaks an AV in 5.10.0, so I use [] in here.
	my $x = A->new();
	my $y = A->new();

	$hash{$x} = 'Hello';
	$hash{$y} = 42;
	$hash{$y}++ for 1 .. 10;

	async{
		my $z = ['thx'];
		$hash{$z}++;
	}->join();

	
} '<=', 1;

is_deeply \%hash, {};
