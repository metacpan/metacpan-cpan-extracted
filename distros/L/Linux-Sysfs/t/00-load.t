#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Linux::Sysfs' );
}

diag( "Testing Linux::Sysfs $Linux::Sysfs::VERSION, Perl $], $^X" );
