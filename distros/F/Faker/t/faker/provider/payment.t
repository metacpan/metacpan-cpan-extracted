use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::Payment';

my $faker    = Faker->new;
my $provider = Faker::Provider::Payment->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->card_expiration;
    ok $generated, "card_expiration method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->card_number;
    ok $generated, "card_number method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->vendor;
    ok $generated, "vendor method ok using value $generated";
}

ok 1 and done_testing;
