use strict;
use warnings;

use FindBin qw( $Bin );
use Test::More tests => 1;

use Image::Info;

{
  my $info = Image::Info::image_info("$Bin/../img/no-thumbnail.jpg");
  ok( ! $info->{error}, "no error on bad thumbnail" ) or diag( "Got Error: $info->{error}" );
}
