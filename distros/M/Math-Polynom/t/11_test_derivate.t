use strict;
use warnings;
use Test::More tests => 7;
use lib "../lib/";

use_ok('Math::Polynom');

my $p1 = Math::Polynom->new();
my $p2 = Math::Polynom->new(0 => 5);
my $p3 = Math::Polynom->new(1 => 5);
my $p4 = Math::Polynom->new(2 => 5);
my $p5 = Math::Polynom->new(4.6 => 4, 5 => 2, 3.5 => 2.5, 6 => 7, .5 => 4);
my $p6 = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);

is_deeply($p1->derivate->{polynom},
	  { },
	  "derivate empty polynom");

is_deeply($p2->derivate->{polynom},
	  { },
	  "derivate constant");

is_deeply($p3->derivate->{polynom},
	  {  0 => 5 },
	  "derivate [".$p3->stringify."]");

is_deeply($p4->derivate->{polynom},
	  {  1 => 10 },
	  "derivate [".$p4->stringify."]");

is_deeply($p5->derivate->{polynom},
	  {
	      5 => 42,
	      4 => 10,
	      3.6 => 18.4,
	      2.5 => 8.75,
	      -.5 => 2,
	  },
	  "derivate [".$p5->stringify."]");

is_deeply($p6->derivate->{polynom},
	  {
	      4 => -10,
	      2.5 => 15.75,
	      0 => 2,
	  },
	  "derivate [".$p6->stringify."]");
