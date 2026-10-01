#!/usr/bin/env perl
# k144: declaration conflicts must fail before they mutate the registry, while
# legitimate role-owned and inherited attributes keep their established paths.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Moo ();
use lib 'lib';
use JSON::MaybeXS qw( decode_json );

use IO::K8s;
use IO::K8s::APIObject;
use IO::K8s::AutoGen;
use IO::K8s::Resource;

sub registry_for {
  my ($class) = @_;
  return { %{ $IO::K8s::Resource::_attr_registry{$class} // {} } };
}

sub attributes_for {
  my ($class) = @_;
  no strict 'refs';
  return [ @{ "${class}::_k8s_attributes" } ];
}

sub assert_rejected_declaration {
  my ($class, $field, $label) = @_;
  my $k8s = $class->can('k8s');
  my $before_registry = registry_for($class);
  my $before_attributes = attributes_for($class);

  throws_ok { $k8s->($field, 'Str') }
    qr/\Q$field\E/,
    $label.' is rejected naming its JSON field';
  is_deeply(registry_for($class), $before_registry,
    $label.' leaves the registry unchanged after rejection');
  is_deeply(attributes_for($class), $before_attributes,
    $label.' leaves the attribute list unchanged after rejection');
}

# Shared body for the recomposition regression below: constructs, reads,
# then calls the conditions *setter* and checks the write actually took
# effect through every reader (->conditions, to_json, is_condition_true,
# get_condition) rather than only checking that the object exists.
sub assert_recomposed_conditions_setter_not_shadowed {
  my ($class, $label) = @_;

  my $obj = $class->new(
    metadata   => { name => 'etcd-0' },
    conditions => [ { type => 'Healthy', status => 'True', message => 'ok' } ],
  );

  is(scalar @{ $obj->conditions }, 1,
    "$label: constructor value is readable through the recomposed role");
  is($obj->conditions->[0]->type, 'Healthy',
    "$label: constructor value keeps its data before the setter runs");

  $obj->conditions([ { type => 'Degraded', status => 'False', message => 'x' } ]);

  is(scalar @{ $obj->conditions }, 1,
    "$label: setter still reports exactly one condition");
  is($obj->conditions->[0]->type, 'Degraded',
    "$label: setter's new element replaces the old one instead of being a silent no-op");

  is_deeply($obj->TO_JSON->{conditions},
    [ { type => 'Degraded', status => 'False', message => 'x' } ],
    "$label: to_json reflects the new element, not the constructor's 'Healthy'");

  ok(!$obj->is_condition_true('Degraded'),
    "$label: is_condition_true sees the new element's status => False");
  ok($obj->get_condition('Degraded'),
    "$label: get_condition finds the element the setter wrote");
}

{
  package TestK144::MethodCollision::IsReady;
  use IO::K8s::APIObject
    api_version => 'test.example.com/v1',
    resource_plural => 'isreadycollisions';
}

{
  package TestK144::MethodCollision::SetOwner;
  use IO::K8s::APIObject
    api_version => 'test.example.com/v1',
    resource_plural => 'setownercollisions';
}

{
  package TestK144::Conditions::Custom;
  use IO::K8s::APIObject
    api_version => 'test.example.com/v1',
    resource_plural => 'customconditions';
}

# Two subclasses of the real, shipped ComponentStatus that each recompose
# IO::K8s::Role::APIObject a second time -- one through the same
# `use IO::K8s::APIObject` import ComponentStatus itself uses, one through a
# bare `with`. Role::Tiny installs a role's methods by checking the TARGET
# package's own stash, not what it inherits, so both routes put the role's
# `conditions` helper back into the subclass's own stash even though
# ComponentStatus (the parent) already removed that very helper from its own
# stash when it declared `conditions` as a k8s field (see _declare_field's
# `remove_symbol` above). A plain Perl method call to $obj->conditions(...)
# then resolves to the subclass's own stash first, ahead of the inherited
# Moo accessor -- so a setter call reaches the role's getter-only helper
# instead, and silently does nothing.
{
  package TestK144::ComponentStatusRecomposed::ViaImport;
  use IO::K8s::APIObject
    api_version => 'v1',
    resource_plural => 'componentstatuses';
  extends 'IO::K8s::Api::Core::V1::ComponentStatus';
}

{
  package TestK144::ComponentStatusRecomposed::ViaWith;
  use Moo;
  extends 'IO::K8s::Api::Core::V1::ComponentStatus';
  with 'IO::K8s::Role::APIObject';
}

# k144's decision (main agent, k144 follow-up): `conditions` is the one
# APIObject helper a same-named declared wire field is allowed to replace --
# IO::K8s::Api::Core::V1::ComponentStatus already ships an upstream
# top-level `conditions` field (unlike Pod, whose conditions live under
# `status`), so the field must win rather than being rejected. Declaring it
# here happens at runtime, inside eval, rather than in the package block
# above: until that decision is implemented in the shared lib, this call
# croaks exactly like the MethodCollision packages above, and an uncaught
# croak here would abort the whole file before any subtest -- including the
# unrelated ones below -- got to run.
my $custom_conditions_error;
eval {
  TestK144::Conditions::Custom->can('k8s')->(
    conditions => ['Core::V1::ComponentCondition']
  );
  1;
} or $custom_conditions_error = $@;

{
  package TestK144::Sanitized::DashThenUnder;
  use IO::K8s::Resource;
  k8s 'x-value' => Str;
}

{
  package TestK144::Sanitized::UnderThenDash;
  use IO::K8s::Resource;
  k8s x_value => Str;
}

{
  package TestK144::Sanitized::InheritedDash;
  use IO::K8s::Resource;
  k8s 'x-value' => Str;
}

{
  package TestK144::Sanitized::InheritedDashChild;
  use IO::K8s::Resource;
  extends 'TestK144::Sanitized::InheritedDash';
}

{
  package TestK144::Sanitized::InheritedUnder;
  use IO::K8s::Resource;
  k8s x_value => Str;
}

{
  package TestK144::Sanitized::InheritedUnderChild;
  use IO::K8s::Resource;
  extends 'TestK144::Sanitized::InheritedUnder';
}

{
  package TestK144::Metadata::Static;
  use IO::K8s::APIObject
    api_version => 'test.example.com/v1',
    resource_plural => 'metadatas';
  k8s spec => Opaque;
}

{
  package TestK144::Metadata::Inherited;
  use Moo;
  extends 'TestK144::Metadata::Static';
}

{
  package TestK144::Override::Base;
  use IO::K8s::Resource;
  k8s state => Bool, 'required';
  k8s 'wire-value' => Bool;
}

{
  package TestK144::Override::Child;
  use IO::K8s::Resource;
  extends 'TestK144::Override::Base';
  k8s state => Str;
  k8s 'wire-value' => Str;
}

# Claim (k144, revised): a wire field must never silently resolve to an
# APIObject role helper that has no notion of yielding to it. `conditions`
# used to be tested here too, but IO::K8s::Api::Core::V1::ComponentStatus
# ships an upstream, top-level `conditions` field (see the subtests below)
# -- proof that `conditions` is a legitimate wire field name, not merely an
# accessor IO::K8s::Role::APIObject happens to define. Every other
# non-yielding helper keeps the strict rejection this subtest checks.
subtest 'a field colliding with a non-yielding APIObject helper is rejected atomically' => sub {
  assert_rejected_declaration(
    'TestK144::MethodCollision::IsReady',
    'is_ready',
    'is_ready colliding with the APIObject helper'
  );
  assert_rejected_declaration(
    'TestK144::MethodCollision::SetOwner',
    'set_owner',
    'set_owner colliding with the APIObject helper'
  );
};

# Claim: a class that declares its own `conditions` wire field gets that
# field's data back from ->conditions, to_json, and every condition helper
# -- the field wins over IO::K8s::Role::APIObject's status-derived helper
# instead of being silently emptied by it.
subtest 'a declared conditions field wins over the APIObject helper and keeps its data' => sub {
  if ($custom_conditions_error) {
    fail("declaring 'conditions' as a wire field on an APIObject failed: $custom_conditions_error");
    return;
  }

  my $obj = TestK144::Conditions::Custom->new(
    conditions => [ { type => 'Healthy', status => 'True', message => 'ok' } ]
  );

  is(scalar @{ $obj->conditions }, 1,
    'conditions keeps the declared data instead of being emptied by the helper');
  isa_ok($obj->conditions->[0], 'IO::K8s::Api::Core::V1::ComponentCondition',
    'the declared field inflates its element type');
  is($obj->conditions->[0]->type, 'Healthy', 'element data is preserved');

  is_deeply($obj->TO_JSON->{conditions},
    [ { type => 'Healthy', status => 'True', message => 'ok' } ],
    'to_json emits the declared conditions, not []');

  ok($obj->is_condition_true('Healthy'), 'is_condition_true reads the declared field');
  is($obj->condition_message('Healthy'), 'ok', 'condition_message reads the declared field');
  my $cond = $obj->get_condition('Healthy');
  ok($cond, 'get_condition finds the element');
  is($cond->type, 'Healthy', 'get_condition returns the matching element')
    if $cond;
};

# Claim: the real shipped collision k144 was found from -- ComponentStatus's
# upstream `conditions` field -- round-trips byte-identically and every
# condition helper works on it, instead of inflate/new silently discarding
# conditions the way HEAD does before the fix (->conditions => [],
# to_json => "conditions":[]).
subtest 'ComponentStatus ships the upstream conditions field and round-trips it' => sub {
  my $k8s = IO::K8s->new;
  my $wire = {
    apiVersion => 'v1',
    kind       => 'ComponentStatus',
    metadata   => { name => 'etcd-0' },
    conditions => [ { type => 'Healthy', status => 'True', message => 'ok' } ],
  };

  my $cs = eval { $k8s->inflate($wire) };
  if (my $err = $@) {
    fail("inflating ComponentStatus failed: $err");
    return;
  }

  isa_ok($cs, 'IO::K8s::Api::Core::V1::ComponentStatus');
  is(scalar @{ $cs->conditions }, 1,
    'conditions is preserved, not dropped to [] (the k144 bug report)');
  isa_ok($cs->conditions->[0], 'IO::K8s::Api::Core::V1::ComponentCondition');
  is($cs->conditions->[0]->type, 'Healthy', 'inflated element data is preserved');

  my $first_json = $cs->to_json;
  is_deeply(decode_json($first_json)->{conditions},
    [ { type => 'Healthy', status => 'True', message => 'ok' } ],
    'to_json writes the conditions data, not "conditions":[]');

  my $roundtripped = $k8s->inflate($first_json);
  is($roundtripped->to_json, $first_json,
    'inflate -> to_json -> inflate -> to_json is byte-identical (canonical JSON)');

  ok($cs->is_condition_true('Healthy'), 'is_condition_true works on ComponentStatus');
  is($cs->condition_message('Healthy'), 'ok', 'condition_message works on ComponentStatus');
  ok($cs->get_condition('Healthy'), 'get_condition works on ComponentStatus');
};

# Claim: a subclass that recomposes IO::K8s::Role::APIObject over
# ComponentStatus still has `conditions` as its field, not the role's
# read-only helper -- the setter must actually change the value, the same
# way it does on ComponentStatus itself, through every reader
# (->conditions, to_json, is_condition_true, get_condition). Both
# recomposition routes reproduce the same collision, since Role::Tiny
# installs role methods by looking only at the target package's own stash.
subtest 'a subclass recomposing IO::K8s::Role::APIObject keeps the conditions setter working, not just the getter' => sub {
  assert_recomposed_conditions_setter_not_shadowed(
    'TestK144::ComponentStatusRecomposed::ViaImport',
    'recomposed via the IO::K8s::APIObject import'
  );
  assert_recomposed_conditions_setter_not_shadowed(
    'TestK144::ComponentStatusRecomposed::ViaWith',
    'recomposed via a bare with IO::K8s::Role::APIObject'
  );
};

# Guard: IO::K8s::Api::Core::V1::ComponentStatus itself composes the role
# exactly once and removes the role's helper from its own stash when it
# declares `conditions` as a k8s field (no recomposition, no shadowing), so
# its setter already works today. This must stay green across the fix for
# the recomposed subclasses above.
subtest 'the base ComponentStatus setter (no role recomposition) already works' => sub {
  my $k8s = IO::K8s->new;
  my $cs = $k8s->new_object('ComponentStatus',
    metadata   => { name => 'etcd-0' },
    conditions => [ { type => 'Healthy', status => 'True', message => 'ok' } ],
  );

  $cs->conditions([ { type => 'Degraded', status => 'False', message => 'x' } ]);

  is($cs->conditions->[0]->type, 'Degraded',
    'base class setter replaces the element (no recomposition, no shadowing)');
  ok($cs->get_condition('Degraded'), 'base class get_condition finds the new element');
  ok(!$cs->is_condition_true('Degraded'), 'base class is_condition_true reflects status => False');
};

# Guard: the ComponentStatus and custom-class cases above give `conditions`
# a top-level wire field. Pod does not -- its conditions live under
# `status` -- so it must keep going through IO::K8s::Role::APIObject's
# status-extraction helper exactly as before k144 (same behaviour t/14_role_
# conditions.t exercises directly against the helper).
subtest 'a Pod without a top-level conditions field still reads status.conditions' => sub {
  my $k8s = IO::K8s->new;
  my $pod = $k8s->new_object('Pod',
    metadata => { name => 'guard-pod' },
    status => {
      conditions => [
        { type => 'Ready', status => 'True', message => 'pod is ready' },
      ],
    },
  );

  is(scalar @{ $pod->conditions }, 1,
    'Pod conditions still comes from status.conditions, not a top-level field');
  isa_ok($pod->conditions->[0], 'IO::K8s::Api::Core::V1::PodCondition');
  ok($pod->is_ready, 'is_ready still true via status.conditions');
  is($pod->condition_message('Ready'), 'pod is ready',
    'condition_message still reads status.conditions');
  my $cond = $pod->get_condition('Ready');
  ok($cond, 'get_condition still finds the status condition');
};

# Claim: distinct JSON keys that sanitize to one accessor must be rejected in
# either declaration order, including when the first declaration is inherited.
subtest 'sanitized accessor collisions are rejected atomically in every order' => sub {
  # Claim: x-value followed by x_value is two distinct wire fields, not an override.
  assert_rejected_declaration(
    'TestK144::Sanitized::DashThenUnder',
    'x_value',
    'x-value then x_value'
  );

  # Claim: the reverse spelling order has the identical rejection contract.
  assert_rejected_declaration(
    'TestK144::Sanitized::UnderThenDash',
    'x-value',
    'x_value then x-value'
  );

  # Claim: a child cannot claim a parent accessor through a different wire key.
  assert_rejected_declaration(
    'TestK144::Sanitized::InheritedDashChild',
    'x_value',
    'inherited x-value then child x_value'
  );

  # Claim: inherited collision detection is independent of the first spelling.
  assert_rejected_declaration(
    'TestK144::Sanitized::InheritedUnderChild',
    'x-value',
    'inherited x_value then child x-value'
  );
};

# Claim: metadata is the intentional role-owned exception, not a declaration
# collision, and remains constructible for static, generated, and inherited
# API objects.
subtest 'metadata stays available through APIObject, AutoGen, and inheritance' => sub {
  my $static = TestK144::Metadata::Static->new(
    metadata => { name => 'static' },
    spec => { enabled => 'yes' }
  );
  isa_ok($static->metadata,
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
    'static APIObject metadata is coerced');
  is($static->TO_JSON->{metadata}{name}, 'static',
    'static APIObject metadata reaches the wire');

  my $inherited = TestK144::Metadata::Inherited->new(
    metadata => { name => 'inherited' }
  );
  isa_ok($inherited->metadata,
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
    'inherited APIObject metadata is coerced');
  is($inherited->TO_JSON->{metadata}{name}, 'inherited',
    'inherited APIObject metadata reaches the wire');

  my $generated = IO::K8s::AutoGen::get_or_generate(
    'test.example.v1.K144Metadata',
    {
      type => 'object',
      'x-kubernetes-group-version-kind' => [{
        group => 'test.example.com', version => 'v1', kind => 'K144Metadata'
      }],
      properties => { spec => { type => 'object', properties => {} } }
    },
    {},
    'IO::K8s::_AUTOGEN_k144_metadata',
    api_version => 'test.example.com/v1',
    kind => 'K144Metadata',
    resource_plural => 'k144metadatas',
    is_namespaced => 1
  );
  my $generated_object = $generated->new(metadata => { name => 'generated' });
  isa_ok($generated_object->metadata,
    'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta',
    'generated APIObject metadata is coerced');
  is($generated_object->TO_JSON->{metadata}{name}, 'generated',
    'generated APIObject metadata reaches the wire');
};

# Claim: a same-wire-key child declaration is a real nearest-wins replacement:
# its constructor, setter, requiredness, coercion, and init_arg follow Str,
# while the parent remains Bool.
subtest 'nearest-wins replaces the effective Moo attribute, not only registry metadata' => sub {
  my $child;
  lives_ok {
    $child = TestK144::Override::Child->new(
      state => 'not-a-boolean',
      'wire-value' => 'wire-text'
    );
  } 'child constructor accepts non-boolean text for its Str override';
  is($child->state, 'not-a-boolean',
    'child constructor preserves the Str value instead of Bool-normalizing it');
  is($child->wire_value, 'wire-text',
    'child constructor retains the JSON init_arg for the sanitized Str override');

  lives_ok { $child->state('setter-text') }
    'child setter accepts non-boolean text for its Str override';
  is($child->state, 'setter-text',
    'child setter preserves non-boolean text instead of Bool-normalizing it');
  is($child->TO_JSON->{'wire-value'}, 'wire-text',
    'child override emits its declared JSON init_arg');

  lives_ok { TestK144::Override::Child->new }
    'child Str override is not required merely because its Bool parent was';

  my $child_specs = Moo->_constructor_maker_for('TestK144::Override::Child')
    ->all_attribute_specs;
  ok(!$child_specs->{state}{required},
    'child constructor spec does not retain the parent required flag');
  ok(!$child_specs->{state}{coerce},
    'child constructor spec does not retain the parent Bool coercer');
  is($child_specs->{wire_value}{init_arg}, 'wire-value',
    'child constructor spec keeps its own sanitized JSON init_arg');

  my $base = TestK144::Override::Base->new(state => 'false');
  is(ref($base->TO_JSON->{state}), 'JSON::PP::Boolean',
    'base declaration remains a Bool on the wire');
  is($base->TO_JSON->{state}, 0,
    'base Bool still normalizes false');
};

done_testing;
