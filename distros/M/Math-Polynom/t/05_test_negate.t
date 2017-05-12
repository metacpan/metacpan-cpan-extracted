use strict;
use warnings;
use Test::More tests => 3;
use lib "../lib/";

use_ok('Math::Polynom');

my $p = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);
my $c = $p->negate;

is_deeply($c->{polynom},
	  {
	      1 => -2,
	      3.5 => -4.5,
	      5 => 2,
	  }
	  ,"testing negate()");

$p = Math::Polynom->new();
is_deeply($p->negate->{polynom},{},"testing negate on empty polynom");
