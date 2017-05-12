use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::Internet';

my $faker    = Faker->new;
my $provider = Faker::Provider::Internet->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->domain_name;
    ok $generated, "domain_name method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->domain_word;
    ok $generated, "domain_word method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->email_address;
    ok $generated, "email_address method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->email_domain;
    ok $generated, "email_domain method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->ip_address;
    ok $generated, "ip_address method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->ip_address_v4;
    ok $generated, "ip_address_v4 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->ip_address_v6;
    ok $generated, "ip_address_v6 method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->root_domain;
    ok $generated, "root_domain method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->url;
    ok $generated, "url method ok using value $generated";
}

ok 1 and done_testing;
