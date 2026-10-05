use v5.24;
use warnings;
use Test2::V0;

use Imager;
use Imager::File::SIXEL;

ok((grep { $_ eq 'sixel' } Imager->read_types),  'sixel is a read type');
ok((grep { $_ eq 'sixel' } Imager->write_types), 'sixel is a write type');

is(Imager::File::SIXEL->VERSION, D(), 'module has a version');

done_testing;
