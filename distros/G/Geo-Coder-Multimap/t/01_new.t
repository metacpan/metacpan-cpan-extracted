use strict;
use warnings;
use Test::More tests => 2;
use Geo::Coder::Multimap;

my $geo = Geo::Coder::Multimap->new(apikey => 'placeholder');
isa_ok($geo, 'Geo::Coder::Multimap', 'new');
can_ok('Geo::Coder::Multimap', qw(geocode ua));
