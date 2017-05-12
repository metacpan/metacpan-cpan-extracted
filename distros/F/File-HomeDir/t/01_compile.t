#!/usr/bin/perl

# Compile-testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';

use Test::More tests => 11;

# This module is destined for the core.
# Please do NOT use convenience modules
# use English; <-- don't do this

ok( $] > 5.00503, 'Perl version is 5.005 or newer' );

use_ok( 'File::HomeDir::Driver'         );
use_ok( 'File::HomeDir::Unix'           );
use_ok( 'File::HomeDir::FreeDesktop'    );
use_ok( 'File::HomeDir::Darwin'         );
use_ok( 'File::HomeDir::Darwin::Carbon' );
use_ok( 'File::HomeDir::Darwin::Cocoa'  );
use_ok( 'File::HomeDir::Windows'        );
use_ok( 'File::HomeDir::MacOS9'         );
use_ok( 'File::HomeDir'                 );

ok( defined &home, 'Using File::HomeDir exports home()' );

# Note the driver we are using for the purposes of
# understanding CPAN Testers failure reports.
diag( "Implemented by: $File::HomeDir::IMPLEMENTED_BY" );

# Prevent a warning
$File::HomeDir::IMPLEMENTED_BY = $File::HomeDir::IMPLEMENTED_BY;
