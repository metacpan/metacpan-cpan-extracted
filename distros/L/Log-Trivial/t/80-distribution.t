#   $Id: 80-distribution.t,v 1.2 2007-08-19 19:57:56 adam Exp $

use Test::More;
use strict;

BEGIN {
    eval ' use Test::Distribution; ';
    if ($@) {
        plan skip_all => 'Test::Distribution not installed';
    }
    else {
        import Test::Distribution;
    }
};
