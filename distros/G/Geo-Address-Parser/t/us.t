use strict;
use warnings;
use Test::More;
use Geo::Address::Parser;

my $parser = Geo::Address::Parser->new(country => 'US');

my $result = $parser->parse('Mastick Senior Center, 1525 Bay St, Alameda, CA 94501');

is($result->{name},    'Mastick Senior Center', 'Name parsed');
is($result->{street},  '1525 Bay St',           'Street parsed');
is($result->{city},    'Alameda',               'City parsed');
is($result->{region},  'CA',                    'Region parsed');
is($result->{zip},     '94501',                 'ZIP parsed');

done_testing();
