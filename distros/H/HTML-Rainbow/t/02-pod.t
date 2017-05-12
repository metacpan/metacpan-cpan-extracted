# 00-basic.t
#
# Test suite for HTML::Rainbow
# Make sure the basic stuff works
#
# copyright (C) 2005-2009 David Landgren

use strict;
use Test::More;

use HTML::Rainbow;

if (!$ENV{PERL_AUTHOR_TESTING}) {
    plan skip_all => 'PERL_AUTHOR_TESTING environment variable not set (or zero)';
    exit;
}

my %tests = (
    POD          => 3,
    POD_COVERAGE => 1,
);
my %tests_skip = %tests;

eval "use Test::Pod";
$@ and delete $tests{POD};

eval "use Test::Pod::Coverage";
$@ and delete $tests{POD_COVERAGE};

if (keys %tests) {
    my $nr = 0;
    $nr += $_ for values %tests;
    plan tests => $nr;
}
else {
    plan skip_all => 'POD testing modules not installed';
}

SKIP: {
    skip( 'Test::Pod not installed on this system', $tests_skip{POD} )
        unless $tests{POD};
    pod_file_ok( 'Rainbow.pm' );
    pod_file_ok( 'eg/rainbow.pl' );
    pod_file_ok( 'eg/html-parse' );
}

SKIP: {
    skip( 'Test::Pod::Coverage not installed on this system', $tests_skip{POD_COVERAGE} )
        unless $tests{POD_COVERAGE};
    pod_coverage_ok( 'HTML::Rainbow', 'POD coverage is go!' );
};

