use warnings;
use strict;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author test: RELEASE_TESTING not set" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $pc = Pod::Coverage->new(
    package => 'IPC::Shareable',
    pod_from => 'lib/IPC/Shareable.pm',
    private => [qr/^shlock$/, qr/^shunlock$/, qr/[A-Z]/, qr/^_/],
);

is $pc->coverage, 1, "pod coverage ok";

if ($pc->uncovered){
    warn "Uncovered:\n\t", join( ", ", $pc->uncovered ), "\n";
}

done_testing;

