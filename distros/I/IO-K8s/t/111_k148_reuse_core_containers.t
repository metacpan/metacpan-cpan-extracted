#!/usr/bin/env perl
# k148: IO::K8s::AutoGen's D5 core-class reuse (reuse_core => 1, the default)
# treats every array as compatible with every "array of X" candidate field,
# and every object/map as compatible with every "map of X" candidate field,
# regardless of what X actually is on either side.
#
# Confirmed repro: a nested `spec` schema shaped exactly like
# IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement
# ({key,operator,values}, required [key,operator]) but whose `values` is an
# ARRAY OF OBJECTS ({item: string}), not an array of strings:
#
#   IO::K8s::AutoGen::get_or_generate('review.Shape', $shape, {}, 'Review::Reuse1',
#       api_version => 'review.example/v1', kind => 'Shape', reuse_core => 1);
#
# picks LabelSelectorRequirement for `spec` anyway (its `values` is [Str]),
# and
#   $class->FROM_HASH({ spec => { key=>'a', operator=>'In', values=>[{item=>'x'}] } })
# dies: "Reference [...] did not pass type constraint ... ArrayRef[Str] ...".
# With reuse_core => 0 the same schema builds its own nested class and
# round-trips correctly.
#
# Cause, in lib/IO/K8s/AutoGen.pm:
#   _flag_compatible (~695-699) treats EVERY 'is_array_of_*' flag as
#   compatible with schema kind 'array', and EVERY 'is_hash_of_*' flag as
#   compatible with schema kind 'object' -- by regex prefix, with no check of
#   what the array holds or what the map's values are. That is the only place
#   _core_class_for (~773-838) compares a CANDIDATE's field type against what
#   the SCHEMA itself actually declares for that field.
#   _core_class_for's other schema-aware step, _wire_identical (~717-735),
#   never runs against the schema at all -- it only compares several
#   surviving CANDIDATES against EACH OTHER (see ~833-838: a single surviving
#   candidate is returned unconditionally at line 833, skipping
#   _wire_identical entirely). So a shape with exactly one candidate --
#   LabelSelectorRequirement/FieldSelectorRequirement/NodeSelectorRequirement
#   are all real candidates for [key,operator,values], but they all happen to
#   agree with EACH OTHER that `values` is an array of strings -- sails
#   through with no comparison against the schema's own (incompatible)
#   `values` shape at all.
#
# Approved fix contract (NOT implemented by this file -- these are
# regression tests pinning it down before the fix exists): recursive
# container/element/map compatibility -- an array candidate must agree with
# the schema on its element shape, a map candidate on its value shape,
# recursively; a complex match that cannot be proven safe generates the
# provider's own class instead of reusing a core one. The existing exception
# stays: a schema fragment that never states a `required` list makes no
# required-ness claim (`_overrequires`, mirrored from t/75_reuse_core.t
# lines 154-161) and is not treated as narrower reuse-wise.
#
# Pure local fixtures -- no network, no cluster.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 'lib';

use IO::K8s::AutoGen;
use JSON::MaybeXS;

my $LABEL_SELECTOR_REQUIREMENT = 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelectorRequirement';
my $HTTP_HEADER                = 'IO::K8s::Api::Core::V1::HTTPHeader';

# Same JSON::MaybeXS options IO::K8s::Role::Resource::to_json uses, so a
# byte-for-byte comparison against $obj->to_json is meaningful.
sub canon_json { JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($_[0]) }

# A root Kind schema with one nested `spec` object shaped {key,operator,+extra},
# required [key,operator] unless $no_required is set -- the shape k148 is
# about, parameterized on what `values` (or whatever extra property is
# supplied) actually looks like.
sub shape_root_schema {
    my (%o) = @_;
    my %props = ( key => { type => 'string' }, operator => { type => 'string' }, %{ $o{extra_props} || {} } );
    my $spec = { type => 'object', properties => \%props };
    $spec->{required} = [ 'key', 'operator' ] unless $o{no_required};
    return { type => 'object', properties => { spec => $spec } };
}

my $unique = 0;
sub fresh_namespace { return 'IO::K8s::_AUTOGEN_k148_' . (++$unique) }

sub spec_class_of {
    my ($class) = @_;
    return $class->_k8s_attr_info->{spec}{class};
}

# ============================================================================
# RED: reuse must not ignore the element/value type of an array or a map.
# ============================================================================

# Claim: `values` shaped as an array of OBJECTS must never be typed as
# LabelSelectorRequirement's `values` ([Str]) just because both are "an
# array" -- and real data for the schema's own shape must round-trip
# byte-identically once typed correctly.
subtest 'k148 RED: array-of-object values must not reuse an array-of-string candidate' => sub {
    my $schema = shape_root_schema(
        extra_props => {
            values => { type => 'array', items => { type => 'object', properties => { item => { type => 'string' } } } },
        },
    );
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Shape', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Shape', reuse_core => 1,
    );

    isnt(spec_class_of($class), $LABEL_SELECTOR_REQUIREMENT,
        'the spec class is not LabelSelectorRequirement '
      . '(currently: it is, even though its values field is [Str], not [{item}])');

    my $data     = { key => 'a', operator => 'In', values => [ { item => 'x' } ] };
    my $expected = canon_json({ apiVersion => 'review.example/v1', kind => 'Shape', spec => $data });
    lives_and {
        is($class->FROM_HASH({ spec => $data })->to_json, $expected);
    } 'the schema\'s own data round-trips byte-identically '
    . '(currently: FROM_HASH dies -- "did not pass type constraint ... ArrayRef[Str]")';
};

# Claim: the same wrong-element-type problem recurses -- an array of arrays
# of strings must not reuse a plain array-of-strings candidate either.
subtest 'k148 RED: array-of-array-of-string values must not reuse a flat array-of-string candidate' => sub {
    my $schema = shape_root_schema(
        extra_props => {
            values => { type => 'array', items => { type => 'array', items => { type => 'string' } } },
        },
    );
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Shape', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Shape', reuse_core => 1,
    );

    isnt(spec_class_of($class), $LABEL_SELECTOR_REQUIREMENT,
        'the spec class is not LabelSelectorRequirement '
      . '(currently: it is, even though its values field is [Str], not [[Str]])');

    my $data     = { key => 'a', operator => 'In', values => [ [ 'x', 'y' ] ] };
    my $expected = canon_json({ apiVersion => 'review.example/v1', kind => 'Shape', spec => $data });
    lives_and {
        is($class->FROM_HASH({ spec => $data })->to_json, $expected);
    } 'the schema\'s own data round-trips byte-identically '
    . '(currently: FROM_HASH dies -- "did not pass type constraint ... ArrayRef[Str]")';
};

# Claim: the identical confusion exists for maps -- a schema whose shape
# happens to match a shipped class with a typed *object*-valued map
# (IO::K8s::Api::Resource::V1alpha3::BasicDevice's {attributes,capacity},
# `attributes` being a map of BasicDevice's own DeviceAttribute objects) must
# not be reused for a schema whose same-named field is a map of a different
# value type (a plain string map here) -- searched for in the shipped core
# shape index rather than invented, per the ticket's own instruction.
subtest 'k148 RED: a typed map (map-of-object) candidate must not be reused for a map-of-string schema field' => sub {
    my @candidates = IO::K8s::AutoGen::core_class_for_shape([qw(attributes capacity)]);
    is_deeply(\@candidates, [ 'IO::K8s::Api::Resource::V1alpha3::BasicDevice' ],
        'BasicDevice(v1alpha3) is the sole real candidate for the {attributes,capacity} shape '
      . '(scope guard: if this fails, upstream added another candidate and this fixture needs a new one)');

    my $schema = {
        type       => 'object',
        properties => {
            spec => {
                type       => 'object',
                properties => {
                    attributes => { type => 'object', additionalProperties => { type => 'string' } },
                    capacity   => { type => 'object', additionalProperties => { type => 'string' } },
                },
            },
        },
    };
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Dev', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Dev', reuse_core => 1,
    );

    isnt(spec_class_of($class), 'IO::K8s::Api::Resource::V1alpha3::BasicDevice',
        'the spec class is not BasicDevice '
      . '(currently: it is, even though its attributes field is a map of DeviceAttribute objects, not of plain strings)');

    my $data     = { attributes => { a => 'plain-string-value' }, capacity => { cpu => '10' } };
    my $expected = canon_json({ apiVersion => 'review.example/v1', kind => 'Dev', spec => $data });
    lives_and {
        is($class->FROM_HASH({ spec => $data })->to_json, $expected);
    } 'the schema\'s own data round-trips byte-identically '
    . '(currently: FROM_HASH lives but silently drops the string value, emitting "attributes":{"a":{}})';
};

# ============================================================================
# GUARDS: established, correct reuse behaviour the fix must not break.
# ============================================================================

# Claim: the genuine wire-identical case -- `values` really is an array of
# strings, exactly like LabelSelectorRequirement's own field -- must keep
# reusing it. This is the established, wanted D5 behaviour k148 must not
# collateral-damage.
subtest 'GUARD: array-of-string values still reuses LabelSelectorRequirement' => sub {
    my $schema = shape_root_schema(extra_props => { values => { type => 'array', items => { type => 'string' } } });
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Shape', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Shape', reuse_core => 1,
    );
    is(spec_class_of($class), $LABEL_SELECTOR_REQUIREMENT, 'spec is still typed as LabelSelectorRequirement');

    my $data = { key => 'a', operator => 'In', values => [ 'x', 'y' ] };
    is_deeply($class->FROM_HASH({ spec => $data })->TO_JSON->{spec}, $data, 'and it round-trips correctly');
};

# Claim: an existing, unrelated positive reuse (a wire-identical {name,value}
# scalar-only shape reusing Core::V1::HTTPHeader, the same fixture
# t/75_reuse_core.t already relies on) must keep working -- k148 is scoped to
# array/map element-type confusion, not to scalar-field reuse in general.
subtest 'GUARD: an established scalar-shape reuse (HTTPHeader) keeps working' => sub {
    my $schema = {
        type       => 'object',
        properties => {
            spec => {
                type       => 'object',
                properties => { name => { type => 'string' }, value => { type => 'string' } },
            },
        },
    };
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Thing', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Thing', reuse_core => 1,
    );
    is(spec_class_of($class), $HTTP_HEADER, 'spec is typed as the shared HTTPHeader class');

    my $data = { name => 'X-Trace', value => 'abc123' };
    is_deeply($class->FROM_HASH({ spec => $data })->TO_JSON->{spec}, $data, 'and it round-trips correctly');
};

# Claim: a schema fragment that never states a `required` list makes no
# required-ness claim (_overrequires' documented exception, exercised by
# t/75_reuse_core.t lines 154-161 for a different candidate) -- reuse must
# still fire in that case, not be denied for merely omitting `required`.
subtest 'GUARD: omitting `required` entirely does not defeat an otherwise-safe reuse' => sub {
    my $schema = shape_root_schema(
        no_required => 1,
        extra_props => { values => { type => 'array', items => { type => 'string' } } },
    );
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Shape', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Shape', reuse_core => 1,
    );
    is(spec_class_of($class), $LABEL_SELECTOR_REQUIREMENT,
        'spec is still typed as LabelSelectorRequirement even with no `required` list in the schema');
};

# Claim: reuse_core => 0 must keep generating the provider's own nested
# class outright, never reaching the reuse decision at all -- the escape
# hatch the confirmed bug report itself used to show correct behaviour.
subtest 'GUARD: reuse_core => 0 always generates its own class, never reuses a core one' => sub {
    my $schema = shape_root_schema(
        extra_props => {
            values => { type => 'array', items => { type => 'object', properties => { item => { type => 'string' } } } },
        },
    );
    my $ns    = fresh_namespace();
    my $class = IO::K8s::AutoGen::get_or_generate(
        'review.Shape', $schema, {}, $ns,
        api_version => 'review.example/v1', kind => 'Shape', reuse_core => 0,
    );
    my $spec_class = spec_class_of($class);
    like($spec_class, qr/^\Q$ns\E::/, 'spec is a class generated inside the provider\'s own namespace');
    isnt($spec_class, $LABEL_SELECTOR_REQUIREMENT, 'and not the shared LabelSelectorRequirement');

    my $data     = { key => 'a', operator => 'In', values => [ { item => 'x' } ] };
    my $expected = canon_json({ apiVersion => 'review.example/v1', kind => 'Shape', spec => $data });
    is($class->FROM_HASH({ spec => $data })->to_json, $expected, 'and the data round-trips byte-identically');
};

done_testing;
