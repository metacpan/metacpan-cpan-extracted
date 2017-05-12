
use Test;

plan tests => my $tests = 4;

if( -f 'SKIP_MOST_TESTS' ) {
    warn " git and/or svn missing, skipping mosts tests\n";
    skip(1,1,1) for 1 .. $tests;
    exit 0;
}

die "re-test requires clean" if -d "s5.repo";

ok( system($^X, '-Iblib/lib', "blib/script/git-svn-replay", "-S", "s5.repo", "s5.co") => 0 );

ok( -d "s5.repo" );
ok( -x "s5.repo/hooks/pre-revprop-change" );
ok( -d "s5.co/.svn" );
