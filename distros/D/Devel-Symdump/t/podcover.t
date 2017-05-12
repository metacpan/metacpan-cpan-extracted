# -*- mode: cperl -*-

BEGIN {
    $|++;
    unless ($ENV{AUTHOR_TEST}) {
        $|=1;
        print "1..0 # SKIP test only run when envariable AUTHOR_TEST is set\n";
        eval "require POSIX; 1" and POSIX::_exit(0);
        exit;
    }
}
use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "Devel::Symdump" );
