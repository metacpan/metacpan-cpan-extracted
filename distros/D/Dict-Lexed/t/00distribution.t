#!/usr/bin/perl
# $Id: 00distribution.t,v 1.1 2005/05/02 16:06:13 rousse Exp $

use Test::More;

BEGIN {
    eval {
	require Test::Distribution;
    };
    if($@) {
	plan skip_all => 'Test::Distribution not installed';
    } else {
	import Test::Distribution not => 'versions';
    }
}
