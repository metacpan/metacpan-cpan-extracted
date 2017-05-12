use Test::More;

use_ok 'Faker';
use_ok 'Faker::Provider::Lorem';

my $faker    = Faker->new;
my $provider = Faker::Provider::Lorem->new(factory => $faker);

ok $provider->does($_) for qw(
    Faker::Role::Data
    Faker::Role::Format
    Faker::Role::Process
    Faker::Role::Random
);

for (1..50) {
    my $generated = $provider->paragraph;
    ok $generated, "paragraph method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->paragraphs;
    ok $generated, "paragraphs method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->sentence;
    ok $generated, "sentence method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->sentences;
    ok $generated, "sentences method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->word;
    ok $generated, "word method ok using value $generated";
}
for (1..50) {
    my $generated = $provider->words;
    ok $generated, "words method ok using value $generated";
}

ok 1 and done_testing;
