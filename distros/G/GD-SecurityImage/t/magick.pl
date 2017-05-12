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
   elsif ( $Image::Magick::VERSION lt '6.0.4') {
      $MAGICK_SKIP = q{There may be a bug in your PerlMagick version's }
                   . "($Image::Magick::VERSION) QueryFontMetrics() method. "
                   . q{Please upgrade to 6.0.4 or newer.};
   }
   else {
      $MAGICK_SKIP = q{};
   }
}

1;
