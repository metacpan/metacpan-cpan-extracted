use strict;
use warnings;
use Test::More tests => 23;
use lib "../lib/";

use_ok('Math::Polynom');

my $p1 = Math::Polynom->new();        # nothing
my $p2 = Math::Polynom->new(0 => 5);  # 5
my $p3 = Math::Polynom->new(0 => 7);  # 7
my $p4 = Math::Polynom->new(1 => 2);  # 2*x^2
my $p5 = Math::Polynom->new(3 => 9);  # 9*x^3
my $p6 = Math::Polynom->new(5 => 5, 3.2 => 4, 0.9 => -2);  # 5*x^5 + 4*x^3.2 - 2*x^0.9
my $p7 = Math::Polynom->new(3 => 6, 1.8 => -6, -1 => 6);    # 6*x^3 - 6*x^1.8 + 6*x^-1

my @tests = (
	     # nothing times anything = nothing
	     $p1, $p1, { },

	     $p1, $p2, { },
	     $p2, $p1, { },

	     $p1, $p3, { },
	     $p3, $p1, { },

	     $p1, $p4, { },
	     $p4, $p1, { },

	     # more complex cases
	     $p2, $p3, { 0 => 35 },
	     $p3, $p2, { 0 => 35 },

	     $p4, $p2, { 1 => 10},
	     $p2, $p4, { 1 => 10},

	     $p5, $p4, { 4 => 18},
	     $p4, $p5, { 4 => 18},

	     # serious stuff now
	     $p5, $p6, { 8 => 45, 6.2 => 36, 3.9 => -18},
	     $p6, $p5, { 8 => 45, 6.2 => 36, 3.9 => -18},

	     $p6, $p7, { 4 => 30, 2.2 => 24, -0.1 => -12,
			 6.8 => -30, 5 => -24, 2.7 => 12,
			 8 => 30, 6.2 => 24, 3.9 => -12},

	     $p7, $p6, { 4 => 30, 2.2 => 24, -0.1 => -12,
			 6.8 => -30, 5 => -24, 2.7 => 12,
			 8 => 30, 6.2 => 24, 3.9 => -12},

	     # and a school exemple to be sure
	     Math::Polynom->new(1 => 1, 0 => 1), # x+1
	     Math::Polynom->new(2 => 1, 1 => 1), # x^2+x
	     { 3 => 1, 2 => 2, 1 => 1},

	     );

while (@tests) {
    my $poly1 = shift @tests;
    my $poly2 = shift @tests;
    my $want  = shift @tests;
    is_deeply($poly1->multiply($poly2)->{polynom},$want,"[".$poly1->stringify."]->multiply(".$poly2->stringify.")");
}

# fault handling
eval { $p3->multiply(undef); };
ok((defined $@ && $@ =~ /got undefined argument/), "multiply(undef)");

eval { $p3->multiply(); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "multiply()");

eval { $p3->multiply(1,2); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "multiply(1,2)");

eval { $p3->multiply('abc'); };
ok((defined $@ && $@ =~ /got non numeric argument/), "multiply('abc')");
