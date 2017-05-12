#    $Id: 91-pod.t,v 1.2 2007-08-06 21:49:56 adam Exp $

use strict;
use Test::More;

BEGIN {
    eval ' use Pod::Coverage; ';

    if ($@) {
        plan( skip_all => 'Pod::Coverage not installled.' );
    }
    else {
        plan( tests => 1 );
    }
}

my $pc = Pod::Coverage->new(package => 'Log::Trivial');
ok($pc->coverage == 1);
