use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::Company';

my $faker    = Faker->new;
my $provider = Faker::Provider::Company->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->name;
    ok $generated, "name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name_suffix;
    ok $generated, "name_suffix method ok using value $generated";
}

ok 1 and done_testing;
