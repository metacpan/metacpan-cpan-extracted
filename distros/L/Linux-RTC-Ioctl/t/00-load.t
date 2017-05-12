#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

# plan tests => 1;

BEGIN {
    use_ok( 'Linux::RTC::Ioctl' ) || print "Bail out!\n";
}

diag( "Testing Linux::RTC::Ioctl $Linux::RTC::Ioctl::VERSION, Perl $], $^X" );
