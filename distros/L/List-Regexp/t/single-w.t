# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ 's' ],
           xfail => [ 's1' ],
           type  => 'pcre',
	   match => 'word');

	   
