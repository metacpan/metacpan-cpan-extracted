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
    package  => 'IPC::Shareable',
    pod_from => 'lib/IPC/Shareable.pm',
    private  => [ qr/^shlock$/, qr/^shunlock$/, qr/[A-Z]/, qr/^_/, qr/^bootstrap$/ ],
);

is $pc->coverage, 1, "IPC::Shareable pod coverage ok";

if ($pc->uncovered){
    warn "IPC::Shareable uncovered:\n\t", join( ", ", $pc->uncovered ), "\n";
}

my $pc_shm = Pod::Coverage->new(
    package => 'IPC::Shareable::SharedMem',
    pod_from => 'lib/IPC/Shareable/SharedMem.pm',
    private  => [qr/^_/],
);

is $pc_shm->coverage, 1, "IPC::Shareable::SharedMem pod coverage ok";

if ($pc_shm->uncovered){
    warn "IPC::Shareable::SharedMem uncovered:\n\t", join( ", ", $pc_shm->uncovered ), "\n";
}

done_testing;

