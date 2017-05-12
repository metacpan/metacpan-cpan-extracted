use Test::More;

if (not defined $ENV{AUTHOR_MODE}) {
    plan(skip_all => 'Skipping Test::Kwalitee - author mode only');
}
eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
