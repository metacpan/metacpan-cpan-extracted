#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use File::Spec::Functions qw(catfile);
use Geo::Location::IP::Database::Reader;

my $asn_reader = new_ok 'Geo::Location::IP::Database::Reader' =>
    [file => catfile(qw(t data Test-ASN.mmdb))];
my $asn_model = $asn_reader->asn(ip => '176.9.54.163');
isa_ok $asn_model, 'Geo::Location::IP::Model::ASN';

my $city_reader = new_ok 'Geo::Location::IP::Database::Reader' =>
    [file => catfile(qw(t data Test-City.mmdb))];
my $city_model = $city_reader->city(ip => '176.9.54.163');
isa_ok $city_model, 'Geo::Location::IP::Model::City';

done_testing;
