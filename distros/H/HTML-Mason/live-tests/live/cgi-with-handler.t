use strict;
use warnings;

use File::Spec;
use lib 'lib', File::Spec->catdir( 't', 'lib' );

use Mason::ApacheTest qw( require_cgi );

require_cgi();

Mason::ApacheTest->run_tests(
    apache_define => 'CGI',
    with_handler  => 1,
    test_sets     => [qw( standard cgi )],
);
