# -*- perl -*-

# t/005_when_getting_png_info.t - test getting various information about the png being converted

use strict;
use warnings;

use lib "t/lib";

use Test::More;

use Test::PNG;

use FuseBead::From::PNG;

use FuseBead::From::PNG::Const qw(:all);

# ----------------------------------------------------------------------

my $tests = 0;

should_return_correct_width();

should_return_correct_height();

should_return_correct_bead_row_length();

should_return_correct_bead_col_height();

done_testing( $tests );

exit;

# ----------------------------------------------------------------------

sub should_return_correct_width {
   my $size = 15;

   my $png = Test::PNG->new({ width => $size, height => $size, unit_size => $size });

   my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $size });

   cmp_ok($object->png_info->{'width'}, '==', $size, 'should return correct width');

   $tests++;
}

sub should_return_correct_height {
   my $size = 10;

   my $png = Test::PNG->new({ width => $size, height => $size, unit_size => $size });

   my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $size });

   cmp_ok($object->png_info->{'height'}, '==', $size, 'should return correct height');

   $tests++;
}

sub should_return_correct_bead_row_length {
   my ($width, $height, $unit_size) = ( 1024, 16, 16 );

   my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

   my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

   cmp_ok($object->bead_row_length, '==', $width / $unit_size, 'should return correct bead row width');

   $tests++;
}

sub should_return_correct_bead_col_height {
   my ($width, $height, $unit_size) = ( 1024, 16, 16 );

   my $png = Test::PNG->new({ width => $width, height => $height, unit_size => $unit_size });

   my $object = FuseBead::From::PNG->new({ filename => $png->filename, unit_size => $unit_size });

   cmp_ok($object->bead_col_height, '==', $height / $unit_size, 'should return correct bead col height');

   $tests++;
}
