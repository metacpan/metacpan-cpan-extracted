use v5.24;
use warnings;
use Test2::V0;

# Imager::File::SIXEL is deliberately not loaded here: Imager loads it
# on demand when the type is given explicitly.
use Imager;

ok(!$INC{'Imager/File/SIXEL.pm'}, 'the module is not loaded at first');

my $img = Imager->new(xsize => 2, ysize => 2);
my $data = '';
ok($img->write(data => \$data, type => 'sixel'), 'write with an explicit type') or diag($img->errstr);
like($data, qr/\A\eP/, 'SIXEL data written');
ok($INC{'Imager/File/SIXEL.pm'}, 'the module was loaded on demand');

done_testing;
