use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::en_US::Person';

my $faker    = Faker->new;
my $provider = Faker::Provider::en_US::Person->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->first_name;
    ok $generated, "first_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->last_name;
    ok $generated, "last_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name;
    ok $generated, "name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name_prefix;
    ok $generated, "name_prefix method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name_suffix;
    ok $generated, "name_suffix method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->username;
    ok $generated, "username method ok using value $generated";
}

ok 1 and done_testing;
