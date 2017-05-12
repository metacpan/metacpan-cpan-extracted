use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use Geo::Coordinates::Converter::iArea;
use Encode ();

my $name = Geo::Coordinates::Converter::iArea->get_name('05905');
is($name, '広尾/白金');
ok(Encode::is_utf8($name), 'decoded utf8');

