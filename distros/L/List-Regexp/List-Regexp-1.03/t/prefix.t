# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

TestRegexp(input => [ 'afoo', 'afquz', 'afbar' ],
           xfail => [ 'afbarba' ],
           type  => 'pcre',
	   match => 'word');
