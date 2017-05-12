#!perl -w

use strict;
use constant HAS_THREADS => eval{ require threads };
use Test::More;

BEGIN{
	if(HAS_THREADS){
		plan tests => 15*3;
	}
	else{
		plan skip_all => 'require threads';
	}
}
use threads;

#use Hash::Util::FieldHash::Compat qw(:all);
use Hash::FieldHash qw(:all);

for(1 .. 3){
	fieldhashes \my(%a, %b);

	{
		my $x = {};
		my $y = {};

		$a{$x} = 'a-x';
		$a{$y} = 'a-y';
		$b{$x} = 'b-x';
		$b{$y} = 'b-y';

		my $thr = async {
			is $a{$x}, 'a-x';
			is $a{$y}, 'a-y';
			is $b{$x}, 'b-x';
			is $b{$y}, 'b-y';

			my $thr1 = async{
				is $a{$x}, 'a-x';

				threads->yield();
				$a{$x} = 3.14;

				threads->yield();
				is $a{$x}, 3.14;
			};

			my $thr2 = async{
				fieldhash my %c;
				my $z = [];

				$c{$x} = $a{$x};
				$c{$z} = 'c-z';

				$a{$x}++;
				$b{$x}++;

				is_deeply [sort values %c], [sort qw(a-x c-z)];
			};

			threads->yield();

			is $a{$x}, 'a-x';

			my $z = {};

			threads->yield();

			is $a{$x}, 'a-x';

			$a{$z} = 42;
			is $a{$z}, 42;

			$thr1->join();
			$thr2->join();
		};

		ok $thr, sprintf 'count=%d, tid=%d', $_, $thr->tid;
		$thr->yield;

		is_deeply [sort values %a], [sort 'a-x', 'a-y'];

		$thr->join;

		is_deeply [sort values %a], [sort 'a-x', 'a-y'];
	}

	is_deeply \%a, {};
	is_deeply \%b, {};
}

