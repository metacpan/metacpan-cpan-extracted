use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::en_US::Company';

my $faker    = Faker->new;
my $provider = Faker::Provider::en_US::Company->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->buzzword_type1;
    ok $generated, "buzzword_type1 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->buzzword_type2;
    ok $generated, "buzzword_type2 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->buzzword_type3;
    ok $generated, "buzzword_type3 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->description;
    ok $generated, "description method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->jargon_buzz_word;
    ok $generated, "jargon_buzz_word method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->jargon_edge_word;
    ok $generated, "jargon_edge_word method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->jargon_prop_word;
    ok $generated, "jargon_prop_word method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name;
    ok $generated, "name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->name_suffix;
    ok $generated, "name_suffix method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->tagline;
    ok $generated, "tagline method ok using value $generated";
}

ok 1 and done_testing;
