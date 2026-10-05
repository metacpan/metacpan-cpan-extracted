use v5.24;
use warnings;
use Test2::V0;

# Imager::File::SIXEL is deliberately not loaded here: Imager loads it
# on demand when the type is given explicitly.
use Imager;

ok(!$INC{'Imager/File/SIXEL.pm'}, 'the module is not loaded at first');

my $img = Imager->new;
ok($img->read(data => "\ePq#1;2;100;0;0~\e\\", type => 'sixel'), 'read with an explicit type')
	or diag($img->errstr);
ok($INC{'Imager/File/SIXEL.pm'}, 'the module was loaded on demand');

done_testing;
