use Test::More;

use_ok 'Faker';

my $faker = Faker->new;

can_ok $faker, qw(locale namespace provider);

isa_ok $faker->provider('Address'),    'Faker::Provider::en_US::Address';
isa_ok $faker->provider('Company'),    'Faker::Provider::en_US::Company';
isa_ok $faker->provider('Person'),     'Faker::Provider::en_US::Person';
isa_ok $faker->provider('Telephone'),  'Faker::Provider::en_US::Telephone';

ok 1 and done_testing;
