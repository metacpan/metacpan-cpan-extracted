use Test::More;

if ( not $ENV{GETOPTLL_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{GETOPTLL_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
