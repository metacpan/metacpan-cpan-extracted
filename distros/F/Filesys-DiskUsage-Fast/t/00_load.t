#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Filesys::DiskUsage::Fast' ) || print "Bail out!\n";
}

diag( "Testing Filesys::DiskUsage::Fast $Filesys::DiskUsage::Fast::VERSION, Perl $], $^X" );
