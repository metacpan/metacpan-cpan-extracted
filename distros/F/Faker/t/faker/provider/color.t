use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::Color';

my $faker    = Faker->new;
my $provider = Faker::Provider::Color->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->hex_code;
    ok $generated, "hex_code method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name;
    ok $generated, "name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->rgbcolors;
    ok $generated, "rgbcolors method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->rgbcolors_array;
    ok $generated, "rgbcolors_array method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->rgbcolors_css;
    ok $generated, "rgbcolors_css method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->safe_hex_code;
    ok $generated, "safe_hex_code method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->safe_name;
    ok $generated, "safe_name method ok using value $generated";
}

ok 1 and done_testing;
