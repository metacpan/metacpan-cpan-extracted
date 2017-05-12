use strict;
use warnings;

use FindBin qw( $Bin );
use Test::More tests => 3;

use Image::Info;

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  local $^W = 1;

  my $info = Image::Info::image_info("$Bin/../img/bad-exif-1.jpg");
  ok( ! $info->{error}, "no error on bad EXIF data" ) or diag( "Got Error: $info->{error}" );
  is( join("\n", @{ $info->{resolution} }), "75 dpi\n3314/3306 dpi", "resolution as expected" );

  isnt "@warnings", "", 'seen expected warnings';
}
