use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( chmod_data_dir );

Mason::ApacheTest->run_tests(
    apache_define => 'multi_config',
    with_handler  => 0,
    test_sets     => [qw( multi_config )],
);
