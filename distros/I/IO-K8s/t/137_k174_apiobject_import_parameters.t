#!/usr/bin/env perl
# k174: `use IO::K8s::APIObject` read only the import parameters it knows
# and ignored every other one, so a typo such as `subresource => {...}` or
# `resource_plurals => '...'` went through without a word -- the class was
# built as if the parameter had never been written, and the mistake only
# showed much later (a to_crd without subresources, a resource_plural of
# undef).
#
# Claims:
#   * an unknown import parameter croaks naming the class, the parameter and
#     the known ones (api_version, resource_plural, subresources), at the
#     caller's `use` line;
#   * it croaks before anything is set up: the package does not become a
#     class and gets no k8s function;
#   * with several unknown parameters the first in sort order is named, so
#     the message is deterministic;
#   * the known parameters, and no parameters at all, still work.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;

use IO::K8s::APIObject ();

my $KNOWN = qr/\(known: api_version, resource_plural, subresources\)/;

my $n = 0;
# Compile a class with the given import parameter source, the `use` on line
# 42 of k174.pm; returns the error, or undef when it compiled.
sub declare {
    my ($params) = @_;
    my $class = 'TestK174::Class' . ++$n;
    my $ok = eval qq{#line 41 "k174.pm"\npackage $class;\nuse IO::K8s::APIObject $params;\n1};
    return ($class, $ok ? undef : $@);
}

subtest 'an unknown parameter croaks naming class, parameter and the known ones' => sub {
    my ($class, $err) = declare(q{api_version => 'k174.example.com/v1', subresource => { status => {} }});
    like($err, qr/\A\Q$class\E: unknown import parameter 'subresource' for IO::K8s::APIObject $KNOWN/,
        'subresource (for subresources)');
    like($err, qr/ at k174\.pm line 42\.?$/m, "reported at the caller's use line");

    ($class, $err) = declare(q{api_version => 'k174.example.com/v1', resource_plurals => 'things'});
    like($err, qr/\A\Q$class\E: unknown import parameter 'resource_plurals' for IO::K8s::APIObject $KNOWN/,
        'resource_plurals (for resource_plural)');

    ($class, $err) = declare(q{apiVersion => 'k174.example.com/v1'});
    like($err, qr/\A\Q$class\E: unknown import parameter 'apiVersion' for IO::K8s::APIObject $KNOWN/,
        'apiVersion, the wire spelling');
};

subtest 'nothing is set up for a refused import' => sub {
    my ($class, $err) = declare(q{api_version => 'k174.example.com/v1', plural => 'things'});
    ok(defined $err, 'the use croaked');
    ok(!$class->can('new'), 'the package did not become a class');
    ok(!$class->can('k8s'), 'and got no k8s function');
    ok(!$class->can('api_version'), 'and no api_version');
};

subtest 'several unknown parameters: the first in sort order is named' => sub {
    my (undef, $err) = declare(q{zeta => 1, api_version => 'k174.example.com/v1', alpha => 2});
    like($err, qr/unknown import parameter 'alpha' for/, 'alpha, not zeta');
};

subtest 'the known parameters still work' => sub {
    my ($class, $err) = declare(q{api_version => 'k174.example.com/v1', resource_plural => 'things',}
        . q{ subresources => { status => {} }});
    is($err, undef, 'all three known parameters compile');
    is($class->api_version, 'k174.example.com/v1', 'api_version installed');
    is($class->resource_plural, 'things', 'resource_plural installed');
    is_deeply($class->subresources, { status => {} }, 'subresources installed');

    my ($plain, $plain_err) = declare('');
    is($plain_err, undef, 'no parameters at all compiles');
    ok($plain->can('metadata'), 'and composes the APIObject role');
};

done_testing;
