# -*- perl -*-

# t/003_when_loading_brick_information.t - test loading lego brick information

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use Lego::From::PNG;

use Lego::From::PNG::Const qw(:all);

use Data::Debug;

# ----------------------------------------------------------------------

my $tests = 0;

should_load_color_const_information_as_a_hash();

should_load_all_color_constants();

should_load_lego_dimensions();

should_load_all_brick_dimensions();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_load_color_const_information_as_a_hash {
   my $object = Lego::From::PNG->new();

   cmp_ok(ref($object->lego_colors), 'eq', 'HASH', 'should load color const information as a hash');

   $tests++;
}

sub should_load_all_color_constants {
   my $object = Lego::From::PNG->new();

   my $expected_colors = [ sort ( Lego::From::PNG::Const->LEGO_COLORS ) ];

   my $colors = [ sort keys %{ $object->lego_colors } ];

   is_deeply($colors, $expected_colors, 'should load all color constants');

   $tests++;
}

sub should_load_lego_dimensions {
   my $object = Lego::From::PNG->new();

   my $expected_dim_in_millimeters = {
      lego_unit_length        => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_LENGTH,
      lego_unit_depth         => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_DEPTH,
      lego_unit_height        => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT,
      lego_unit_stud_diameter => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_DIAMETER,
      lego_unit_stud_height   => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT,
      lego_unit_stud_spacing  => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_SPACING,
      lego_unit_edge_to_stud  => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_EDGE_TO_STUD,
   };

   my $expected_dim_in_inches = {
      lego_unit_length        => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_LENGTH * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_depth         => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_DEPTH * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_height        => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_HEIGHT * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_stud_diameter => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_DIAMETER * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_stud_height   => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_HEIGHT * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_stud_spacing  => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_STUD_SPACING * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
      lego_unit_edge_to_stud  => Lego::From::PNG::Const->LEGO_UNIT * Lego::From::PNG::Const->LEGO_UNIT_EDGE_TO_STUD * Lego::From::PNG::Const->MILLIMETER_TO_INCH,
   };

   is_deeply($object->lego_dimensions->{'metric'}, $expected_dim_in_millimeters, 'should load lego brick dimensions in millimeters by default');

   is_deeply($object->lego_dimensions->{'imperial'}, $expected_dim_in_inches, 'should load lego brick dimensions in inches when requested');

   $tests += 2;
}

sub should_load_all_brick_dimensions {
    my $object = Lego::From::PNG->new();

    my $expected_lengths = [ sort ( Lego::From::PNG::Const->LEGO_BRICK_LENGTHS ) ];

    my %seen;
    $seen{ $_->length } = 1 for values %{ $object->lego_bricks };

    my $lengths = [ sort keys %seen ];

    is_deeply($lengths, $expected_lengths, 'should load all brick lengths');

    $tests++;
}
