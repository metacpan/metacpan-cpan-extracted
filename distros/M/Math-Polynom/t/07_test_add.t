use strict;
use warnings;
use Test::More tests => 17;
use lib "../lib/";

use_ok('Math::Polynom');

my $p1 = Math::Polynom->new();
my $p2 = Math::Polynom->new(0 => 5);
my $p3 = Math::Polynom->new(4.6 => 4, 5 => 2, 3.5 => 2.5, 6 => 7, 8 => 9);
my $p4 = Math::Polynom->new(1 => 2, 3.5 => 4.5, 5 => -2);

is_deeply($p1->add($p2),$p2,"p + empty polynom = p");
is_deeply($p2->add($p1),$p2,"p + empty polynom = p (commutativity)");
is_deeply($p1->add($p3),$p3,"p + empty polynom = p");
is_deeply($p3->add($p1),$p3,"p + empty polynom = p (commutativity)");

is_deeply($p1->add(3)->{polynom},
	  { 0 => 3 },
	  "empty polynom + constant");

is_deeply($p2->add(6.5)->{polynom},
	  { 0 => 11.5 },
	  "constant + constant");

is_deeply($p4->add(6.5)->{polynom},
	  { 0 => 6.5, 1 => 2, 3.5 => 4.5, 5 => -2 },
	  "constant + constant");

is_deeply($p3->add($p2)->{polynom},
	  { 0 => 5, 4.6 => 4, 5 => 2, 3.5 => 2.5, 6 => 7, 8 => 9 },
	  "p3->add(p2)");

# the most interesting exemple, by far :)
is_deeply($p3->add($p4)->{polynom},
	  {
	      1 => 2,
	      4.6 => 4,
	      3.5 => 7,
	      6 => 7,
	      8 => 9,
	  },
	  "p3->add(p4)");

is_deeply($p3->add($p2),$p2->add($p3),"p3->add(p2) = p2->add($p3)");
is_deeply($p3->add($p4),$p4->add($p3),"p3->add(p4) = p4->add($p3)");
is_deeply($p2->add($p4),$p4->add($p2),"p2->add(p4) = p4->add($p2)");

# fault handling
eval { $p3->add(undef); };
ok((defined $@ && $@ =~ /got undefined argument/), "add(undef)");

eval { $p3->add(); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "add()");

eval { $p3->add(1,2); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "add(1,2)");

eval { $p3->add('abc'); };
ok((defined $@ && $@ =~ /got non numeric argument/), "add('abc')");

