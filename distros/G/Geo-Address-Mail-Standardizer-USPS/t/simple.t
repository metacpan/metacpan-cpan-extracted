use Test::More;
use strict;

use Geo::Address::Mail::US;
use Geo::Address::Mail::Standardizer::USPS;

my $std = Geo::Address::Mail::Standardizer::USPS->new;

my $address = Geo::Address::Mail::US->new(
    name => 'Test Testerson',
    street => '123 Test Street',
    street2 => 'Apartment #2',
    city => 'Testville',
    state => 'TN',
    postal_code => '12345'
);

my $res = $std->standardize($address);
my $corr = $res->standardized_address;
cmp_ok($corr->name, 'eq', 'TEST TESTERSON', 'uppercase name');
cmp_ok($res->changed_count, '==', 3, '3 change(s)');
cmp_ok($res->standardized_address->street2, 'eq', 'APT #2', 'apt2');

done_testing;