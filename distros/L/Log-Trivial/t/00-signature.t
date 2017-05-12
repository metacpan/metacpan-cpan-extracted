#   $Id: 00-signature.t,v 1.1 2007-08-07 17:42:58 adam Exp $

use Test::More;

use Test::More;
use strict;

BEGIN {

    if ( $ENV{SKIP_SIGNATURE_TEST} ) {
        plan( skip_all => 'Signature test skipped. Unset $ENV{SKIP_SIGNATURE_TEST} to activate test.' );
    }

    eval ' use Test::Signature; ';

    if ( $@ ) {
        plan( skip_all => 'Test::Signature not installed.' );
    }
    else {
        plan( tests => 1 );
    }
}
signature_ok();
