use Test::More;

BEGIN {
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}
        and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";

    use_ok('Hash::Merge') || BAIL_OUT("Couldn't load Hash::Merge");
}

diag("Testing Hash::Merge version $Hash::Merge::VERSION, Perl $], $^X");

my $backend = Clone::Choose->backend;

diag( "Using backend $backend version " . $backend->VERSION );

done_testing;
