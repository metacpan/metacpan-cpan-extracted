
use Test;

plan tests => my $tests = 11;

if( -f 'SKIP_MOST_TESTS' ) {
    warn " git and/or svn missing, skipping mosts tests\n";
    skip(1,1,1) for 1 .. $tests;
    exit 0;
}

die "re-test requires clean" if -d "s7.repo";

ok( system($^X, '-Iblib/lib', "blib/script/git-svn-replay", "-S", "s5.repo", (map {('-s', $_)} qw(dir1 dir2)), "s5.co") => 0 );
ok( -d "s5.co/dir1" );
ok( -d "s5.co/dir2" );

ok( system($^X, '-Iblib/lib', "blib/script/git-svn-replay", "-S", "s7.repo", (map {('-s', $_)} qw(dir1 dir2)), "s7.co") => 0 );
ok( -d "s7.co/.svn" );
ok( -d "s7.co/dir1" );
ok( -d "s7.co/dir2" );

ok( system($^X, '-Iblib/lib', "blib/script/git-svn-replay", "-S", "s7.repo", '-s', 'testdir/yikes/hard/test/recursive', "s7.co") => 0 );
ok( -d "s7.co/testdir/yikes/hard/test/recursive" );

ok( system($^X, '-Iblib/lib', "blib/script/git-svn-replay", "-S", "s7.repo", '-s', 'testdir/yikes/hard/test/recursive/2', "s7.co") => 0 );
ok( -d "s7.co/testdir/yikes/hard/test/recursive/2" );
