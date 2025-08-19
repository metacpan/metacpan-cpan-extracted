use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Geo::Address::Parser') }

my $parser = Geo::Address::Parser->new(country => 'US');
my $result = $parser->parse('Mastick Senior Center, 1525 Bay St, Alameda, CA 94501');

is $result->{name},   'Mastick Senior Center', 'Name parsed';
is $result->{road}, '1525 Bay St',           'Street parsed';
is $result->{city},   'Alameda',               'City parsed';
is($result->{state}, 'CA', 'State parsed');
is $result->{zip},    '94501',                 'ZIP parsed';
is $result->{country}, 'US',                   'Country preserved';

throws_ok(sub { Geo::Address::Parser->new() }, qr/^Usage/, 'Dies with no country');

throws_ok(sub { Geo::Address::Parser->new('country' => 'unknown') }, qr/^Unsupported/, 'Dies with invalid country');

done_testing();
