#!/usr/bin/env perl
# Direct unit test for IO::K8s::Resource::_expand_class.
#
# _expand_class is private but its effect is observable via the registry it
# feeds: every k8s DSL declaration that names a class records the expanded
# full class name in %IO::K8s::Resource::_attr_registry under
# {caller}{attr}{class}. Each subtest below declares a fresh target package,
# runs one k8s call with the short name under test, and asserts the
# recorded class.
#
# This is a unit test, not a regression test for any specific bug — it
# exercises every branch of the four-way if/return so future changes to
# _expand_class fail loudly here, not silently inside some shipped API
# class.

use strict;
use warnings;
use Test::More;

# Run-time load — _expand_class and the registry are package globals, but
# we never want to depend on the order in which the shipped API classes
# load.
require IO::K8s::Resource;

my $REG = \%IO::K8s::Resource::_attr_registry;

sub _fresh_target {
    my $name = shift;
    # We need a fresh target package per case because the registry is a
    # package global. We use string eval because `package $var;` is not
    # valid Perl syntax. The eval block also installs a sub closure that
    # calls k8s() in the fresh target's scope, so callers can invoke it
    # without method-call syntax (which would prepend $pkg to @_ and
    # confuse the k8s wrapper). We use a 0 + sub {...} trick to make the
    # eval return the coderef rather than the trailing 1.
    my $pkg = "IO::K8s::Test::ExpandClass::$name";
    my $k8s_call = eval "package $pkg; use IO::K8s::Resource; sub { k8s(\@_) }"
        or die "could not import IO::K8s::Resource into $pkg: $@";
    return ($pkg, $k8s_call);
}

sub _declared_class {
    my ($pkg, $attr) = @_;
    my $info = $REG->{$pkg}{$attr}
        or return ('NO REGISTRY ENTRY', undef);
    return ('NO class FIELD', undef) unless exists $info->{class};
    return ($info->{class}, $info);
}

# ---- Branch A: leading '+' strips to the bare FQCN ----------------------------

subtest 'Branch A: +FullClassName strips the + and uses the FQCN verbatim' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchA');
    $k8s->(x => '+IO::K8s::Api::Core::V1::Pod');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Api::Core::V1::Pod',
        '+ prefix stripped, expansion is the FQCN');
};

# ---- Branch B: input already starts with IO::K8s:: ----------------------------

subtest 'Branch B: input starting with IO::K8s:: passes through unchanged' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchB');
    $k8s->(x => 'IO::K8s::Api::Core::V1::Pod');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Api::Core::V1::Pod',
        'already-qualified name passes through unchanged');
};

# ---- Branch C: simple known prefix --------------------------------------------

subtest 'Branch C: known prefix Core expands to IO::K8s::Api::Core' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchCSimple');
    $k8s->(x => 'Core::V1::Pod');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Api::Core::V1::Pod',
        'Core::V1::Pod expands to IO::K8s::Api::Core::V1::Pod');
};

# ---- Branch C: known prefix Meta (non-Api namespace) --------------------------

subtest 'Branch C: known prefix Meta expands to the Apimachinery namespace' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchCMeta');
    $k8s->(x => 'Meta::V1::ObjectMeta');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
        'Meta::V1::ObjectMeta expands to the Apimachinery namespace');
};

# ---- Branch C: the longest-key-first contract (the actual bugfix) ------------

subtest 'Branch C: KubeAggregator longest-key wins over a hypothetical shorter prefix' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchCLongest');
    # The KubeAggregator prefix already encodes the full
    # Pkg::Apis::Apiregistration path, so the short form is just
    # 'V1::APIServiceSpec' — the same form real API classes use.
    $k8s->(x => 'KubeAggregator::V1::APIServiceSpec');
    my ($class) = _declared_class($pkg, 'x');
    is($class,
        'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceSpec',
        'KubeAggregator::* expands to the KubeAggregator namespace');
    isnt($class,
        'IO::K8s::Api::KubeAggregator::V1::APIServiceSpec',
        'does NOT collapse to the wrong IO::K8s::Api::KubeAggregator namespace');
};

# ---- Branch C: prefix substring edge case (Apiextensions::V1::CRD) ------------

subtest 'Branch C: Apiextensions::V1::CRD expands via the Apiextensions key, not a hypothetical Api key' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchCApiext');
    $k8s->(x => 'Apiextensions::V1::CustomResourceDefinition');
    my ($class) = _declared_class($pkg, 'x');
    is($class,
        'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
        'Apiextensions::* expands via the longest matching key');
    isnt($class,
        'IO::K8s::Api::Apiextensions::V1::CustomResourceDefinition',
        'does NOT collapse to the wrong IO::K8s::Api namespace');
};

# ---- Branch C: unknown prefix falls through to IO::K8s::Api:: ----------------

subtest 'Branch C: unknown prefix falls through to IO::K8s::Api' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchCUnknown');
    $k8s->(x => 'Boggle::V1::Foo');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Api::Boggle::V1::Foo',
        'unknown CamelCase prefix falls through to IO::K8s::Api::');
};

# ---- Branch D: default fallback (input does not start with [A-Z]\w*::) --------

subtest 'Branch D: lowercase input falls through to IO::K8s::Api::' => sub {
    my ($pkg, $k8s) = _fresh_target('BranchD');
    $k8s->(x => 'lowercase::v1::Foo');
    my ($class) = _declared_class($pkg, 'x');
    is($class, 'IO::K8s::Api::lowercase::v1::Foo',
        'non-CamelCase input falls through to the IO::K8s::Api:: default');
};

# ---- Map consistency check ---------------------------------------------------

# Walk every prefix key and assert the public _expand_class path produces a
# name in the expected target namespace. We do this by importing
# IO::K8s::Resource into fresh throwaway packages and running one k8s call
# per key, with a sentinel "X::V1::Y" short form. The prefix key must win.
subtest 'every %_class_prefix key expands to its declared namespace' => sub {
    # The keys we expect to be in the prefix map. We do not introspect the
    # map (it is a lexical `my` in Resource.pm); we assert against the
    # publicly documented contract — anything missing here is a regression
    # in the public surface of _expand_class.
    my %expected = (
        'Core'                  => 'IO::K8s::Api::Core',
        'Apps'                  => 'IO::K8s::Api::Apps',
        'Batch'                 => 'IO::K8s::Api::Batch',
        'Networking'            => 'IO::K8s::Api::Networking',
        'Rbac'                  => 'IO::K8s::Api::Rbac',
        'Storage'               => 'IO::K8s::Api::Storage',
        'Policy'                => 'IO::K8s::Api::Policy',
        'Autoscaling'           => 'IO::K8s::Api::Autoscaling',
        'Admissionregistration' => 'IO::K8s::Api::Admissionregistration',
        'Coordination'          => 'IO::K8s::Api::Coordination',
        'Discovery'             => 'IO::K8s::Api::Discovery',
        'Events'                => 'IO::K8s::Api::Events',
        'Flowcontrol'           => 'IO::K8s::Api::Flowcontrol',
        'Node'                  => 'IO::K8s::Api::Node',
        'Scheduling'            => 'IO::K8s::Api::Scheduling',
        'Certificates'          => 'IO::K8s::Api::Certificates',
        'Authentication'        => 'IO::K8s::Api::Authentication',
        'Authorization'         => 'IO::K8s::Api::Authorization',
        'Resource'              => 'IO::K8s::Api::Resource',
        'Storagemigration'      => 'IO::K8s::Api::Storagemigration',
        'Meta'                  => 'IO::K8s::Apimachinery::Pkg::Apis::Meta',
        'Apiextensions'         => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions',
        'KubeAggregator'        => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration',
    );

    my $i = 0;
    for my $prefix (sort keys %expected) {
        my ($pkg, $k8s) = _fresh_target("MapCheck" . ++$i);
        $k8s->(x => "${prefix}::V1::Sentinel");
        my ($class) = _declared_class($pkg, 'x');
        is($class, $expected{$prefix} . '::V1::Sentinel',
            "prefix '$prefix' expands to its declared namespace");
    }
};

done_testing;
