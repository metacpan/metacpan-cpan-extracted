use strict;
use warnings;
use Test::More;
use Geo::Address::Parser;

my $parser = Geo::Address::Parser->new(country => 'NZ');
my $result = $parser->parse('Auckland Museum, 1 Museum Circuit, Parnell, Auckland 1010');

is $result->{name},     'Auckland Museum',      'Name parsed';
is $result->{street},   '1 Museum Circuit',     'Street parsed';
is $result->{suburb},   'Parnell',              'Suburb parsed';
is $result->{city},     'Auckland',             'City parsed';
is $result->{postcode}, '1010',                 'Postcode parsed';

done_testing();
