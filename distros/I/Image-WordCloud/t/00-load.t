use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Image::WordCloud' ) || print "Bail out!\n";
}

diag( "Testing Image::WordCloud $Image::WordCloud::VERSION, Perl $], $^X" );
