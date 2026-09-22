#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::K8s;

# k61: add() must not re-qualify a provider resource_map key that is
# ALREADY domain-qualified. Such a key is an exact GVK request and is
# registered verbatim; running it through _qualify_class_path a second time
# produced junk keys of shape "$group/$version/$group/$version/$Kind".

# --- A provider whose resource_map carries an already-qualified key ---
{
    package Test::Mock::Qualified::Widget;
    use IO::K8s::Resource;
    sub api_version { 'example.com/v1' }
    sub kind { 'Widget' }
}
{
    package Test::Mock::QualifiedProvider;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';
    sub resource_map {
        return {
            'example.com/v1/Widget' => '+Test::Mock::Qualified::Widget',
        };
    }
}

my $k8s = IO::K8s->new;
$k8s->add('Test::Mock::QualifiedProvider');
my $map = $k8s->resource_map;

ok(exists $map->{'example.com/v1/Widget'},
   'already-qualified provider key is registered verbatim');
ok(!exists $map->{'example.com/v1/example.com/v1/Widget'},
   'already-qualified key is NOT re-qualified into a double-qualified junk key');

# --- The shipped providers that established the pattern: no key on the
#     merged map may carry more than two path segments (group/version/Kind). ---
{
    my $shipped = IO::K8s->new(with => ['IO::K8s::GatewayAPI', 'IO::K8s::AgentSandbox'])->resource_map;
    my @junk = grep { (my $n = () = m{/}g) > 2 } keys %$shipped;
    is_deeply(\@junk, [],
              'no double-qualified junk keys in the merged shipped provider map')
        or diag("junk keys: @junk");

    # The legitimate verbatim GVK entries still resolve.
    ok(exists $shipped->{'gateway.networking.k8s.io/v1/ReferenceGrant'},
       'GatewayAPI v1 ReferenceGrant GVK key present verbatim');
    ok(exists $shipped->{'agents.x-k8s.io/v1alpha1/Sandbox'},
       'AgentSandbox v1alpha1 Sandbox GVK key present verbatim');
}

done_testing;
