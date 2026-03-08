use strict;
use warnings;

use utf8;
use Test::Most;
use Geo::Address::Parser;

# Initialize the parser with the France module
my $parser = Geo::Address::Parser->new(country => 'FR');

# Test Case 1: Standard French address with postcode
my $data = 'l\'église Sainte-Bernadette, 14 Rue Paul Painlevé, 69300 Caluire-et-Cuire';
my $result = $parser->parse($data);

ok(defined $result, 'Parsed address result exists');
is($result->{name}, 'L\'Église Sainte-Bernadette', 'Name capitalized and parsed');
is($result->{street}, '14 Rue Paul Painlevé', 'Street parsed');
is($result->{city}, 'Caluire-et-Cuire', 'City parsed');
is($result->{postcode}, '69300', 'Postcode parsed');
is($result->{country}, 'FR', 'Country set correctly');

$data = 'l\'église Sainte-Bernadette, 14 Rue Paul Painlevé, Caluire-et-Cuire, France';
is($result->{name}, 'L\'Église Sainte-Bernadette', 'Name capitalized and parsed');
is($result->{street}, '14 Rue Paul Painlevé', 'Street parsed');
is($result->{city}, 'Caluire-et-Cuire', 'City parsed');
is($result->{country}, 'FR', 'Country set correctly');

# Test Case 2: Minimal address
my $simple = 'Mairie, 75001 Paris';
my $res_simple = $parser->parse($simple);

is($res_simple->{city}, 'Paris', 'City parsed from minimal address');
is($res_simple->{postcode}, '75001', 'Postcode parsed from minimal address');

done_testing();
