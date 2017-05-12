use strict;
use warnings;
use Test::More tests => 11;
use lib "../lib/";

use_ok('Math::Polynom');

my $p1;

$p1 = Math::Polynom->new(1 => 2, 3 => 4);

is(ref $p1, "Math::Polynom", "check type");
is_deeply($p1,
	  {
	      polynom => { 1 => 2, 3 => 4 },
	      -error  => 0,
	      -iterations => 0,
	  },
	  "check content"
	);

$p1 = new Math::Polynom(1.8 => 5.2, 3.1 => 0);

is(ref $p1, "Math::Polynom", "check type");
is_deeply($p1,
	  {
	      polynom => { 1.8 => 5.2 },
	      -error  => 0,
	      -iterations => 0,
	  },
	  "check content"
	);

$p1 = new Math::Polynom();

is(ref $p1, "Math::Polynom", "check type (empty polynom)");
is_deeply($p1,{ polynom => {}, -error => 0, -iterations => 0 },"check content (empty polynom)");
ok(!$p1->error,"polynom contains no error");

# test _is_number, indirectly
eval { 
    Math::Polynom->new(1 => 2.5,
		       -1.234728347568237456 => +1.345e23,
		       2 => -1.345e-23,
		       3 => -1.345E-23,
		       4 => -1.345E+23,
		       );
};
ok( (!defined $@ || $@ eq ""), "new() accepts all kind of numbers");

# fault handling
eval { Math::Polynom->new(1); };
ok((defined $@ && $@ =~ /got odd number of arguments/),"new() fails on odd number of arguments");

eval { Math::Polynom->new(1 => 2, 'a' => 3); };
ok((defined $@ && $@ =~ /is not numeric/),"new() fails on non numeric arguments");
