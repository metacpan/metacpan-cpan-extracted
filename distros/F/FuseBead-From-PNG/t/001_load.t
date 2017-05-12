# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;

use Test::More;

# ----------------------------------------------------------------------

my $tests = 0;

should_use_modules();

should_require_modules();

should_be_the_module_we_asked_for();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_use_modules {
   use_ok( 'FuseBead::From::PNG' );
   use_ok( 'FuseBead::From::PNG::Bead' );
   use_ok( 'FuseBead::From::PNG::Const' );
   use_ok( 'FuseBead::From::PNG::View' );
   use_ok( 'FuseBead::From::PNG::View::JSON' );
   use_ok( 'FuseBead::From::PNG::View::HTML' );

   $tests += 6;
}

sub should_require_modules {
   require_ok( 'FuseBead::From::PNG' );
   require_ok( 'FuseBead::From::PNG::Bead' );
   require_ok( 'FuseBead::From::PNG::Const' );
   require_ok( 'FuseBead::From::PNG::View' );
   require_ok( 'FuseBead::From::PNG::View::JSON' );
   require_ok( 'FuseBead::From::PNG::View::HTML' );

   $tests += 6;
}

sub should_be_the_module_we_asked_for {
    my $object = FuseBead::From::PNG->new();
    isa_ok ($object, 'FuseBead::From::PNG');

   $tests++;
}

