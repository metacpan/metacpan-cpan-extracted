use strict;
use Test::More tests => 12;

use Geo::Hex::V3::XS;

my $geohex = Geo::Hex::V3::XS->new(code => 'OL3371');
my @locations = $geohex->polygon();
like $locations[0]{lat}, qr/^-45\.47775038345/;
like $locations[0]{lng}, qr/^49\.46502057613/;
like $locations[1]{lat}, qr/^-45\.47775038345/;
like $locations[1]{lng}, qr/^49\.30041152263/;
like $locations[2]{lat}, qr/^-45\.37770368915/;
like $locations[2]{lng}, qr/^49\.54732510288/;
like $locations[3]{lat}, qr/^-45\.37770368915/;
like $locations[3]{lng}, qr/^49\.21810699588/;
like $locations[4]{lat}, qr/^-45\.27747966662/;
like $locations[4]{lng}, qr/^49\.46502057613/;
like $locations[5]{lat}, qr/^-45\.27747966662/;
like $locations[5]{lng}, qr/^49\.30041152263/;

