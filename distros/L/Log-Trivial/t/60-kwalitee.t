#   $Id: 60-kwalitee.t,v 1.1 2007-08-07 17:42:58 adam Exp $

use strict;
use Test::More;

BEGIN {
    eval { require Test::Kwalitee; };
    if ($@) {
        plan skip_all => 'Test::Kwalitee not installed';
    }
    else {
        Test::Kwalitee->import();
    }
};
