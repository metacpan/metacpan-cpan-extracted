#    $Id: 90-pod.t,v 1.3 2007-08-20 15:45:00 adam Exp $

use strict;
use Test::More;

BEGIN {
    eval ' use Test::Pod; ';

    if ($@) {
        plan( skip_all => 'Test::Pod not installled.' );
    }
    else {
        plan( tests => 1 );
    }
}

pod_file_ok("./lib/Log/Trivial.pm",                 'Valid POD file' );
