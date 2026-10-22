#!/usr/bin/env perl
# In-cluster configuration builds "https://$host:$port" from the
# KUBERNETES_SERVICE_HOST/PORT variables the kubelet injects. An IPv6 literal
# (an IPv6-only or dual-stack cluster) contains ':' and must be bracketed in
# the URL, else the endpoint parses as a different host and port. Nothing here
# reached this path before: it checks -f on a fixed /var/run/secrets/... path.
#
# The test relies on the package variables $SA_TOKEN and $SA_CA in
# Kubernetes::REST::Kubeconfig, which it localises to a temporary token.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
path("$tmpdir/token")->spew_raw("sa-token\n");
path("$tmpdir/ca.crt")->spew_raw("FAKECA\n");

no warnings "once";
local $Kubernetes::REST::Kubeconfig::SA_TOKEN = "$tmpdir/token";
local $Kubernetes::REST::Kubeconfig::SA_CA    = "$tmpdir/ca.crt";

sub endpoint_for {
    my ($host, $port) = @_;
    local $ENV{KUBERNETES_SERVICE_HOST} = $host;
    local $ENV{KUBERNETES_SERVICE_PORT} = $port;
    delete $ENV{KUBERNETES_SERVICE_HOST} unless defined $host;
    delete $ENV{KUBERNETES_SERVICE_PORT} unless defined $port;
    my $api = Kubernetes::REST::Kubeconfig->new->_in_cluster_api;
    return $api ? $api->server->endpoint : undef;
}

is(endpoint_for('10.96.0.1', undef), 'https://10.96.0.1:443', 'IPv4 literal, default port');
is(endpoint_for('fd00:10:96::1', '6443'), 'https://[fd00:10:96::1]:6443', 'IPv6 literal is bracketed');
is(endpoint_for('kubernetes.default.svc', undef), 'https://kubernetes.default.svc:443', 'DNS name is left alone');
is(endpoint_for(undef, undef), 'https://kubernetes.default.svc:443', 'no env: default host and port');
is(endpoint_for('[::1]', '6443'), 'https://[::1]:6443', 'already bracketed host is not bracketed twice');

{
    local $Kubernetes::REST::Kubeconfig::SA_TOKEN = "$tmpdir/missing";
    is(endpoint_for('10.96.0.1', '443'), undef, 'no service account token: not in-cluster');
}

done_testing;
