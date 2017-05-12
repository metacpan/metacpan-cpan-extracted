# -*- perl -*-
use lib 't';
use strict;
use TestRegexp;

my @input = (
    'abab',
    'ac',
    'abba',
    'abbaab',
    'abbaabab',
    'ba',
    'bb',
    'babab',
    );

TestRegexp(input => \@input,
           type  => 'pcre',
	   match => 'word');


    