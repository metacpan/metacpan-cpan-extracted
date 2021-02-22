# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ 'aa', 'ac', 'aba' ],
           xfail => [ 'ab' ],
           type  => 'pcre',
	   match => 'word');
