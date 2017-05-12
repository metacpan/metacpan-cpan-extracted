use strict;
use warnings;
use Test::More;
use lib "../lib/";

eval "use Data::Float qw(float_is_nan)";
plan skip_all => "Data::Float required for testing eval()" if $@;

plan tests => 54;

use_ok('Math::Polynom');

sub test_eval {
    my($p,@tests) = @_;
    while (@tests) {
	my $value = shift @tests;
	my $want  = shift @tests;

	is($p->eval($value),$want,"eval($value) on [".$p->stringify."]");

	if ($want > 0) {
	    is($p->xpos, $value, "xpos set to value");
	    is($p->xneg, undef,  "xneg stays undef");
	} elsif ($want < 0) {
	    is($p->xpos, undef,  "xpos stays undef");
	    is($p->xneg, $value, "xneg set to value");
	} else {
	    is($p->xpos, undef,  "xpos stays undef");
	    is($p->xneg, undef,  "xneg stays undef");
	}

	$p->xpos(undef);
	$p->xneg(undef);
    }
}


# empty polynom
my $p = Math::Polynom->new();
test_eval($p,
	  0 => 0,
	  12 => 0,
	  );

# constant polynom
$p = Math::Polynom->new(0 => 5);
test_eval($p,
	  -5 => 5,
	  2 => 5,
	  654321 => 5,
	  );

# a simple square
$p = Math::Polynom->new(2 => 1);
test_eval($p,
	  -5 => 25,
	  2 => 4,
	  14 => 196,
	  0 => 0,
	  );

# a more complex one
$p = Math::Polynom->new(2 => 3, .5 => 5.2);
test_eval($p,
	  4  =>  58.4,
	  0 => 0,
	  );

my $v = $p->eval(-5);
ok(float_is_nan($v),"got a nan on -5");

# negative power
$p = Math::Polynom->new(-1 => 10);
test_eval($p,
	  1 => 10,
	  10 => 1,
	  5 => 2,
	  -5 => -2,
	  );

# fault handling
eval { $p->eval(undef); };
ok((defined $@ && $@ =~ /got undefined/),"eval(undef)");

eval { $p->eval(); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "eval()");

eval { $p->eval(1,2); };
ok((defined $@ && $@ =~ /got wrong number of arguments/), "eval(1,2)");

eval { $p->eval([]); };
ok((defined $@ && $@ =~ /is not numeric/),"eval([])");

eval { $p->eval({}); };
ok((defined $@ && $@ =~ /is not numeric/),"eval({})");

eval { $p->eval('abc'); };
ok((defined $@ && $@ =~ /is not numeric/),"eval('abc')");

eval { $p->eval('+-32'); };
ok((defined $@ && $@ =~ /is not numeric/),"eval('+-32')");
