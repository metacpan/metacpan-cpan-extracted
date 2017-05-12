# -*- perl -*-

# t/003_when_loading_bead_information.t - test loading bead information

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use FuseBead::From::PNG;

use FuseBead::From::PNG::Const qw(:all);

use Data::Debug;

# ----------------------------------------------------------------------

my $tests = 0;

should_load_color_const_information_as_a_hash();

should_load_all_color_constants();

should_load_bead_dimensions();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_load_color_const_information_as_a_hash {
   my $object = FuseBead::From::PNG->new();

   cmp_ok(ref($object->bead_colors), 'eq', 'HASH', 'should load color const information as a hash');

   $tests++;
}

sub should_load_all_color_constants {
   my $object = FuseBead::From::PNG->new();

   my $expected_colors = [ sort ( FuseBead::From::PNG::Const->BEAD_COLORS ) ];

   my $colors = [ sort keys %{ $object->bead_colors } ];

   is_deeply($colors, $expected_colors, 'should load all color constants');

   $tests++;
}

sub should_load_bead_dimensions {
   my $object = FuseBead::From::PNG->new();

   my $expected_dim_in_millimeters = {
      bead_diameter => FuseBead::From::PNG::Const->BEAD_DIAMETER,
   };

   my $expected_dim_in_inches = {
      bead_diameter => FuseBead::From::PNG::Const->BEAD_DIAMETER * FuseBead::From::PNG::Const->MILLIMETER_TO_INCH,
   };

   is_deeply($object->bead_dimensions->{'metric'}, $expected_dim_in_millimeters, 'should load bead brick dimensions in millimeters by default');

   is_deeply($object->bead_dimensions->{'imperial'}, $expected_dim_in_inches, 'should load bead brick dimensions in inches when requested');

   $tests += 2;
}
