#!perl -Tw

use warnings;
use strict;
use Test::More tests => 3;

use_ok( 'Locale::Maketext' );
use_ok( 'Locale::Maketext::Guts' );
use_ok( 'Locale::Maketext::GutsLoader' );

diag( "Testing Locale::Maketext $Locale::Maketext::VERSION with Perl $], $^X" );
