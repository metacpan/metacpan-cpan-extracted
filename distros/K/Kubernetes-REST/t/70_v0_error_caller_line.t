#!/usr/bin/env perl
# karr k67: an error from a call through the v0 compatibility layer names the
# caller's line, not V0Group.pm.
#
# The v0 wrapper's AUTOLOAD dispatches to list/get/update/... in
# Kubernetes::REST, and an APIError thrown there (or a plain croak) reported
# the line inside V0Group's _dispatch, because Carp did not trust V0Group.
# V0Group now trusts Kubernetes::REST through @CARP_NOT, so Carp walks past
# both packages and blames the code that made the v0 call.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

sub api {
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::Kubernetes::Mock::IO->new,
    );
}

# Runs $code (which returns the line it made the v0 call on) and checks the
# error it dies with names that line, once.
sub dies_at_caller {
    my ($what, $code) = @_;
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $line = $code->(api());
    my $err  = $@;
    ok($err, "$what: died");
    like("$err", qr/ at \Q$0\E line $line\.\n\z/, "$what: at the caller's line");
    is(scalar(() = "$err" =~ / at \S+ line \d+\./g), 1, "$what: with one location");
    unlike("$err", qr/V0Group\.pm/, "$what: does not name V0Group.pm");
}

subtest 'a 404 through a v0 read' => sub {
    dies_at_caller('ReadNamespacedPod', sub { my $api = shift;
        my $line = __LINE__; eval { $api->Core->ReadNamespacedPod(
            name => 'nope', namespace => 'default') }; $line });
};

subtest 'a 404 through a v0 list' => sub {
    # The mock 404s a missing fixture, and a list of a resource the mock does
    # not serve throws an APIError like any other checked response.
    dies_at_caller('ListNamespacedPod', sub { my $api = shift;
        $api->io->responses->{no_such} = undef;    # keep the fixture map empty
        my $line = __LINE__; eval { $api->Core->ListNamespacedPod(
            namespace => 'nope') }; $line });
};

subtest 'the thrown value is still an APIError' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    eval { $api->Core->ReadNamespacedPod(name => 'nope', namespace => 'default') };
    my $err = $@;
    isa_ok($err, 'Kubernetes::REST::APIError', 'the error');
    ok($err->is_not_found, 'is_not_found');
};

done_testing;
