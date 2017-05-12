#    $Id: 00-use.t,v 1.3 2007-08-20 15:43:40 adam Exp $

use strict;
use Test::More tests => 1;
use Log::Trivial;

BEGIN { use_ok( 'Log::Trivial' ); };
