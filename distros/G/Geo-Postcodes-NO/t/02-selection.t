use strict;
use warnings;
use utf8;

use Test::More;

use Geo::Postcodes::NO;

my @all = sort(Geo::Postcodes::NO::get_postcodes());
ok(@all > 5_000, 'bundled postcode table is loaded');
is_deeply([ Geo::Postcodes::NO::selection('all') ], \@all, 'selection all returns sorted postcodes');

is_deeply([ Geo::Postcodes::NO::selection(postcode => '1178') ], ['1178'], 'postcode selection');
is_deeply([ Geo::Postcodes::NO::selection(location => 'oslo', type => 'ST') ],
    [ Geo::Postcodes::NO::selection(location => 'OSLO', type => 'ST') ],
    'selection is case-insensitive');

my @baerum = Geo::Postcodes::NO::selection(borough => 'BÆRUM');
ok(grep { $_ eq '1300' } @baerum, 'UTF-8 selection against borough');

my @svalbard = Geo::Postcodes::NO::selection(county => 'SVALBARD');
ok(grep { $_ eq '9170' } @svalbard, 'county selection');

my @service = Geo::Postcodes::NO::selection(type_verbose => 'Serviceboks');
is_deeply(\@service, [qw(0018 0045 0046 0047)], 'type_verbose selection');

is(Geo::Postcodes::NO::selection('and', postcode => '4%', postcode => '9%'), undef,
    'impossible and-selection returns undef in scalar context');

my @object_selection = Geo::Postcodes::NO->selection(postcode => '1178');
is(scalar @object_selection, 1, 'method selection returns one object');
isa_ok($object_selection[0], 'Geo::Postcodes::NO');
is($object_selection[0]->postcode, '1178', 'selected object has postcode');

my ($status, @modified) = Geo::Postcodes::NO::verify_selectionlist(
    county => 'AKERSHUS',
    'and not',
    borough => 'OSLO',
);
ok($status, 'valid selection list');
is_deeply(\@modified, [county => 'AKERSHUS', 'and not', borough => 'OSLO'], 'selection list is preserved');

($status) = Geo::Postcodes::NO::verify_selectionlist(category => 'G');
ok(!$status, 'unknown selection field rejected');

my @looped;
ok(Geo::Postcodes::NO::selection_loop(sub { push @looped, shift }, postcode => '1178'), 'selection_loop runs');
is_deeply(\@looped, ['1178'], 'selection_loop receives postcode strings');

my @looped_objects;
ok(Geo::Postcodes::NO->selection_loop(sub { push @looped_objects, shift }, postcode => '1178'), 'OO selection_loop runs');
is(scalar @looped_objects, 1, 'OO selection_loop receives one object');
isa_ok($looped_objects[0], 'Geo::Postcodes::NO', 'OO selection_loop passes a postcode object');
is($looped_objects[0]->postcode, '1178', 'OO selection_loop object has postcode');

done_testing;
