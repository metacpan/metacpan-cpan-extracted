#!perl -w

use strict;
use Test::More tests => 2;

my $warn = '';
local $SIG{__WARN__} = sub{ $warn .= "@_" };
eval q{
	package A;
	use parent qw(Method::Cumulative);

	sub foo :CUMULATIVE{}

	package B;
	use parent -norequire => 'A';
	sub foo :CUMULATIVE(BASE FIRST){}
};

like $warn, qr/Conflicting definitions for cumulative method B::foo/ or diag $warn;

$warn = '';
eval q{
	package A;
	use parent qw(Method::Cumulative);

	sub bar :CUMULATIVE(BASE FIRST){}

	package B;
	use parent -norequire => 'A';
	sub bar :CUMULATIVE{}
};

like $warn, qr/Conflicting definitions for cumulative method B::bar/ or diag $warn;
