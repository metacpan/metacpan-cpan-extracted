#!/usr/bin/env perl
# karr #31 / #32: expand_class() and add()/with() resolve a resource_map
# short-name key as a GVK source, but only when the mapped class can
# positively confirm the requested apiVersion.
#
# This test locks in:
#
#   - karr #31: a CRD registered only under its bare kind (e.g.
#     StaticWebSite => '+My::StaticWebSite') still resolves through
#     inflate()/new_object()/expand_class() when an apiVersion is supplied,
#     not just when it is omitted.
#   - karr #17: a version mismatch, or a mapped class with no api_version()
#     method at all, stays fail-closed (undef).
#   - karr #32: a mapped class that CANNOT verify its api_version — because
#     the method exists but returns undef, or because api_version is a Moo
#     instance attribute rather than a class-level method/constant — must
#     fail closed silently: undef, no warning, no exception. This applies
#     on both call paths: _resolve_short_name_gvk (expand_class's GVK
#     lookup) and _qualify_class_path (add()/with(), driven at
#     IO::K8s->new(with => [...]) construction time).
#
# Pure local fixtures — no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';
use IO::K8s;

# ----------------------------------------------------------------------------
# Test-local CRD/provider classes.
#   My::StaticWebSite  — kind() matches the bug report's wire kind.
#   My::TestCRD        — the generic mini-CRD shape (kind derived from the
#                        class name, so the map key must be 'TestCRD').
#   My::NoApiVersion   — has kind() but NO api_version() method at all: not
#                        verifiable, so the fallback must fail closed.
#   My::UndefAV        — HAS an api_version() method, but it returns undef.
#                        Pre-fix this tripped 'undef eq $api_version' and
#                        warned; the result was already undef either way.
#   My::AttrAV         — api_version is a Moo instance attribute, not a
#                        class-level method/constant. Calling it as a class
#                        method dies. Models a foreign CRD class not built
#                        on IO::K8s::APIObject — the practical case.
# ----------------------------------------------------------------------------

{
    package My::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    k8s spec => { Str => 1 };
    1;
}

{
    package My::TestCRD;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'testcrds';
    k8s spec => { Str => 1 };
    1;
}

{
    package My::NoApiVersion;
    use IO::K8s::Resource;
    sub kind { 'NoApiVersion' }
    1;
}

{
    package My::UndefAV;
    use IO::K8s::Resource;
    sub kind { 'UndefAV' }
    sub api_version { undef }
    1;
}

{
    package My::AttrAV;
    use Moo;
    has api_version => (is => 'rw');
    sub kind { 'AttrAV' }
    1;
}

# The reported reproduction: the built-in map plus short-name CRD keys.
my %map = (
    %{ IO::K8s->default_resource_map },
    StaticWebSite => '+My::StaticWebSite',
    TestCRD      => '+My::TestCRD',
);

subtest 'inflate() with apiVersion resolves short-name CRD key' => sub {
    my $api = IO::K8s->new(resource_map => \%map);

    my $obj;
    lives_ok {
        $obj = $api->inflate({
            kind       => 'StaticWebSite',
            apiVersion => 'homelab.example.com/v1',
            metadata   => { name => 'my-site' },
            spec       => { domain => 'blog.example.com' },
        });
    } 'inflate kind + apiVersion does not die';
    isa_ok($obj, 'My::StaticWebSite', 'inflated object class');
    is($obj->kind, 'StaticWebSite', 'inflated kind');
    is($obj->api_version, 'homelab.example.com/v1', 'inflated api_version');
    is($obj->metadata->name, 'my-site', 'inflated metadata name');
    is($obj->spec->{domain}, 'blog.example.com', 'inflated spec');
};

subtest 'new_object with apiVersion resolves short-name CRD key' => sub {
    my $api = IO::K8s->new(resource_map => \%map);

    my $obj;
    lives_ok {
        $obj = $api->new_object('TestCRD',
            { metadata => { name => 'my-crd' }, spec => { foo => 'bar' } },
            'homelab.example.com/v1',
        );
    } 'new_object($kind, {...}, $api_version) does not die';
    isa_ok($obj, 'My::TestCRD', 'new_object object class');
    is($obj->kind, 'TestCRD', 'new_object kind');
    is($obj->api_version, 'homelab.example.com/v1', 'new_object api_version');
    is($obj->metadata->name, 'my-crd', 'new_object metadata name');
};

subtest 'expand_class("$av/$kind") resolves short-name CRD key' => sub {
    my $api = IO::K8s->new(resource_map => \%map);

    is($api->expand_class('homelab.example.com/v1/TestCRD'), 'My::TestCRD',
        'domain-qualified string falls back to short-name key (TestCRD)');
    is($api->expand_class('homelab.example.com/v1/StaticWebSite'), 'My::StaticWebSite',
        'domain-qualified string falls back to short-name key (StaticWebSite)');
};

subtest 'version mismatch fails closed' => sub {
    my $api = IO::K8s->new(resource_map => \%map);

    is($api->expand_class('StaticWebSite', 'wrong.example.com/v2'), undef,
        'expand_class with mismatched apiVersion returns undef (fail closed)');

    throws_ok {
        $api->inflate({
            kind       => 'StaticWebSite',
            apiVersion => 'wrong.example.com/v2',
            metadata   => { name => 'x' },
        });
    } qr/Cannot resolve Kubernetes GVK: kind 'StaticWebSite', apiVersion 'wrong\.example\.com\/v2'/,
        'inflate with mismatched apiVersion dies with GVK error';
};

subtest 'mapped class without api_version() fails closed' => sub {
    my $api = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        NoApiVersion => '+My::NoApiVersion',
    });

    is($api->expand_class('NoApiVersion', 'whatever.io/v1'), undef,
        'class without api_version() cannot be verified -> undef (fail closed)');
};

subtest 'mapped class with api_version() returning undef fails closed silently' => sub {
    # karr #32: api_version() is callable and returns cleanly, but the
    # answer is undef. 'undef eq $api_version' in the verification guard
    # is a warning trap ("Use of uninitialized value ... in string eq") if
    # the fix does not check definedness before the string comparison. The
    # result was already undef pre-fix, so is($result, undef) alone would
    # not catch the regression — the warning capture is the actual assertion.
    my $api = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        UndefAV => '+My::UndefAV',
    });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $result;
    lives_ok { $result = $api->expand_class('UndefAV', 'whatever.io/v1') }
        'expand_class does not die when the mapped api_version() returns undef';
    is($result, undef, 'undef api_version() cannot be verified -> undef (fail closed)');
    is(scalar(@warnings), 0, 'no warnings emitted')
        or diag("warnings: @warnings");
};

subtest 'add()/with() tolerate a mapped api_version() returning undef' => sub {
    # karr #32, released-bug side (1.106): _qualify_class_path() hit the
    # same 'undef eq $api_version' trap, reached from add() and therefore
    # from IO::K8s->new(with => [...]) at construction time.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $api;
    lives_ok {
        $api = IO::K8s->new(with => [ { UndefAV => '+My::UndefAV' } ]);
    } 'new(with => [{...}]) does not die when the provider api_version() returns undef';
    is(scalar(@warnings), 0, 'no warnings emitted during construction')
        or diag("warnings: @warnings");

    is($api->resource_map->{UndefAV}, '+My::UndefAV',
        'short-name key is registered regardless');
    ok(!(grep { m{/UndefAV\z} } keys %{ $api->resource_map }),
        'no domain-qualified key is synthesised (api_version could not be confirmed)');

    my @warnings2;
    local $SIG{__WARN__} = sub { push @warnings2, $_[0] };
    my $api2 = IO::K8s->new;
    lives_ok { $api2->add({ UndefAV => '+My::UndefAV' }) }
        'add({...}) directly does not die either';
    is(scalar(@warnings2), 0, 'add(): no warnings emitted')
        or diag("warnings: @warnings2");
    is($api2->resource_map->{UndefAV}, '+My::UndefAV',
        'add(): short-name key is registered');
    ok(!(grep { m{/UndefAV\z} } keys %{ $api2->resource_map }),
        'add(): no domain-qualified key is synthesised');
};

subtest 'mapped class with api_version as a Moo instance attribute fails closed' => sub {
    # karr #32: calling api_version() as a class method on such a class
    # dies ("Class::XSAccessor: invalid instance method invocant ..." or
    # equivalent). The eval-guarded lookup must swallow that and fail
    # closed, not propagate the exception out of expand_class().
    my $api = IO::K8s->new(resource_map => {
        %{ IO::K8s->default_resource_map },
        AttrAV => '+My::AttrAV',
    });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $result;
    lives_ok { $result = $api->expand_class('AttrAV', 'whatever.io/v1') }
        'expand_class does not die when api_version is an instance attribute';
    is($result, undef, 'instance-attribute api_version cannot be verified -> undef (fail closed)');
    is(scalar(@warnings), 0, 'no warnings emitted')
        or diag("warnings: @warnings");
};

subtest 'add()/with() tolerate api_version as a Moo instance attribute' => sub {
    # karr #32, released-bug side (1.106) — the practical case: a foreign
    # CRD class not built on IO::K8s::APIObject. Before the fix, add() (and
    # therefore IO::K8s->new(with => [...])) died outright instead of
    # skipping the unqualifiable entry.
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $api;
    lives_ok {
        $api = IO::K8s->new(with => [ { AttrAV => '+My::AttrAV' } ]);
    } 'new(with => [{...}]) does not die when api_version is an instance attribute';
    is(scalar(@warnings), 0, 'no warnings emitted during construction')
        or diag("warnings: @warnings");

    is($api->resource_map->{AttrAV}, '+My::AttrAV',
        'short-name key is registered regardless');
    ok(!(grep { m{/AttrAV\z} } keys %{ $api->resource_map }),
        'no domain-qualified key is synthesised (api_version could not be confirmed)');

    my @warnings2;
    local $SIG{__WARN__} = sub { push @warnings2, $_[0] };
    my $api2 = IO::K8s->new;
    lives_ok { $api2->add({ AttrAV => '+My::AttrAV' }) }
        'add({...}) directly does not die either';
    is(scalar(@warnings2), 0, 'add(): no warnings emitted')
        or diag("warnings: @warnings2");
    is($api2->resource_map->{AttrAV}, '+My::AttrAV',
        'add(): short-name key is registered');
    ok(!(grep { m{/AttrAV\z} } keys %{ $api2->resource_map }),
        'add(): no domain-qualified key is synthesised');
};

subtest 'live resource_map mutation after construction' => sub {
    my $api = IO::K8s->new;    # no resource_map at construction
    $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

    my $obj;
    lives_ok {
        $obj = $api->inflate({
            kind       => 'StaticWebSite',
            apiVersion => 'homelab.example.com/v1',
            metadata   => { name => 'live' },
        });
    } 'live-mutated map: inflate with apiVersion does not die';
    isa_ok($obj, 'My::StaticWebSite', 'live-mutated inflate object class');
    is($obj->kind, 'StaticWebSite', 'live-mutated inflate kind');
    is($obj->api_version, 'homelab.example.com/v1', 'live-mutated inflate api_version');
};

subtest 'existing behaviour unchanged' => sub {
    my $api = IO::K8s->new(resource_map => \%map);

    is($api->expand_class('Pod', 'apps/v1'), undef,
        'Pod is core/v1 — apps/v1 request stays undef (fallback must not false-hit)');
    is($api->expand_class('Pod', 'v1'), 'IO::K8s::Api::Core::V1::Pod',
        'qualified key still takes precedence');
    is($api->expand_class('Pod'), 'IO::K8s::Api::Core::V1::Pod',
        'short name without apiVersion unchanged');
    is($api->expand_class('StaticWebSite'), 'My::StaticWebSite',
        'short name without apiVersion still resolves (baseline from bug report)');
};

done_testing;
