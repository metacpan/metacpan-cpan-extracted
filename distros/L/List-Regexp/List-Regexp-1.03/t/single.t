# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ 's' ],
           match => [ 's1', 'asa' ], 
           xfail => [ 'a' ],
           type  => 'pcre',
	   match => 'word');
	   
