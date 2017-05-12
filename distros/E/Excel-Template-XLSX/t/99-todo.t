use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 1;

TODO: {
   local $TODO = qq[
   Images in the Sheet
   Images in Headers/Footers
   Charts
   Shapes
   Themes (gradients, fonts, fills, styles)
   macros
   modules (vba code)
   show/hide gridlines
   print_row_col_headers()
   set_custom_color( index, red, green, blue )
   data_validation
   conditional_formatting
   gradient fills
   TRUE/FALSE values (converted to string)

   ];

   ok( 0, 'Content/Testing not Created' );
}

__DATA__
