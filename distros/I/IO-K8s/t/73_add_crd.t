#!/usr/bin/env perl
# D10: IO::K8s::CRD turns a CustomResourceDefinition manifest into one class
# per served version; IO::K8s->add_crd registers them (qualified keys for
# every version, the short name on the storage version).
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;

use IO::K8s;
use IO::K8s::CRD;

my $fixture = "$FindBin::Bin/data/crd-knob.yaml";

subtest 'load accepts every input form' => sub {
    my $from_path = IO::K8s::CRD->load($fixture);
    is(scalar @$from_path, 1, 'one CRD from a path');
    is($from_path->[0]{spec}{names}{kind}, 'Knob', 'parsed');

    open my $fh, '<', $fixture or die $!;
    my $text = do { local $/; <$fh> };
    is_deeply(IO::K8s::CRD->load($text), $from_path, 'same from YAML text');
    is_deeply(IO::K8s::CRD->load($from_path->[0]), $from_path, 'same from a hashref');

    my $k8s = IO::K8s->new;
    my $obj = $k8s->inflate($from_path->[0]);
    isa_ok($obj, 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition');
    my $from_obj = IO::K8s::CRD->load($obj);
    is($from_obj->[0]{spec}{versions}[1]{schema}{openAPIV3Schema}{properties}{spec}{properties}{mode}{enum}[0], 'fast',
        'from an object, through TO_JSON');
    is(scalar @{ IO::K8s::CRD->load([ $fixture, $from_path->[0] ]) }, 2, 'an arrayref of inputs concatenates');

    throws_ok { IO::K8s::CRD->load("apiVersion: v1\nkind: Pod\nmetadata:\n  name: x\n") }
        qr/document 1 is a 'Pod', not a CustomResourceDefinition/, 'wrong kind dies, names the document';
    throws_ok { IO::K8s::CRD->load({ kind => 'CustomResourceDefinition', spec => { group => 'g' } }) }
        qr/without spec\.group \/ spec\.names\.kind \/ spec\.versions/, 'incomplete CRD dies';
    throws_ok { IO::K8s::CRD->load(undef) } qr/needs a CustomResourceDefinition/, 'undef dies';
    throws_ok {
        IO::K8s::CRD->load({
            apiVersion => 'apiextensions.k8s.io/v1',
            kind       => 'CustomResourceDefinition',
            metadata   => { name => 'x' },
            spec       => { group => 'g', names => { kind => 'X', plural => 'xs' }, versions => [] },
        });
    } qr/without spec\.group \/ spec\.names\.kind \/ spec\.versions/, 'empty versions array dies the same way';
};

subtest 'served_versions skips unserved and marks storage' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my $v = IO::K8s::CRD->served_versions($crd);
    is_deeply([ map { $_->{api_version} } @$v ], [ 'opts.example.com/v1alpha1', 'opts.example.com/v1' ], 'v0 is not served');
    is_deeply([ map { $_->{storage} } @$v ], [ 0, 1 ], 'storage flag');
    is($v->[1]{name}, 'v1', 'name');
    ok($v->[1]{schema}{properties}{spec}, 'schema carried');
};

subtest 'served_versions accepts a quoted "true"/"false" and rejects a malformed flag' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my @versions = @{ $crd->{spec}{versions} };

    # v0 is unserved in the fixture (served: false); flip it to the quoted
    # string form and confirm it now counts as served.
    my %quoted_crd = %$crd;
    $quoted_crd{spec} = {
        %{ $crd->{spec} },
        versions => [ @versions[0, 1], { %{ $versions[2] }, served => 'true' } ],
    };
    my $v = IO::K8s::CRD->served_versions(\%quoted_crd);
    is_deeply([ map { $_->{name} } @$v ], [ 'v1alpha1', 'v1', 'v0' ], 'served: "true" (quoted string) counts as served');

    # A value _normalize_bool cannot read as true/false must not be
    # swallowed into "not served" -- it has to fail loudly instead.
    my %malformed_crd = %$crd;
    $malformed_crd{spec} = {
        %{ $crd->{spec} },
        versions => [ { %{ $versions[0] }, served => [ 1, 2 ] }, $versions[1] ],
    };
    throws_ok { IO::K8s::CRD->served_versions(\%malformed_crd) }
        qr/spec\.versions\[0\]\.served is not a boolean/, 'a malformed served value dies loudly, naming the index and field';
};

subtest 'generate falls back to the LAST served version when none marks storage' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my %no_storage_crd = %$crd;
    $no_storage_crd{spec} = {
        %{ $crd->{spec} },
        versions => [ map { +{ %$_, storage => 0 } } @{ $crd->{spec}{versions} } ],
    };
    my $k8s = IO::K8s->new;
    my $classes = IO::K8s::CRD->generate(\%no_storage_crd, $k8s->_autogen_namespace);
    is($classes->{storage}, 'opts.example.com/v1', 'v1 (the last served version) is picked, not v1alpha1 (the first)');
};

subtest 'generate: scope Cluster does not compose Role::Namespaced' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my %cluster_crd = %$crd;
    $cluster_crd{spec} = { %{ $crd->{spec} }, scope => 'Cluster' };
    my $k8s = IO::K8s->new;
    my $classes = IO::K8s::CRD->generate(\%cluster_crd, $k8s->_autogen_namespace);
    my $storage_class = $classes->{ $classes->{storage} };
    ok(!$storage_class->does('IO::K8s::Role::Namespaced'), 'Cluster-scoped generated class is not Namespaced');
};

subtest 'add_crd: a hyphenated API group and an odd nested JSON key generate valid packages' => sub {
    # cert-manager.io's own group is 'acme.cert-manager.io': every segment
    # of def_to_class's ::-joined package name must be a bare identifier,
    # and a hyphen is not one (D10 follow-up, the crd-drift-check --suggest
    # run over CertManager).
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my %hyphen_crd = %$crd;
    $hyphen_crd{metadata} = { %{ $crd->{metadata} }, name => 'knobs.acme.cert-manager.io' };
    $hyphen_crd{spec} = { %{ $crd->{spec} }, group => 'acme.cert-manager.io' };

    # Give the storage version's spec an oddly-named nested object property
    # too: '.' and '/' are as invalid in a nested class's own package
    # segment as '-' is in the group.
    my @versions = map { +{ %$_ } } @{ $crd->{spec}{versions} };
    for my $v (@versions) {
        next unless $v->{name} eq 'v1';
        $v->{schema} = { %{ $v->{schema} } };
        my $oapi = { %{ $v->{schema}{openAPIV3Schema} } };
        $oapi->{properties} = { %{ $oapi->{properties} } };
        $oapi->{properties}{spec} = { %{ $oapi->{properties}{spec} } };
        $oapi->{properties}{spec}{properties} = {
            %{ $oapi->{properties}{spec}{properties} },
            'x.y/z' => { type => 'object', properties => { a => { type => 'string' } } },
        };
        $v->{schema}{openAPIV3Schema} = $oapi;
    }
    $hyphen_crd{spec}{versions} = \@versions;

    my $k8s = IO::K8s->new;
    my $reg;
    lives_ok { $reg = $k8s->add_crd(\%hyphen_crd) } 'add_crd lives for a hyphenated API group';
    my $storage_class = $reg->{Knob}{ $reg->{Knob}{storage} };
    like($storage_class, qr/::acme::cert_manager::io::v1::Knob$/, 'the hyphen in the group sanitizes to an underscore in the package');
    is($storage_class->api_version, 'acme.cert-manager.io/v1', 'api_version keeps the original hyphen -- only the package name is sanitized');
    is($k8s->expand_class('acme.cert-manager.io/v1/Knob'), $storage_class, 'expand_class resolves the hyphenated, domain-qualified GVK string');

    my $knob = $k8s->new_object('Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec     => { mode => 'fast', 'x.y/z' => { a => 'v' } },
    );
    my $spec_attr_info = ref($knob->spec)->_k8s_attr_info;
    like($spec_attr_info->{x_y_z}{class}, qr/::X_y_z$/, 'x.y/z -> a nested class named ::X_y_z');
    is_deeply($knob->TO_JSON->{spec}{'x.y/z'}, { a => 'v' }, 'the odd key round-trips on the wire under its original JSON key');
};

subtest 'add_crd registers every served version and the storage short name' => sub {
    my $k8s = IO::K8s->new;
    my $reg = $k8s->add_crd($fixture);
    is_deeply([ sort keys %$reg ], [ 'Knob' ], 'one Kind');
    is($reg->{Knob}{storage}, 'opts.example.com/v1', 'storage version');
    my $v1  = $reg->{Knob}{'opts.example.com/v1'};
    my $v1a = $reg->{Knob}{'opts.example.com/v1alpha1'};
    like($v1,  qr/^IO::K8s::_AUTOGEN_[0-9a-f]+::_CRD::opts::example::com::v1::Knob$/, 'v1 class in the instance namespace, under the ::_CRD sub-namespace');
    like($v1a, qr/::v1alpha1::Knob$/, 'v1alpha1 class');
    is($k8s->expand_class('Knob'), $v1, 'short name -> storage version');
    is($k8s->expand_class('Knob', 'opts.example.com/v1alpha1'), $v1a, 'qualified lookup -> other version');
    is($k8s->expand_class('opts.example.com/v1/Knob'), $v1, 'domain-qualified string');
    is($v1->api_version, 'opts.example.com/v1', 'api_version');
    is($v1->kind, 'Knob', 'kind');
    is($v1->resource_plural, 'knobs', 'resource_plural from names.plural');
    ok($v1->does('IO::K8s::Role::Namespaced'), 'Namespaced scope');
    ok($v1->does('IO::K8s::Role::APIObject'), 'top-level object');
};

subtest 'objects from the registered classes are typed to full depth' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add_crd($fixture);
    my $knob = $k8s->new_object('Knob',
        metadata => { name => 'k', namespace => 'd' },
        spec => {
            mode => 'fast', replicas => 2,
            limit => { average => 10, period => '5s' },
            routes => [ { match => 'a', weight => 1 } ],
            size => '10Gi',
            extra => { anything => 1 },
        },
    );
    isa_ok($knob->spec->limit, ref($knob) . '::Spec::Limit');
    isa_ok($knob->spec->routes->[0], ref($knob) . '::Spec::RoutesItem');
    is($knob->spec->size, '10Gi', 'x-kubernetes-int-or-string -> IntOrStr');
    is($knob->spec->_k8s_attr_info->{size}{is_int_or_string}, 1,
        'size is registered as IntOrStr at the registry level, not merely holding a string value');
    is_deeply($knob->TO_JSON->{spec}{extra}, { anything => 1 }, 'preserve-unknown object is opaque and round-trips');
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'slow' }) } qr/not one of: fast, safe/, 'enum';
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'fast', replicas => 9 }) } qr/above the maximum 5/, 'range';
    throws_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => { mode => 'fast', limit => { period => 'x' } }) } qr/does not match the pattern/, 'pattern below the top level';
    # required lists are recorded for the schema (required => 'schema', step 2's
    # ruling), never enforced on a generated class: a cluster returns
    # status: {} for a fresh object no matter what the status schema requires.
    is(ref($knob)->_k8s_attr_info->{spec}{required}, 1, 'top-level required recorded');
    is($knob->spec->_k8s_attr_info->{mode}{required}, 1, 'nested required recorded');
    lives_ok { $k8s->new_object('Knob', metadata => { name => 'k' }, spec => {}) } 'a missing required field does not fail construction';
    lives_ok { $k8s->inflate({ apiVersion => 'opts.example.com/v1', kind => 'Knob', metadata => { name => 'k' }, spec => { mode => 'fast' }, status => {} }) }
        'a cluster document with an empty status inflates';
    my $old = $k8s->new_object('Knob', { metadata => { name => 'o' }, spec => { mode => 'anything' } }, 'opts.example.com/v1alpha1');
    is($old->api_version, 'opts.example.com/v1alpha1', 'the other served version is its own class');
    is($old->TO_JSON->{spec}{mode}, 'anything', 'with its own, looser schema');
};

subtest 'a provider registered first keeps the short name' => sub {
    my $k8s = IO::K8s->new;
    $k8s->add({ Knob => '+IO::K8s::Api::Core::V1::Pod' });   # stands in for a provider class
    my $reg = $k8s->add_crd($fixture);
    is($k8s->expand_class('Knob'), 'IO::K8s::Api::Core::V1::Pod', 'first registration wins the short name');
    is($k8s->expand_class('opts.example.com/v1/Knob'), $reg->{Knob}{'opts.example.com/v1'}, 'the CRD class is reachable by its qualified key');
};

subtest 'two instances do not share generated classes' => sub {
    my $a = IO::K8s->new; my $b = IO::K8s->new;
    my $ra = $a->add_crd($fixture); my $rb = $b->add_crd($fixture);
    isnt($ra->{Knob}{'opts.example.com/v1'}, $rb->{Knob}{'opts.example.com/v1'}, 'different namespaces');
};

subtest 'a CRD class never aliases an openapi_spec class for the same GVK' => sub {
    # Both IO::K8s::CRD->generate and the openapi_spec AutoGen path build a
    # class name from nothing but the namespace + group/version/Kind (see
    # IO::K8s::AutoGen::get_or_generate) -- never from the schema. Without
    # the ::_CRD sub-namespace (see the generate() POD) the two would build
    # the IDENTICAL class name for opts.example.com/v1/Knob, AutoGen's
    # per-class-name cache would return whichever one ran first, and
    # add_crd would report success while silently discarding the CRD's own
    # schema.
    my $swagger_def = {
        type => 'object',
        'x-kubernetes-group-version-kind' => [ { group => 'opts.example.com', version => 'v1', kind => 'Knob' } ],
        properties => {
            spec => { type => 'object', properties => { fromSpec => { type => 'string' } } },
        },
    };
    my $k8s = IO::K8s->new(openapi_spec => { definitions => { 'opts.example.com.v1.Knob' => $swagger_def } });

    # Force the openapi_spec-derived class to be generated FIRST, under
    # this instance's bare _autogen_namespace.
    my $swagger_class = $k8s->expand_class('Knob', 'opts.example.com/v1');
    ok($swagger_class->_k8s_attr_info->{spec}, 'swagger class generated');

    my $reg = $k8s->add_crd($fixture);
    my $crd_class = $reg->{Knob}{'opts.example.com/v1'};
    isnt($crd_class, $swagger_class, 'the CRD class is a distinct package from the swagger-derived one');

    my $spec_attrs = $crd_class->_k8s_attr_info->{spec}{class}->_k8s_attr_info;
    ok(exists $spec_attrs->{$_}, "CRD spec declares '$_'") for qw( mode replicas limit routes );
    ok(!exists $spec_attrs->{fromSpec}, "CRD spec does not carry the swagger definition's 'fromSpec'");

    my $knob = $k8s->new_object('Knob', metadata => { name => 'k', namespace => 'd' }, spec => { mode => 'fast' });
    is(ref($knob), $crd_class, "new_object('Knob') resolves to the CRD's own class (D13: +Class registration wins over AutoGen)");
};

subtest 'served_versions does not autovivify a missing schema key' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my %no_schema_key_crd = %$crd;
    # v0 (index 2) carries no 'schema' key at all here, not merely an empty
    # one -- a plain '$v->{schema}{openAPIV3Schema}' read would autovivify
    # $v->{schema} into {} as a side effect of the read.
    my @versions = map { +{ %$_ } } @{ $crd->{spec}{versions} };
    delete $versions[2]{schema};
    $versions[2]{served} = 1;   # so it is actually walked
    $no_schema_key_crd{spec} = { %{ $crd->{spec} }, versions => \@versions };

    ok(!exists $versions[2]{schema}, 'no schema key before the call');
    my $served = IO::K8s::CRD->served_versions(\%no_schema_key_crd);
    is_deeply(
        (grep { $_->{name} eq 'v0' } @$served)[0]{schema},
        { type => 'object' },
        'the default schema is still returned for the missing-key version',
    );
    ok(!exists $versions[2]{schema}, 'the caller\'s version hashref did not gain a schema key as a side effect');
};

subtest 'add_crd merges version entries when two CRDs share a Kind across groups' => sub {
    my ($crd) = @{ IO::K8s::CRD->load($fixture) };
    my %other_group_crd = %$crd;
    $other_group_crd{metadata} = { %{ $crd->{metadata} }, name => 'knobs.other.example.com' };
    $other_group_crd{spec} = { %{ $crd->{spec} }, group => 'other.example.com' };

    # One add_crd call, two CRDs sharing the bare Kind 'Knob' across
    # different groups -- the case the old '$registered{$kind} = $classes'
    # (plain overwrite) lost the first CRD's versions for.
    my $k8s = IO::K8s->new;
    my $reg = $k8s->add_crd($fixture, \%other_group_crd);

    is_deeply(
        [ sort grep { $_ ne 'storage' } keys %{ $reg->{Knob} } ],
        [ sort qw( opts.example.com/v1 opts.example.com/v1alpha1 other.example.com/v1 other.example.com/v1alpha1 ) ],
        'both CRDs\' served versions are present under the shared Kind',
    );
    is($reg->{Knob}{storage}, 'opts.example.com/v1', 'storage stays the FIRST registration\'s, mirroring add()\'s first-registration-wins');
    is($k8s->expand_class('Knob'), $reg->{Knob}{'opts.example.com/v1'}, 'the bare Kind resolves to the first registration\'s storage class');
    is($k8s->expand_class('other.example.com/v1/Knob'), $reg->{Knob}{'other.example.com/v1'}, 'the second group\'s version is still reachable, qualified');
};

done_testing;
