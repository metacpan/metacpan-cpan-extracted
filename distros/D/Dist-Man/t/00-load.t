#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'Dist::Man' );
use_ok( 'Dist::Man::Simple' );
use_ok( 'Dist::Man::BuilderSet' );
use_ok( 'Dist::Man::Plugin::Template' );

diag( "Testing Dist::Man $Dist::Man::VERSION, Perl $], $^X" );
