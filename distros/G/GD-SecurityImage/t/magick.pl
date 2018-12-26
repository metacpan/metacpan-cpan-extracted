use strict;
use warnings;
use vars qw( $MAGICK_SKIP );

BEGIN {
   my $eok = eval {
      require Image::Magick;
      1;
   };
   if ( $@ || ! $eok ) {
      $MAGICK_SKIP  = "You don't have Image::Magick installed. $@";
   }
   else {
      $MAGICK_SKIP = q{};
   }
}

1;
