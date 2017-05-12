#! perl  # Can't run in taint mode

# in a separate test file
use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import();
    1
} or plan( skip_all => 'Test::Kwalitee not installed; skipping' );
