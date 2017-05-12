use strict;
use Data::Dumper;
use Image::Magick;
use Test::More tests => 12;
BEGIN { use_ok('Image::Magick::Iterator') };

ok(open(PPM, 'eg/t.ppm')) or die "couldn't open eg/t.ppm: $!";
ok(my $iter = Image::Magick::Iterator->new());

ok($iter->format('PPM'));
ok($iter->handle(\*PPM));

my $i = 0;
while(my $frame = $iter->next){
  is($frame->Get('width') , 320);
  is($frame->Get('height'), 240);
  $i++;
}

is($i, 3);
