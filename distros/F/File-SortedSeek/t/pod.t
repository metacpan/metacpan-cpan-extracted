use Test;

#$ENV{RELEASE_TESTING}++;

eval "use Test::Pod 1.00";

if ($@) {
    plan tests => 1;
    skip("Test::Pod 1.00 required for testing POD");
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        my @poddirs = qw(lib ../lib);
        all_pod_files_ok(all_pod_files( @poddirs ));
    }
    else {
        plan tests => 1;
        skip( "Author only private tests" );
    }
}
