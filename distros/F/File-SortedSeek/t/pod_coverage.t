use Test;
use Cwd;

my $ALSO_PRIVATE = [ 'set_max_tries', 'set_line_length' ];

#$ENV{RELEASE_TESTING}++;

my $chdir = 0;  # Test::Pod::Coverage is brain dead and won't find
                # lib or blib when run from t/, nor can you tell it
                # where to look
if ( cwd() =~ m/t$/ ) {
    chdir "..";
    $chdir++;
}

eval "use Test::Pod::Coverage 1.00";

if ($@) {
    plan tests => 1;
    skip("Test::Pod::Coverage 1.00 required for testing POD");
}
else {
    if ( $ENV{RELEASE_TESTING} ) {
        all_pod_coverage_ok( { also_private => $ALSO_PRIVATE } );
    }
    else {
        plan tests => 1;
        skip( "Author only private tests" );
    }
}

chdir "t" if $chdir;  # back to t/