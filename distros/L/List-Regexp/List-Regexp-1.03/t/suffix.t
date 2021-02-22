# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ 'afoo', 'foo', 'efoo' ],
           xfail => [ 'bfoo' ],
	   re => '\b(?:[ae]?foo)\b',
           type  => 'pcre',
	   match => 'word');

