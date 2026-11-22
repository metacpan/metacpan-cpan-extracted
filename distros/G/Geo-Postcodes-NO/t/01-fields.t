use strict;
use warnings;
use utf8;

use Test::More;

use Geo::Postcodes::NO;

my @fields = qw(postcode location borough borough_number county type type_verbose);

is_deeply([ Geo::Postcodes::NO::get_fields() ], \@fields, 'procedural fields');
is_deeply([ Geo::Postcodes::NO->get_fields() ], \@fields, 'method fields');

for my $field (@fields) {
    ok(Geo::Postcodes::NO::is_field($field), "$field is a field as procedure");
    ok(Geo::Postcodes::NO->is_field($field), "$field is a field as method");
}

ok(!Geo::Postcodes::NO::is_field('category'), 'raw Bring category is not a legacy selection field');
ok(!Geo::Postcodes::NO->is_field('elephant'), 'unknown field rejected');

is(Geo::Postcodes::NO::type2verbose('STBX'), 'Både gateadresse og postboks', 'Norwegian type2verbose');
is(Geo::Postcodes::NO::type2verbose_english('STBX'), 'Street Address and Post Office box', 'English type2verbose');

my @types = Geo::Postcodes::NO::get_types();
ok(grep { $_ eq 'ST' } @types, 'get_types includes ST');
ok(grep { $_ eq 'STBX' } @types, 'get_types includes STBX');

done_testing;
