use warnings;
use strict;

use Test::More tests => 12;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

require Lexical::Var;

sub test_case($) {
	my $result = eval($_[0]);
	my $err = $@;
	if($err eq "") {
		is $result, 123;
	} else {
		like $err, qr/\Acan't set up lexical /;
	}
}

test_case q{
	use Lexical::Var '$t1' => \123;
	$t1;
};

test_case q{
	BEGIN { "Lexical::Var"->import('$t2' => \123); }
	$t2;
};

test_case q{
	BEGIN {
		require Lexical::Sub;
		"Lexical::Var"->import('$t3' => \123);
	}
	$t3;
};

test_case q{
	BEGIN { do "t/setup_s_4.pm"; die $@ if $@; }
	$t4;
};

test_case q{
	BEGIN { require t::setup_s_5; }
	$t5;
};

test_case q{
	use t::setup_s_6;
	$t6;
};

test_case q{
	use t::setup_s_7;
	$t7;
};

test_case q{
	BEGIN { sub{ "Lexical::Var"->import('$t8' => \123); }->(); }
	$t8;
};

test_case q{
	BEGIN {
		sub {
			my $n = 123;
			sub{ "Lexical::Var"->import('$t9' => \$n); };
		}->()->();
	}
	$t9;
};

sub ts10() { "Lexical::Var"->import('$t10' => \123); }
test_case q{
	BEGIN { ts10(); }
	$t10;
};

test_case q{
	BEGIN {
		eval q{"x"}; die $@ if $@;
		"Lexical::Var"->import('$t11' => \123);
	}
	$t11;
};

test_case q{
	BEGIN {
		eval q{ "Lexical::Var"->import('$t12' => \123); };
		die $@ if $@;
	}
	$t12;
};

1;
