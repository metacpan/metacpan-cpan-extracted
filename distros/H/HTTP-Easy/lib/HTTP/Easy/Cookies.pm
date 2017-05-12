package HTTP::Easy::Cookies;

#use strict;
#use warnings;

BEGIN {
	if (!$NO_XS and eval {require HTTP::Easy::Cookies::XS;1}) {
		push @ISA, 'HTTP::Easy::Cookies::XS';
	}
	else {
		require HTTP::Easy::Cookies::PP;
		push @ISA, 'HTTP::Easy::Cookies::PP';
	}
}

1;
