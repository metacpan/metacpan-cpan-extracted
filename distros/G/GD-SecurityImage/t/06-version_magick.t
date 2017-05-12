#!/usr/bin/env perl -w
use strict;
use warnings;
use vars qw( $MAGICK_SKIP );
use Test::More;
use Cwd;
use Carp qw( croak );
use lib  qw( .. );
use constant TOTAL_TESTS => 6;

BEGIN {
   do 't/magick.pl' || croak "Can not include t/magick.pl: $!";

   plan tests => TOTAL_TESTS;

   SKIP: {
      if ( $MAGICK_SKIP ) {
         skip( $MAGICK_SKIP . ' Skipping...', TOTAL_TESTS );
      }
      require GD::SecurityImage;
      GD::SecurityImage->import( use_magick => 1 );
   }
}

exit if $MAGICK_SKIP;

my $i = GD::SecurityImage->new;

my $gt = $i->_versiongt('6.0');
my $lt = $i->_versionlt('6.4.3');
ok( defined $gt, 'GT defined' );
ok( defined $lt, 'LT defined' );

GT: {
   local $Image::Magick::VERSION = '6.0.3';
   ok( $i->_versiongt( '6.0'   ), 'GT 6.0'   );
   ok( $i->_versiongt( '6.0.3' ), 'GT 6.0.3' );
   ok( $i->_versionlt( '6.2'   ), 'LT 6.2'   );
   ok( $i->_versionlt( '6.2.6' ), 'LT 6.2.6' );
}
