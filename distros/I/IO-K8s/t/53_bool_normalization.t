#!/usr/bin/env perl
# k37: boolean normalization treated every reference as true, so the bare
# Perl false idiom \0 arrived as true.
#
# There are two places that normalize a boolean-ish input into the plain 0/1
# that gets stored on the attribute, and before this ticket they disagreed:
#
#   1. the Moo coercer in lib/IO/K8s/Resource.pm, which dereferences and was
#      therefore right about \0 and JSON::PP::Boolean, and
#   2. the is_bool branch of _inflate_struct in lib/IO/K8s.pm, which read
#      `... || $value ? 1 : 0` -- and in Perl *every* reference is true, so an
#      unblessed \0 came out as 1.
#
# _inflate_struct runs before $class->new(%args), so the wrong pre-normalization
# won: the coercer only ever saw a plain 1 and had nothing left to rescue.
# Everything downstream (accessor, TO_JSON, to_json) then reports a confident
# true, indistinguishable from a real one -- on fields like privileged,
# allowPrivilegeEscalation or hostNetwork.
#
# The same expression had a second defect in the same failure class, on a path
# the ticket did not mention: the string "false". `lc($value) eq 'true'` is
# false for it, so the `|| $value` fallback took over, and a non-empty string
# that is not "0" is true in Perl -- so "false" also became 1. That one was
# wrong in the coercer too, i.e. on *both* paths.
#
# This test pins the whole matrix on both entry points and, crucially, in both
# serialization directions: a test that only reads the accessor cannot fail when
# TO_JSON flips, and TO_JSON is what actually reaches the cluster.
#
# k42 and k48 extend the same matrix, same file, same six lines of
# _normalize_bool (lib/IO/K8s/Resource.pm:139-156):
#
#   * k42 -- bad data (a hash/array/coderef, or a ref-to-ref like \\0) must
#     die with a message that names the rejected type, and on the inflation
#     path (struct_to_object/json_to_object) the class and field too, since
#     that is where a caller's own bad manifest data arrives anonymously.
#     \\0 was the silent half of the bug: it used to come out true.
#   * k48 -- an explicit undef (or \undef) must leave a Maybe[Bool] attribute
#     unset, not become a stored false that TO_JSON then emits onto the wire.
#     A required Bool (Bool, not Maybe[Bool]) still accepts explicit undef --
#     Types::Standard::Bool itself allows undef -- so construction does not
#     die locally; TO_JSON simply omits the field.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::PP ();
use JSON::MaybeXS ();
use IO::K8s;
use IO::K8s::Resource ();
use IO::K8s::Api::Core::V1::SecurityContext ();
use IO::K8s::Api::Core::V1::ContainerStatus ();
use IO::K8s::Api::Resource::V1::DeviceAttribute ();
use IO::K8s::Api::Resource::V1beta1::DeviceAttribute ();
use IO::K8s::Api::Resource::V1beta2::DeviceAttribute ();

my $k8s = IO::K8s->new;

# [ description, input value, expected plain 0/1 ]
my @cases = (
    [ 'JSON::PP::false'      => JSON::PP::false(),      0 ],
    [ 'JSON::PP::true'       => JSON::PP::true(),       1 ],
    [ 'JSON::MaybeXS::false' => JSON::MaybeXS::false(), 0 ],
    [ 'JSON::MaybeXS::true'  => JSON::MaybeXS::true(),  1 ],
    [ 'plain 0'              => 0,                      0 ],
    [ 'plain 1'              => 1,                      1 ],
    [ 'scalar ref \\0'       => \0,                     0 ],
    [ 'scalar ref \\1'       => \1,                     1 ],
    [ 'blessed scalar ref (arbitrary class) false' =>
        do { bless \(my $bf = 0), 'Test::Bool::Whatever' }, 0 ],
    [ 'blessed scalar ref (arbitrary class) true' =>
        do { bless \(my $bt = 1), 'Test::Bool::Whatever' }, 1 ],
    [ 'string "false"'       => 'false',                0 ],
    [ 'string "true"'        => 'true',                 1 ],
    [ 'string "False"'       => 'False',                0 ],
    [ 'string "0"'           => '0',                    0 ],
    [ 'string ""'            => '',                     0 ],
);

sub json_bool_name { $_[0] ? 'true' : 'false' }

subtest 'is_bool via struct_to_object (the _inflate_struct path)' => sub {
    for my $case (@cases) {
        my ($desc, $value, $want) = @$case;

        my $pod = $k8s->struct_to_object('Pod', {
            apiVersion => 'v1',
            kind       => 'Pod',
            metadata   => { name => 'p' },
            spec       => { containers => [
                { name => 'c', securityContext => { privileged => $value } },
            ] },
        });

        my $sc = $pod->spec->containers->[0]->securityContext;
        is($sc->privileged, $want, "$desc: accessor is $want");

        # Direction 2: what actually goes on the wire.
        my $out = $pod->TO_JSON->{spec}{containers}[0]{securityContext}{privileged};
        is(json_bool_name($out), json_bool_name($want),
            "$desc: TO_JSON emits " . json_bool_name($want));
        like($pod->to_json, qr/"privileged":\Q@{[ json_bool_name($want) ]}\E/,
            "$desc: encoded JSON carries " . json_bool_name($want));
    }
};

subtest 'is_bool via the constructor (the Moo coercer path)' => sub {
    for my $case (@cases) {
        my ($desc, $value, $want) = @$case;

        my $sc = IO::K8s::Api::Core::V1::SecurityContext->new(privileged => $value);
        is($sc->privileged, $want, "$desc: accessor is $want");
        is($sc->to_json, '{"privileged":' . json_bool_name($want) . '}',
            "$desc: serializes to " . json_bool_name($want));

        # Before k59, FROM_HASH was a bare ->new(%$hash) -- "the shallow
        # entry point" this comment used to describe. It now routes through
        # the same _inflate_struct pipeline struct_to_object uses, so a
        # scalar Bool value passes through both the is_bool inflate branch
        # and the constructor's coercer; for SecurityContext -- a flat class
        # with no nested object fields -- the observable result is the same.
        my $from = IO::K8s::Api::Core::V1::SecurityContext->FROM_HASH({ privileged => $value });
        is($from->privileged, $want, "$desc: FROM_HASH accessor is $want");
    }
};

subtest 'is_bool via json_to_object (real decoded JSON booleans)' => sub {
    for my $literal (qw(true false)) {
        my $want = $literal eq 'true' ? 1 : 0;
        my $sc = $k8s->json_to_object(
            'IO::K8s::Api::Core::V1::SecurityContext',
            qq({"privileged":$literal}),
        );
        is($sc->privileged, $want, "JSON literal $literal: accessor is $want");
        is($sc->to_json, qq({"privileged":$literal}),
            "JSON literal $literal round-trips byte-identical");
    }
};

# is_array_of_bool has no branch in _inflate_struct at all -- the value falls
# through untouched and only the array coercer in Resource.pm sees it. So the
# \0 defect never applied here; this locks that in, and covers the string case
# which the array coercer shared with its scalar sibling.
subtest 'is_array_of_bool keeps every element distinct' => sub {
    my @in   = map { $_->[1] } @cases;
    my @want = map { $_->[2] } @cases;
    my $want_json = '{"bools":[' . join(',', map { json_bool_name($_) } @want) . ']}';

    my $via_struct = $k8s->struct_to_object('IO::K8s::Api::Resource::V1::DeviceAttribute', { bools => \@in });
    is_deeply($via_struct->bools, \@want, 'struct_to_object: every element normalized');
    is($via_struct->to_json, $want_json, 'struct_to_object: array serializes as JSON booleans');

    my $via_new = IO::K8s::Api::Resource::V1::DeviceAttribute->new(bools => \@in);
    is_deeply($via_new->bools, \@want, 'constructor: every element normalized');
    is($via_new->to_json, $want_json, 'constructor: array serializes as JSON booleans');
};

# The regression as reported, spelled out end to end: two Pods that differ only
# in how false was written must be byte-identical on the wire.
subtest 'k37: \\0 and JSON false produce identical output' => sub {
    my $make = sub {
        my ($v) = @_;
        return $k8s->struct_to_object('Pod', {
            apiVersion => 'v1',
            kind       => 'Pod',
            metadata   => { name => 'p' },
            spec       => { containers => [
                { name => 'c', securityContext => {
                    privileged               => $v,
                    allowPrivilegeEscalation => $v,
                } },
            ] },
        })->to_json;
    };

    my $expected = $make->(JSON::PP::false());
    like($expected, qr/"privileged":false/, 'JSON::PP::false stays false');
    is($make->(\0),      $expected, '\0 matches JSON::PP::false');
    is($make->('false'), $expected, 'string "false" matches JSON::PP::false');
    is($make->(0),       $expected, 'plain 0 matches JSON::PP::false');
};

# k42, item 1: a value that cannot mean true or false must die naming
# what it was. Called directly so the assertion is against _normalize_bool's
# own message, before either caller attaches its own context.
subtest 'k42: non-derefable references name their type' => sub {
    for my $case (
        [ HASH  => {} ],
        [ ARRAY => [] ],
        [ CODE  => sub { 1 } ],
    ) {
        my ($reftype, $bad) = @$case;
        eval { IO::K8s::Resource::_normalize_bool($bad) };
        like($@, qr/\QBool value must be a scalar or scalar ref, got $reftype\E/,
            "$reftype ref: message names the rejected type");
    }
};

# k42, item 2: the second defect found while verifying -- a ref-to-ref
# used to dereference once, land on another reference, and that reference's
# truthiness silently won (\\0 came out true). It must die instead, and the
# message must say what it dereferenced to, not just that it failed.
subtest 'k42: \\0 (ref-to-ref) dies instead of silently becoming true' => sub {
    eval { IO::K8s::Resource::_normalize_bool(\\0) };
    like($@,
        qr/\QBool scalar ref dereferenced to another reference (SCALAR), not a boolean\E/,
        '\\0 dies naming what it dereferenced to');
};

# k42, item 3: the constructor path already named the attribute before
# this ticket (Moo's coercion wrapper does that for free) -- pin the combined
# message so the two paths stay legible side by side.
subtest 'k42: constructor path via Moo names the attribute too' => sub {
    throws_ok { IO::K8s::Api::Core::V1::SecurityContext->new(privileged => {}) }
        qr/coercion for "privileged" failed: Bool value must be a scalar or scalar ref, got HASH/,
        'constructor: HASH ref names both the attribute and the rejected type';

    throws_ok { IO::K8s::Api::Core::V1::SecurityContext->new(privileged => \\0) }
        qr/coercion for "privileged" failed: Bool scalar ref dereferenced to another reference \(SCALAR\), not a boolean/,
        'constructor: \\0 dies naming the attribute, not silently true';
};

# k42, item 4: this was the anonymous half of the bug as originally
# reported -- struct_to_object's inflation path knows $class and $attr, and
# now attaches them, so a caller's own bad manifest data is diagnosable
# instead of bottoming out at a bare line number inside IO::K8s.
subtest 'k42: inflation path names class and field' => sub {
    throws_ok {
        $k8s->struct_to_object('Pod', { spec => { hostNetwork => {} } });
    }
        qr/Bool value must be a scalar or scalar ref, got HASH while inflating IO::K8s::Api::Core::V1::PodSpec field hostNetwork/,
        'struct_to_object: HASH ref names class and field, not just a line number';

    throws_ok {
        $k8s->struct_to_object('Pod', { spec => { hostNetwork => \\0 } });
    }
        qr/Bool scalar ref dereferenced to another reference \(SCALAR\), not a boolean while inflating IO::K8s::Api::Core::V1::PodSpec field hostNetwork/,
        'struct_to_object: \\0 dies with class/field context too, not silently true';
};

# k42, item 5: is_array_of_bool shares _normalize_bool via the array
# coercer in lib/IO/K8s/Resource.pm (the `elsif ($info{is_array_of_bool})`
# branch, around lines 282-296 -- not line 264, which is just the
# _k8s_attributes bookkeeping push()), which appends "at element N" to
# whatever _normalize_bool said. struct_to_object has no dedicated inflate
# branch for arrays of bool (documented above), so the value falls through
# untouched and only the array coercer ever sees it -- same message, either
# entry point.
subtest 'k42: array element errors report which element failed' => sub {
    throws_ok { IO::K8s::Api::Resource::V1::DeviceAttribute->new(bools => [1, {}, 0]) }
        qr/coercion for "bools" failed: .* at element 1/,
        'constructor: bad array element (hashref) names the element index';

    throws_ok { IO::K8s::Api::Resource::V1::DeviceAttribute->new(bools => [1, \\0, 0]) }
        qr/coercion for "bools" failed: .* at element 1/,
        'constructor: bad array element (\\0) names the element index too';

    throws_ok {
        $k8s->struct_to_object('IO::K8s::Api::Resource::V1::DeviceAttribute', { bools => [1, {}, 0] });
    }
        qr/coercion for "bools" failed: .* at element 1/,
        'struct_to_object: falls through to the same array coercer, same message';
};

# k48: an explicit undef -- via the constructor, FROM_HASH, a scalar ref
# to undef, struct_to_object, or a real decoded JSON null -- must leave a
# Maybe[Bool] attribute unset. TO_JSON is the direction that matters: an
# unset field is omitted, not emitted as an explicit `false` that a
# strategic-merge patch or server-side apply would then treat as a claim of
# ownership over a value the caller never actually supplied.
subtest 'k48: explicit undef leaves the field unset, not false' => sub {
    my $assert_unset = sub {
        my ($obj, $label) = @_;
        ok(!defined $obj->privileged, "$label: accessor is undef");
        ok(!exists $obj->TO_JSON->{privileged}, "$label: TO_JSON omits the field");
        is($obj->to_json, '{}', "$label: to_json is the empty object");
    };

    $assert_unset->(
        IO::K8s::Api::Core::V1::SecurityContext->new(privileged => undef),
        'constructor: undef',
    );
    $assert_unset->(
        IO::K8s::Api::Core::V1::SecurityContext->new(privileged => \undef),
        'constructor: \\undef',
    );
    $assert_unset->(
        IO::K8s::Api::Core::V1::SecurityContext->FROM_HASH({ privileged => undef }),
        'FROM_HASH: undef',
    );
    $assert_unset->(
        IO::K8s::Api::Core::V1::SecurityContext->FROM_HASH({ privileged => \undef }),
        'FROM_HASH: \\undef',
    );
    $assert_unset->(
        $k8s->struct_to_object('Api::Core::V1::SecurityContext', { privileged => undef }),
        'struct_to_object: undef (regression guard -- _inflate_struct already skipped it before k48)',
    );
    $assert_unset->(
        $k8s->struct_to_object('Api::Core::V1::SecurityContext', { privileged => \undef }),
        'struct_to_object: \\undef',
    );
    $assert_unset->(
        $k8s->json_to_object('IO::K8s::Api::Core::V1::SecurityContext', '{"privileged":null}'),
        'json_to_object: real decoded JSON null',
    );
};

# k48: a *required* Bool (isa => Bool, not Maybe[Bool] -- ContainerStatus's
# "ready") still accepts an explicit undef, because Types::Standard::Bool
# itself allows undef regardless of required-ness. This is worth pinning
# explicitly: it means "required" does not by itself reject undef, and
# TO_JSON's behaviour is identical to the Maybe[Bool] case -- the field is
# simply omitted, not coerced into a stored false.
subtest 'k48: a required Bool accepts explicit undef; TO_JSON omits it' => sub {
    my $cs;
    lives_ok {
        $cs = IO::K8s::Api::Core::V1::ContainerStatus->new(
            name         => 'c',
            image        => 'busybox',
            imageID      => 'docker-pullable://busybox@sha256:deadbeef',
            restartCount => 0,
            ready        => undef,
        );
    } 'required Bool "ready": explicit undef does not trigger a local type error';

    ok(!defined $cs->ready, 'accessor is undef');
    ok(!exists $cs->TO_JSON->{ready}, 'TO_JSON omits the required-but-undef field');
};

# k51: an undef ELEMENT of ArrayRef[Bool] is accepted at construction --
# Types::Standard::Bool allows undef, and _normalize_bool's `return undef`
# (not a bare `return`) keeps the array coercer from collapsing the element,
# so the position is preserved -- but there is no honest wire representation
# for it. The attribute-level answer from k48 (leave the field unset)
# does not apply inside an array, where "omit" would shift every later
# element. TO_JSON dies instead, naming the class, field and element index,
# in the same style as the k42 messages. Covered on all three
# DeviceAttribute API tracks that carry `bools` (V1alpha3 has no `bools`
# field and is out of scope).
subtest 'k51: undef array element accepted at construction, dies on serialization' => sub {
    for my $class (qw(
        IO::K8s::Api::Resource::V1::DeviceAttribute
        IO::K8s::Api::Resource::V1beta1::DeviceAttribute
        IO::K8s::Api::Resource::V1beta2::DeviceAttribute
    )) {
        my $obj;
        lives_ok { $obj = $class->new(bools => [1, undef, 0]) }
            "$class: constructor accepts an undef array element";
        is_deeply($obj->bools, [1, undef, 0],
            "$class: undef element keeps its position (not dropped, not coerced to false)");

        throws_ok { $obj->TO_JSON }
            qr/\QBool value must not be undef at element 1 while serializing $class field bools\E/,
            "$class: TO_JSON dies naming class, field and element index";

        throws_ok { $obj->to_json }
            qr/\QBool value must not be undef at element 1 while serializing $class field bools\E/,
            "$class: to_json dies the same way (goes through TO_JSON)";
    }
};

# k51: the index in the message is the actual position, not hardcoded --
# pin that against undef at the first and last positions too.
subtest 'k51: the reported element index matches the actual position' => sub {
    my $class = 'IO::K8s::Api::Resource::V1::DeviceAttribute';

    throws_ok { $class->new(bools => [undef, 1, 0])->TO_JSON }
        qr/\QBool value must not be undef at element 0 while serializing $class field bools\E/,
        'undef at element 0 is reported as element 0';

    throws_ok { $class->new(bools => [1, 0, undef])->TO_JSON }
        qr/\QBool value must not be undef at element 2 while serializing $class field bools\E/,
        'undef at element 2 is reported as element 2';
};

done_testing;
