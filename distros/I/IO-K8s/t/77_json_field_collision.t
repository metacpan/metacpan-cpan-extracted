#!/usr/bin/env perl
# k108: a k8s-declared field literally named `json` used to collide with
# IO::K8s::Role::Resource's own internal JSON-encoder attribute (also named
# `json`). Resource.pm's _k8s() skips calling Moo's has() when the class
# already can($attr_name) -- true here, since the role's `has json` wins the
# slot -- so the field's declared type/default were never backed by a real
# attribute; the encoder object sat in that slot instead, and to_json/to_yaml
# died trying to serialize it. Fixed by renaming the role's private encoder
# attribute to `_json_encoder`, freeing `json` for a real k8s field on any
# class that declares one. This is the generic regression test, independent
# of the Cilium AccessLogs class that surfaced the bug (see t/07_cilium.t
# for that direct repro).
use strict;
use warnings;
use Test::More;

{
    package TestCollision::HasJsonField;
    use IO::K8s::Resource;

    k8s name => Str;
    # `default` in the k8s DSL is schema-only (never applied client-side --
    # see Resource.pm POD, "Field options"), so a bare instance leaves this
    # field genuinely unset. The regression this guards against is the
    # UNSET slot silently holding the role's internal JSON encoder object
    # instead of undef.
    k8s json => { Str => 1 }, { default => { authority => 'default-authority' } };
}

# Proof the role's own (now-renamed) `_json_encoder` attribute no longer
# shadows the k8s-declared `json` attribute: an untouched field reads back
# as undef -- never the encoder object -- and to_json/to_yaml, which read
# every declared attribute including this one, do not die.
subtest 'bare instance: field left unset, to_json/to_yaml do not die' => sub {
    my $obj = TestCollision::HasJsonField->new(name => 'widget');
    is($obj->json, undef, 'json field is unset (not the role\'s JSON encoder object)');

    my $json = eval { $obj->to_json };
    ok(!$@, 'to_json does not die') or diag("died: $@");
    like($json, qr/"name":"widget"/, 'to_json emits the object');
    unlike($json, qr/"json"/, 'to_json omits the unset json field rather than serializing the encoder');

    my $yaml = eval { $obj->to_yaml };
    ok(!$@, 'to_yaml does not die') or diag("died: $@");
    unlike($yaml, qr/^json:/m, 'to_yaml omits the unset json field');
};

subtest 'constructor-supplied value: round-trips through JSON' => sub {
    my $obj = TestCollision::HasJsonField->new(
        name => 'widget',
        json => { authority => '%REQUEST_HEADER(:AUTHORITY)%', extra => 'x' },
    );
    is_deeply(
        $obj->json,
        { authority => '%REQUEST_HEADER(:AUTHORITY)%', extra => 'x' },
        'constructor value wins over the field default',
    );

    my $struct = $obj->TO_JSON;
    is_deeply(
        $struct->{json},
        { authority => '%REQUEST_HEADER(:AUTHORITY)%', extra => 'x' },
        'TO_JSON emits a plain hashref for the json field, not a blessed encoder',
    );

    my $json = eval { $obj->to_json };
    ok(!$@, 'to_json does not die with an explicit json value') or diag("died: $@");

    my $re = eval { TestCollision::HasJsonField->from_json($json) };
    ok(!$@, 'from_json does not die') or diag("died: $@");
    isa_ok($re, 'TestCollision::HasJsonField');
    is($re->name, 'widget', 'round-trip preserves name');
    is_deeply(
        $re->json,
        { authority => '%REQUEST_HEADER(:AUTHORITY)%', extra => 'x' },
        'round-trip preserves the json field value',
    );
};

done_testing;
