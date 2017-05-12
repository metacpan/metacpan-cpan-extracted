use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( require_libapreq );

require_libapreq();

Mason::ApacheTest->run_tests(
    apache_define => 'mod_perl_no_handler',
    with_handler  => 0,
    test_sets     => [qw( standard apache_request )],
);
