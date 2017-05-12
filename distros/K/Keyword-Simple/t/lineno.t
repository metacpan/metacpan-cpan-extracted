#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN {
	package Some::Module;
	use Keyword::Simple;
	sub import {
		Keyword::Simple::define 'provided', sub {
			my ($ref) = @_;
			substr($$ref, 0, 0) = 'if';
		};
	}
	sub unimport {
		Keyword::Simple::undefine 'provided';
	}
	$INC{'Some/Module.pm'} = __FILE__;
};

use Some::Module;

provided (1) {
	is(__LINE__, 25);
}

#line 1
provided(1){is __LINE__, 1;}
is __LINE__, 2;

provided
#line 1
(1) { is __LINE__, 1; }
is __LINE__, 2;

provided (2) { provided (3) {
		is __LINE__, 5;
	}
}
