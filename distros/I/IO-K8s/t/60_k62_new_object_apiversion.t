#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;

# k62: new_object() used to take the exact-GVK request only as its third
# positional argument and silently overwrite an apiVersion passed INSIDE the
# params hash with whatever version the short name resolves to -- while
# inflate() reads that same key and honours it. Two entry points, one input
# key, opposite semantics. Fix: honour apiVersion from the params hash the same
# way inflate does, and fail closed on a genuine conflict, never substitute.

my $k8s = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);

# Baseline: the short name alone resolves to the default served version.
my $default = $k8s->new_object('Sandbox', { spec => { podTemplate => {} } });
isa_ok($default, 'IO::K8s::AgentSandbox::V1beta1::Sandbox',
       'short name with no apiVersion resolves the default version');
is($default->api_version, 'agents.x-k8s.io/v1beta1', 'default api_version');

# The bug: apiVersion in the params hash is honoured, symmetric with inflate.
my $alpha = $k8s->new_object('Sandbox', {
    apiVersion => 'agents.x-k8s.io/v1alpha1',
    spec       => { podTemplate => {} },
});
isa_ok($alpha, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
       'apiVersion in the params hash selects the requested version');
is($alpha->api_version, 'agents.x-k8s.io/v1alpha1',
   'new_object honours the caller apiVersion, like inflate does');

# Symmetry check: inflate on the same input already behaves this way.
my $inflated = $k8s->inflate({
    kind       => 'Sandbox',
    apiVersion => 'agents.x-k8s.io/v1alpha1',
    spec       => { podTemplate => {} },
});
is(ref($alpha), ref($inflated),
   'new_object and inflate resolve the same class for the same kind+apiVersion');

# Fail closed: an apiVersion in the params hash that cannot be resolved dies
# instead of silently building a differently-versioned object.
throws_ok { $k8s->new_object('Sandbox', {
        apiVersion => 'agents.x-k8s.io/v1nonexistent',
        spec       => { podTemplate => {} },
    }) }
    qr/Cannot resolve Kubernetes GVK/,
    'unresolvable apiVersion in the params hash fails closed';

# A params-hash apiVersion that contradicts the explicit positional one is a
# genuine conflict -- reject it rather than pick one silently.
throws_ok { $k8s->new_object('Sandbox',
        { apiVersion => 'agents.x-k8s.io/v1alpha1', spec => { podTemplate => {} } },
        'agents.x-k8s.io/v1beta1') }
    qr/conflicting apiVersion/,
    'params-hash apiVersion contradicting the positional one croaks';

# Agreement between the two is fine.
my $agree = $k8s->new_object('Sandbox',
    { apiVersion => 'agents.x-k8s.io/v1alpha1', spec => { podTemplate => {} } },
    'agents.x-k8s.io/v1alpha1');
isa_ok($agree, 'IO::K8s::AgentSandbox::V1alpha1::Sandbox',
       'matching params-hash and positional apiVersion resolve normally');

done_testing;
