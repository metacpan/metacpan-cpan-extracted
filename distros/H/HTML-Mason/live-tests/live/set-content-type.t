use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( require_libapreq );

require_libapreq();

Mason::ApacheTest->run_tests(
    apache_define => 'set_content_type',
    with_handler  => 0,
    test_sets     => [qw( set_content_type )],
);
