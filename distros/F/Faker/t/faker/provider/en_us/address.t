use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::en_US::Address';

my $faker    = Faker->new;
my $provider = Faker::Provider::en_US::Address->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->city_name;
    ok $generated, "city_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->city_prefix;
    ok $generated, "city_prefix method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->city_suffix;
    ok $generated, "city_suffix method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->country_name;
    ok $generated, "country_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->latitude;
    ok $generated, "latitude method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->line1;
    ok $generated, "line1 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->line2;
    ok $generated, "line2 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->lines;
    ok $generated, "lines method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->longitude;
    ok $generated, "longitude method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->number;
    ok $generated, "number method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->postal_code;
    ok $generated, "postal_code method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->state_abbr;
    ok $generated, "state_abbr method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->state_name;
    ok $generated, "state_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->street_name;
    ok $generated, "street_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->street_suffix;
    ok $generated, "street_suffix method ok using value $generated";
}

ok 1 and done_testing;
