#!/use/bin/perl -w

use strict;
use Test::More;
BEGIN {
	my $add = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; ++$add; 1 }
		or diag "Test::NoWarnings missed, skipping no warnings test";
	plan tests => 6 + $add;
	eval {require Data::Dumper;Data::Dumper::Dumper(1)}
		and *dd = sub ($) { Data::Dumper->new([$_[0]])->Indent(0)->Terse(1)->Quotekeys(0)->Useqq(1)->Purity(1)->Dump }
		or  *dd = \&explain;
}

use Devel::Hexdump;

is
    xd("\0", { row => 2, cols => 1, hpad => 0, cpad=>1, hsp=>0, csp=>0,  }),
    "[0000]   00   .     \n"
;

is
    xd("\0"x2, { row => 2, cols => 1, hpad => 0, cpad=>1, hsp=>0, csp=>0,  }),
    "[0000]   0000  . . \n"
;

is
    xd("\0"x4, { row => 2, cols => 1, hpad => 0, cpad=>1, hsp=>0, csp=>0,  }),
    "[0000]   0000  . . \n".
    "[0002]   0000  . . \n"
;

is
    xd("\1\2\3\4", { row => 2, cols => 1, hpad => 0, cpad=>1, hsp=>0, csp=>0,  }),
    "[0000]   0102  . . \n".
    "[0002]   0304  . . \n"
;

is
    xd("\1\2\3\4", { row => 2, cols => 2, hpad => 1, cpad=>0, hsp=>0, csp=>0,  }),
    "[0000]   01 02   ..\n".
    "[0002]   03 04   ..\n"
;

is
    xd("\1\2\3\4", { row => 4, cols => 2, hpad => 0, cpad=>0, hsp=>2, csp=>1,  }),
    "[0000]   0102  0304  .. ..\n"
;

