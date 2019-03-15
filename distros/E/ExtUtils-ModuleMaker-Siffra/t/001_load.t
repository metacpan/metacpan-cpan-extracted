# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'ExtUtils::ModuleMaker::Siffra' ); }

my $object = ExtUtils::ModuleMaker::Siffra->new( NAME => 'Test' );

isa_ok( $object, 'ExtUtils::ModuleMaker::Siffra' );