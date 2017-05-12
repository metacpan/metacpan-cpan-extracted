# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ '[', '-', ']', 'a', 'e', 'b', 'c' ],
           re => '[][a-ce-]',
           type  => 'pcre',
	   match => 'default');

