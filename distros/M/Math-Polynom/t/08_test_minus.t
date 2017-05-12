use strict;
use warnings;
use Test::More tests => 16;
use lib "../lib/";

use_ok('Math::Polynom');

my $p1 = Math::Polynom->new();
my $p2 = Math::Polynom->new(0 => 5);
my $p3 = Math::Polynom->new(4.6 => 4, 5 => 2, 3.5 => 2.5, 6 => 7, 8 => 9);
my $p4 = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);

# minus nothing
is_deeply($p1->minus($p2)->{polynom},
	  { 0 => -5 },
	  "p1->minus(p2)");

is_deeply($p2->minus($p1),
	  $p2,
	  "p1->minus(p2)");

is_deeply($p1->minus($p3)->{polynom},
	  { 4.6 => -4, 5 => -2, 3.5 => -2.5, 6 => -7, 8 => -9 },
	  "p1->minus(p3)");

is_deeply($p3->minus($p1),
	  $p3,
	  "p1->minus(p3)");

# minus constant
is_deeply($p1->minus(3)->{polynom},
	  { 0 => -3 },
	  "p1->minus(3)");

is_deeply($p2->minus(6.5)->{polynom},
	  { 0 => -1.5 },
	  "p2->minus(6.5)");

is_deeply($p4->minus(6.5)->{polynom},
	  { 0 => -6.5, 1 => 2, 3.5 => 4.5, 5 => -2 },
	  "p4->minus(6.5)");

# substraction of polynoms
is_deeply($p3->minus($p2)->{polynom},
	  { 0 => -5, 4.6 => 4, 5 => 2, 3.5 => 2.5, 6 => 7, 8 => 9 },
	  "p3->minus(p2)");

is_deeply($p2->minus($p3)->{polynom},
	  { 0 => 5, 4.6 => -4, 5 => -2, 3.5 => -2.5, 6 => -7, 8 => -9 },
	  "p2->minus(p3)");

# the most interesting exemple, by far :)
is_deeply($p3->minus($p4)->{polynom},
	  {
	      1 => -2,
	      4.6 => 4,
	      3.5 => -2,
	      5 => 4,
	      6 => 7,
	      8 => 9,
	  },
	  "p3->minus(p4)");

is_deeply($p4->minus($p3)->{polynom},
	  {
	      1 => 2,
	      3.5 => 2,
	      4.6 => -4,
	      5 => -4,
	      6 => -7,
	      8 => -9,
	  },
	  "p4->minus(p3)");

# fault handling
eval { $p3->minus(undef); };
ok((defined $@ && $@ =~ /got undefined argument/), "minus(undef)");

eval { $p3->minus(); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "minus()");

eval { $p3->minus(1,2); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "minus(1,2)");

eval { $p3->minus('abc'); };
ok((defined $@ && $@ =~ /got non numeric argument/), "minus('abc')");

