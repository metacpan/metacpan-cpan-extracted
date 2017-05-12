use strict;
use FindBin;
use Test::More tests => 5;

BEGIN { use_ok( 'Image::Info' ) }

my @widths = qw/10 10/;

for(0..1) {
    my $info = Image::Info::image_info("$FindBin::Bin/../img/test$_-fuji.jpg");
    is($info->{error}, undef, "No error for test$_-fuji.jpg");
    is($info->{width}, $widths[$_], "Correct width detected");
}
