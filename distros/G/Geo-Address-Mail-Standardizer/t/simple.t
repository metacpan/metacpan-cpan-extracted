use Test::More;
use lib qw(t/lib);

use Geo::Address::Mail::US;
use MyStandardizer;

my $addr = Geo::Address::Mail::US->new(
    street => '123 Main Street',
    city   => 'Testville',
    state => 'TN'
);

my $std = MyStandardizer->new;
my $results = $std->standardize($addr);
isa_ok($results, 'Geo::Address::Mail::Standardizer::Results', 'got results');
cmp_ok($results->standardized_address->street, 'eq', '123 Main ST', 'standardized street');
cmp_ok($results->changed_count, '==', 1, 'changed_count');
cmp_ok($results->get_changed('street'), 'eq', '123 Main ST', 'get_changed');

done_testing;