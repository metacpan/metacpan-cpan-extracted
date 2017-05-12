use Test::More;

use lib 't/lib';

use Geo::Address::Mail::US;

my $usaddr = Geo::Address::Mail::US->new(
    name => 'Cory Watson', postal_code => '12345'
);

cmp_ok($usaddr->standardize('Mock'), 'eq', 'hello!', 'loaded relative class');

cmp_ok($usaddr->standardize('+MyStandardizer'), 'eq', 'hello!', 'loaded fully qualified class');

done_testing;