#    $Id: 92-pod.t,v 1.2 2007-08-07 17:42:58 adam Exp $

use strict;
use Test::More;

BEGIN {
    eval ' use Test::Pod::Coverage 1.04; ';
    if ($@) {
        plan( skip_all => 'Test::Pod::Coverage 1.04+ not installed.');
    }
}

all_pod_coverage_ok();
