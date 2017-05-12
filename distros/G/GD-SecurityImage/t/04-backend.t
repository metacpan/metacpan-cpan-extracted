#!/usr/bin/env perl -w
use strict;
use warnings;
use vars qw( $MAGICK_SKIP );
use Test::More;
use Cwd;
use Carp qw( croak );
use lib  qw( .. );

BEGIN {
   do 't/magick.pl' || croak "Can not include t/magick.pl: $!";

   my %total = (
      magick => 2,
      gd     => 2,
      other  => 1,
   );

   my $total  = 0;
      $total += $total{$_} foreach keys %total;
   my $class  = 'GD::SecurityImage';

   plan tests => $total;

   require GD::SecurityImage;

   my $eok = eval { $class->new };
   ok( $@, q{If there is an error == OK [since we didn't import() so far]} );

   # test if we've loaded the right library
   GD_TEST: {
      $class->import( use_magick => 0 );
      ok( $class->new->raw->isa('GD::Image' ), 'Loaded GD [1]' );
      $class->import( backend => 'GD' );
      ok( $class->new->raw->isa('GD::Image' ), 'Loaded GD [2]' );
   }

   SKIP: {
      if ( $MAGICK_SKIP ) {
         skip( $MAGICK_SKIP . ' Skipping...', $total{magick} );
      }
      $class->import( use_magick => 1        );
      ok( $class->new->raw->isa('Image::Magick'), 'Loaded Magick [1]' );
      $class->import( backend    => 'Magick' );
      ok( $class->new->raw->isa('Image::Magick'), 'Loaded Magick [2]' );
   }
}
