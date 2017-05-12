use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $a = {"a" => 1,
         "b" => 4,
		 "c" => 9,
		 "d" => 16,};
		 
my $b = happly($a, sub{sqrt($_[0])});
my $c = happly($a, sub {$_[0] + 2});

is_deeply($b, {a => 1,
               b => 2,
			   c => 3,
			   d => 4});
			   
is_deeply($c, {a => 3,
               b => 6,
			   c => 11,
			   d => 18});
			   