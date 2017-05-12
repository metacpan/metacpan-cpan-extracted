use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( require_libapreq require_apache_filter );

require_libapreq();
require_apache_filter();

Mason::ApacheTest->run_tests(
    apache_define => 'filter_tests',
    with_handler  => 0,
    test_sets     => [qw( filter )],
);
