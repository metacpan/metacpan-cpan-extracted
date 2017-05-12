use strict;
use warnings;
use Test::More tests => 9;
use lib "../lib/";

use_ok('Math::Polynom');

my $p = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);
is_deeply($p->divide(2)->{polynom},
	  {
	      1 => 1,
	      3.5 => 2.25,
	      5 => -1,
	  }
	  ,"testing divide(2)");

$p = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);
is_deeply($p->divide(-1)->{polynom},
	  {
	      1 => -2,
	      3.5 => -4.5,
	      5 => 2,
	  }
	  ,"testing divide(-1)");

is_deeply(Math::Polynom->new()->divide(5)->{polynom},{},"testing divide(5) on empty polynom");

# fault handling
eval { $p->divide(); };
ok((defined $@ && $@ =~ /got wrong number of arguments/),"divide()");

eval { $p->divide({}); };
ok((defined $@ && $@ =~ /got non numeric argument/),"divide({})");

eval { $p->divide('bob'); };
ok((defined $@ && $@ =~ /got non numeric argument/),"divide('bob')");

eval { $p->divide(undef); };
ok((defined $@ && $@ =~ /got undefined argument/),"divide(undef)");

eval { $p->divide(0); };
ok((defined $@ && $@ =~ /cannot divide by 0/),"test division by 0");




