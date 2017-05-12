package HTTP::Easy::Headers;

#use strict;
#use warnings;

BEGIN {
	if (!$NO_XS and eval {require HTTP::Easy::Headers::XS;1}) {
		push @ISA, 'HTTP::Easy::Headers::XS';
	}
	else {
		require HTTP::Easy::Headers::PP;
		push @ISA, 'HTTP::Easy::Headers::PP';
	}
}

1;
