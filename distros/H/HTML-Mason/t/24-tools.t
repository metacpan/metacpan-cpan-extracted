use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 1;


use HTML::Mason::Tools ();

eval { HTML::Mason::Tools::load_pkg( 'LoadTest', 'Required package.' ) };
like( $@, qr/Can't locate Does.Not.Exist/ );
