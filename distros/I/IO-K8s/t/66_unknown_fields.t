#!/usr/bin/env perl
# D1: a constructor key no attribute claims is kept in _unknown_fields and
# emitted again by TO_JSON -- on inflate, new_object and a direct ->new,
# at every nesting level, including inline structs (k91 part 2).
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::PP ();
use JSON::MaybeXS ();

use IO::K8s;
use IO::K8s::Api::Core::V1::Pod;
use IO::K8s::Api::Core::V1::PodSpec;
use IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta;

# A subclass built with `use parent`, not `use Moo` -- it has no constructor
# maker of its own, so Moo->_constructor_maker_for(__PACKAGE__) returns undef
# and _collect_known_init_args must walk up the ISA to find the specs for
# `_json_encoder` and `_unknown_fields` (both a plain `has` in Role::Resource,
# not a k8s-registered attribute) instead of treating them as unknown.
{
    package TestUF::Sub;
    use parent -norequire, 'IO::K8s::Api::Core::V1::Pod';
}

my $k8s = IO::K8s->new;

sub meta { IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta->new(name => $_[0]) }

subtest 'inflate keeps undeclared fields at every level' => sub {
    my $pod = $k8s->inflate({
        apiVersion => 'v1',
        kind       => 'Pod',
        metadata   => { name => 'x' },
        spec       => {
            containers => [ { name => 'c', image => 'i', bogusToo => JSON::PP::true } ],
            bogusField => { nested => [ 1, 2 ] },
        },
    });
    my $out = $pod->TO_JSON;
    is_deeply($out->{spec}{bogusField}, { nested => [ 1, 2 ] }, 'unknown spec field round-trips');
    ok($out->{spec}{containers}[0]{bogusToo}, 'unknown field inside an array element round-trips');
    is_deeply($pod->spec->_unknown_fields, { bogusField => { nested => [ 1, 2 ] } }, 'the bag holds exactly the unknown field');
    ok(!exists $out->{_unknown_fields}, 'the bag itself is not a wire field');
    ok(!exists $out->{spec}{_unknown_fields}, 'nor on nested objects');
};

subtest 'new_object and a direct constructor keep unknown fields too' => sub {
    my $pod = $k8s->new_object('Pod',
        metadata => { name => 'y' },
        spec     => { containers => [], extra => 'v' },
    );
    is($pod->TO_JSON->{spec}{extra}, 'v', 'new_object path');

    my $direct = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), whatever => 1);
    is($direct->TO_JSON->{whatever}, 1, 'direct ->new path');
};

subtest 'apiVersion and kind in a struct are not unknown fields' => sub {
    my $pod = $k8s->inflate({ apiVersion => 'v1', kind => 'Pod', metadata => { name => 'x' } });
    is_deeply($pod->_unknown_fields, {}, 'the GVK keys the role supplies are recognised');
};

subtest 'a declared attribute wins over a same-named bag entry' => sub {
    # spec is a plain nested-object attribute, not an inline struct, so
    # ->new doesn't coerce a hashref into PodSpec (that inflation lives in
    # IO::K8s::_inflate_struct, ahead of new_object/inflate, not in the
    # constructor) -- a blessed PodSpec is required here.
    my $pod = IO::K8s::Api::Core::V1::Pod->new(
        metadata => meta('z'),
        spec     => IO::K8s::Api::Core::V1::PodSpec->new(containers => []),
    );
    $pod->_unknown_fields({ spec => 'shadow' });
    is(ref $pod->TO_JSON->{spec}, 'HASH', 'declared spec is emitted, the bag entry is ignored');
};

subtest 'undef unknown values are not kept' => sub {
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), gone => undef);
    ok(!exists $pod->TO_JSON->{gone}, 'undef unknown value omitted');
    is_deeply($pod->_unknown_fields, {}, 'and not stored');
};

subtest 'the bag does not alias the caller data (k54 line)' => sub {
    my $data = { deep => 1 };
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), extra => $data);
    $data->{deep} = 2;
    is($pod->TO_JSON->{extra}{deep}, 1, 'one-level copy on the way in');
    my $out = $pod->TO_JSON;
    $out->{extra}{deep} = 3;
    is($pod->TO_JSON->{extra}{deep}, 1, 'one-level copy on the way out');
};

subtest 'an explicit _unknown_fields hashref is copied, not aliased' => sub {
    my $h = { extra => 1 };
    my $pod = IO::K8s::Api::Core::V1::Pod->new(metadata => meta('z'), _unknown_fields => $h);
    $h->{extra} = 2;
    is($pod->TO_JSON->{extra}, 1, '_unknown_fields is copied on the way in, not aliased');
};

subtest 'inline struct keeps unknown keys (k91 part 2)' => sub {
    my $sb = IO::K8s->new(with => ['IO::K8s::AgentSandbox']);
    my $s = $sb->new_object('Sandbox',
        metadata => { name => 'x', namespace => 'd' },
        spec     => { replicas => 1, shutdownPolicy => 'Retain' },
    );
    is($s->TO_JSON->{spec}{replicas}, 1, 'undeclared spec.replicas survives on an inline struct');
    is($s->TO_JSON->{spec}{shutdownPolicy}, 'Retain', 'declared field still there');
};

subtest 'JSON round-trip through to_json / from_json keeps the field' => sub {
    my $pod = $k8s->new_object('Pod', metadata => { name => 'r' }, spec => { containers => [], extra => [ 'a' ] });
    my $again = IO::K8s::Api::Core::V1::Pod->from_json($pod->to_json);
    is_deeply($again->TO_JSON->{spec}{extra}, [ 'a' ], 'survives a full serialize/parse cycle');
};

subtest 'a use-parent subclass with no Moo constructor of its own still knows _json_encoder/_unknown_fields' => sub {
    my $obj = TestUF::Sub->new(
        metadata        => meta('sub'),
        _json_encoder   => JSON::MaybeXS->new(utf8 => 1),
        _unknown_fields => { a => 1 },
        bogus           => 2,
    );
    is_deeply($obj->_unknown_fields, { a => 1, bogus => 2 },
        '_json_encoder and _unknown_fields are recognised as known init args; only bogus lands in the bag');
    ok(!exists $obj->TO_JSON->{_json_encoder}, 'the encoder object never reaches the wire');
    is($obj->TO_JSON->{a}, 1, 'the pre-seeded bag entry still round-trips');

    local $IO::K8s::Resource::STRICT = 1;
    lives_ok {
        TestUF::Sub->new(
            metadata        => meta('sub2'),
            _json_encoder   => JSON::MaybeXS->new(utf8 => 1),
            _unknown_fields => { a => 1 },
        );
    } '_json_encoder and _unknown_fields alone live under strict, even with no own constructor maker';
    throws_ok {
        TestUF::Sub->new(
            metadata        => meta('sub3'),
            _json_encoder   => JSON::MaybeXS->new(utf8 => 1),
            _unknown_fields => { a => 1 },
            bogus           => 2,
        );
    } qr/^Unknown field 'bogus' for TestUF::Sub$/m, 'a genuinely unknown key still dies under strict, naming it';
};

done_testing;
