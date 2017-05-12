#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
 use_ok( 'Mac::NSGetExecutablePath' );
}

diag( "Testing Mac::NSGetExecutablePath $Mac::NSGetExecutablePath::VERSION, Perl $], $^X" );
