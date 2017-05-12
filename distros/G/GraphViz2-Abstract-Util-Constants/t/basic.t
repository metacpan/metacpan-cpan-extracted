
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 12/01/13 17:18:48 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test constants are exported and have expected values.

use GraphViz2::Abstract::Util::Constants;

is( EMPTY_STRING,   q[],       'EMPTY STRING' );
is( FALSE,          q[false],  'FALSE' );
is( TRUE,           q[true],   'TRUE' );
is( ${ NONE() },    "none",    'NONE' );
is( ${ UNKNOWN() }, "unknown", 'UNKNOWN' );

done_testing;

