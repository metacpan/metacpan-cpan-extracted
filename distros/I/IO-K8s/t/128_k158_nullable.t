#!/usr/bin/env perl
# k158, part 1: a field declared nullable => 1 keeps an explicit JSON null.
#
# Claims, all checked on the wire JSON and not only on Perl values:
#   * a nullable field accepts undef at construction and in the setter, and a
#     field present with undef serializes as null; an absent field stays
#     absent -- only nullable fields make that difference;
#   * every inflate entry point keeps a null for a nullable field (nested
#     too) and still drops it for every other field;
#   * a nullable field, and only a nullable field, gets has_<accessor>
#     ("the key exists", null included) and clear_<accessor> ("make it
#     absent again"); the k144 declaration preflight checks both names;
#   * required => 1 plus nullable is allowed and null satisfies it;
#   * spec_set to undef means "present with null", spec_delete removes it;
#   * the shipped ExternalSecrets refreshTime (nullable upstream) round-trips
#     a server's refreshTime: null as null;
#   * AutoGen's nullable: true mapping gets the same runtime behaviour.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::MaybeXS qw( decode_json );
use JSON::PP ();

use IO::K8s;
use IO::K8s::AutoGen;
use IO::K8s::ExternalSecrets;

{
  package Test158::Upstream;
  use IO::K8s::Resource;

  k8s class => Str;

  1;
}

{
  package Test158::Spec;
  use IO::K8s::Resource;

  k8s class    => Str, { required => 1 };
  k8s upstream => Opaque, { nullable => 1, preserve_unknown => 1 };  # k191: the opaque map is Opaque
  k8s target   => '+Test158::Upstream', { nullable => 1 };
  k8s note     => Str, { nullable => 1 };
  k8s tags     => [Str], { nullable => 1 };
  k8s plain    => Str;
  k8s child    => '+Test158::Upstream';
  k8s inline   => { mode => [ Str, { nullable => 1 } ], size => Int };

  1;
}

{
  package Test158::Must;
  use IO::K8s::Resource;

  k8s choice => Str, { required => 1, nullable => 1 };

  1;
}

{
  package Test158::NullThing;
  use IO::K8s::APIObject
    api_version     => 'k158.example.com/v1',
    resource_plural => 'nullthings';
  with 'IO::K8s::Role::Namespaced';

  k8s spec => '+Test158::Spec';

  1;
}

my $JSON = JSON::MaybeXS->new(canonical => 1, utf8 => 1);

# -- predicates and clearers ------------------------------------------------

subtest 'has_ and clear_ exist for nullable fields only' => sub {
  for my $field (qw( upstream target note tags )) {
    ok(Test158::Spec->can('has_'.$field), 'has_'.$field.' for the nullable '.$field);
    ok(Test158::Spec->can('clear_'.$field), 'clear_'.$field.' for the nullable '.$field);
  }
  for my $field (qw( class plain child inline )) {
    ok(!Test158::Spec->can('has_'.$field), 'no has_'.$field.' for the non-nullable '.$field);
    ok(!Test158::Spec->can('clear_'.$field), 'no clear_'.$field.' for the non-nullable '.$field);
  }
  ok(Test158::Spec::_Inline->can('has_mode'), 'inside an inline struct too');
  ok(!Test158::Spec::_Inline->can('has_size'), 'but not for its other fields');
  ok(Test158::Must->can('has_choice'), 'required plus nullable gets one as well');
};

# -- construction, setter, clearer, TO_JSON ---------------------------------

subtest 'present with undef is null on the wire, absent stays absent' => sub {
  my $null = Test158::Spec->new(class => 'X', upstream => undef);
  ok($null->has_upstream, 'has_upstream: the key exists');
  ok(!defined $null->upstream, 'its value is undef');
  is($null->to_json, '{"class":"X","upstream":null}', 'to_json writes null');
  my $data = $null->TO_JSON;
  ok(exists $data->{upstream} && !defined $data->{upstream}, 'TO_JSON carries the key with undef');

  my $absent = Test158::Spec->new(class => 'X');
  ok(!$absent->has_upstream, 'absent: has_upstream is false');
  is($absent->to_json, '{"class":"X"}', 'absent: no key on the wire');

  my $all = Test158::Spec->new(class => 'X', upstream => undef, target => undef,
    note => undef, tags => undef, plain => undef, child => undef);
  is($all->to_json, '{"class":"X","note":null,"tags":null,"target":null,"upstream":null}',
    'every nullable shape writes null, the non-nullable plain and child stay omitted');

  my $set = Test158::Spec->new(class => 'X', upstream => { class => 'A' }, target => { class => 'B' });
  isa_ok($set->target, 'Test158::Upstream', 'a hashref for a nullable object field is still coerced');
  is($set->to_json, '{"class":"X","target":{"class":"B"},"upstream":{"class":"A"}}',
    'defined values serialize as before');
};

subtest 'the setter writes null, the clearer makes the field absent again' => sub {
  my $spec = Test158::Spec->new(class => 'X');
  $spec->upstream(undef);
  ok($spec->has_upstream, 'setter undef: the key exists');
  is($spec->to_json, '{"class":"X","upstream":null}', 'setter undef: null on the wire');
  $spec->clear_upstream;
  ok(!$spec->has_upstream, 'clear_upstream: the key is gone');
  is($spec->to_json, '{"class":"X"}', 'clear_upstream: nothing on the wire');
  $spec->target({ class => 'C' });
  isa_ok($spec->target, 'Test158::Upstream', 'the setter still coerces a defined value');
  $spec->plain(undef);
  is($spec->to_json, '{"class":"X","target":{"class":"C"}}', 'a non-nullable field set to undef stays omitted');
};

subtest 'required plus nullable: null satisfies required' => sub {
  throws_ok { Test158::Must->new } qr/choice/, 'a missing key still fails required';
  my $must;
  lives_ok { $must = Test158::Must->new(choice => undef) } 'an explicit undef passes';
  ok($must->has_choice, 'and exists');
  is($must->to_json, '{"choice":null}', 'written as null');
  is(Test158::Must->FROM_HASH({ choice => undef })->to_json, '{"choice":null}',
    'FROM_HASH keeps the null and satisfies required with it');
  is(Test158::Must->new(choice => 'x')->to_json, '{"choice":"x"}', 'a value works as before');
};

# -- every inflate entry point ----------------------------------------------

my %doc = (
  apiVersion => 'k158.example.com/v1',
  kind       => 'NullThing',
  metadata   => { name => 't' },
  spec       => {
    class    => 'X',
    upstream => undef,
    target   => undef,
    note     => undef,
    tags     => undef,
    plain    => undef,
    child    => undef,
    inline   => { mode => undef, size => undef },
  },
);
my $want_spec = '{"class":"X","inline":{"mode":null},"note":null,"tags":null,"target":null,"upstream":null}';

sub spec_wire {
  my ($obj) = @_;
  my $data = decode_json($obj->to_json);
  return $JSON->encode($data->{spec});
}

subtest 'every inflate entry keeps null for nullable fields and drops it otherwise' => sub {
  my $k8s = IO::K8s->new;
  $k8s->add({ NullThing => '+Test158::NullThing' });
  my $json = $JSON->encode(\%doc);

  my %built = (
    'inflate(hashref)'          => $k8s->inflate({ %doc }),
    'inflate(json)'             => $k8s->inflate($json),
    'new_object'                => $k8s->new_object('NullThing', { %doc }),
    'struct_to_object(class)'   => $k8s->struct_to_object('NullThing', { %doc }),
    'struct_to_object(hashref)' => $k8s->struct_to_object({ %doc }),
    'json_to_object(class)'     => $k8s->json_to_object('NullThing', $json),
    'json_to_object(json)'      => $k8s->json_to_object($json),
    'FROM_HASH'                 => Test158::NullThing->FROM_HASH({ %doc }),
    'from_json'                 => Test158::NullThing->from_json($json),
    'constructor coercion'      => Test158::NullThing->new(metadata => { name => 't' }, spec => { %{ $doc{spec} } }),
  );
  for my $entry (sort keys %built) {
    my $obj = $built{$entry};
    is(spec_wire($obj), $want_spec, $entry.': null kept for nullable fields only, nested included');
    ok($obj->spec->has_upstream, $entry.': has_upstream');
    ok($obj->spec->inline->has_mode, $entry.': has_mode inside the inline struct');
  }
};

subtest 'strict mode is about unknown keys, not nulls' => sub {
  my $k8s = IO::K8s->new(strict => 1);
  $k8s->add({ NullThing => '+Test158::NullThing' });
  my $obj;
  lives_ok { $obj = $k8s->inflate({ %doc }) } 'a null for a declared field is no unknown field';
  is(spec_wire($obj), $want_spec, 'and is kept the same way');
};

subtest 'to_yaml writes null as well' => sub {
  my $spec = Test158::Spec->new(class => 'X', upstream => undef);
  like($spec->to_yaml, qr/^upstream: null$/m, 'upstream: null');
};

# -- SpecBuilder ------------------------------------------------------------

subtest 'spec_set to undef is present with null, spec_delete removes the key' => sub {
  my $thing = Test158::NullThing->new(metadata => { name => 't' }, spec => { class => 'X' });
  $thing->spec_set('upstream', undef);
  ok($thing->spec->has_upstream, 'spec_set undef: the key exists');
  is(spec_wire($thing), '{"class":"X","upstream":null}', 'spec_set undef: null on the wire');
  $thing->spec_delete('upstream');
  ok(!$thing->spec->has_upstream, 'spec_delete: the key is gone');
  is(spec_wire($thing), '{"class":"X"}', 'spec_delete: nothing on the wire');

  $thing->spec_set('inline.mode', undef);
  is(spec_wire($thing), '{"class":"X","inline":{"mode":null}}', 'nested: spec_set undef writes null');
  $thing->spec_delete('inline.mode');
  is(spec_wire($thing), '{"class":"X","inline":{}}', 'nested: spec_delete removes it');

  $thing->spec_set('plain', 'p');
  $thing->spec_delete('plain');
  is(spec_wire($thing), '{"class":"X","inline":{}}', 'a non-nullable field is cleared as before');
};

# -- declaration preflight (k144) -------------------------------------------

sub registry_for { +{ %{ $IO::K8s::Resource::_attr_registry{ $_[0] } // {} } } }

{
  package Test158::HasMethod;
  use IO::K8s::Resource;
  sub has_extra { 'mine' }
  1;
}
{
  package Test158::ClearMethod;
  use IO::K8s::Resource;
  sub clear_extra { 'mine' }
  1;
}
{
  package Test158::FieldFirst;
  use IO::K8s::Resource;
  k8s has_bar => Str;
  1;
}
{
  package Test158::NullableFirst;
  use IO::K8s::Resource;
  k8s foo => Str, { nullable => 1 };
  1;
}
{
  package Test158::PlainWithMethod;
  use IO::K8s::Resource;
  sub has_baz { 'mine' }
  1;
}

subtest 'the declaration preflight checks the predicate and clearer names' => sub {
  my $before = registry_for('Test158::HasMethod');
  throws_ok { Test158::HasMethod::k8s(extra => 'Str', { nullable => 1 }) }
    qr/field 'extra' of Test158::HasMethod.*'has_extra'/,
    'a method named like the predicate is refused, naming field and method';
  is_deeply(registry_for('Test158::HasMethod'), $before, 'and leaves the registry alone');
  is(Test158::HasMethod->has_extra, 'mine', 'the method is untouched');

  throws_ok { Test158::ClearMethod::k8s(extra => 'Str', { nullable => 1 }) }
    qr/field 'extra' of Test158::ClearMethod.*'clear_extra'/,
    'a method named like the clearer is refused as well';

  throws_ok { Test158::FieldFirst::k8s(bar => 'Str', { nullable => 1 }) }
    qr/field 'bar' of Test158::FieldFirst.*'has_bar'/,
    'a field whose accessor is the predicate name is refused';

  throws_ok { Test158::NullableFirst::k8s(has_foo => 'Str') }
    qr/field 'has_foo' of Test158::NullableFirst collides with the method 'has_foo'/,
    'a later field taking the predicate name is refused by the method check';

  lives_ok { Test158::PlainWithMethod::k8s(baz => 'Str') }
    'a non-nullable field has no predicate and does not collide';
  is(Test158::PlainWithMethod->has_baz, 'mine', 'and the method stays');

  lives_ok { Test158::NullableFirst::k8s(foo => 'Str', { nullable => 1 }) }
    'an identical redeclaration in the same class is still a no-op';
};

{
  package Test158::Parent;
  use IO::K8s::Resource;
  k8s note => Str, { nullable => 1 };
  1;
}
{
  package Test158::Child;
  use IO::K8s::Resource;
  extends 'Test158::Parent';
  k8s note => Str, { nullable => 1, description => 'redeclared' };
  1;
}

subtest 'a subclass redeclares an inherited nullable field' => sub {
  my $child = Test158::Child->new(note => undef);
  ok($child->has_note, 'the inherited predicate name is the field\'s own again');
  is($child->to_json, '{"note":null}', 'null on the wire from the subclass');
  $child->clear_note;
  is($child->to_json, '{}', 'cleared');
};

# -- shipped classes: ExternalSecrets refreshTime ---------------------------

subtest 'refreshTime: null from the server round-trips as null' => sub {
  my $k8s = IO::K8s->new(with => ['IO::K8s::ExternalSecrets']);
  for my $case (
    [ 'external-secrets.io/v1',       'ExternalSecret' ],
    [ 'external-secrets.io/v1alpha1', 'PushSecret' ],
  ) {
    my ($api_version, $kind) = @$case;
    my $json = $JSON->encode({
      apiVersion => $api_version, kind => $kind, metadata => { name => 'es' },
      status     => { refreshTime => undef, syncedResourceVersion => undef },
    });
    my $obj = $k8s->inflate($json);
    ok($obj->status->has_refreshTime, $kind.': has_refreshTime');
    is($JSON->encode(decode_json($obj->to_json)->{status}), '{"refreshTime":null}',
      $kind.': refreshTime null kept, the non-nullable syncedResourceVersion null dropped');

    my $set = $k8s->inflate($JSON->encode({
      apiVersion => $api_version, kind => $kind, metadata => { name => 'es' },
      status     => { refreshTime => '2026-09-27T00:00:00Z' },
    }));
    is(decode_json($set->to_json)->{status}{refreshTime}, '2026-09-27T00:00:00Z', $kind.': a time still works');
    my $absent = $k8s->inflate($JSON->encode({
      apiVersion => $api_version, kind => $kind, metadata => { name => 'es' }, status => {},
    }));
    ok(!$absent->status->has_refreshTime, $kind.': absent stays absent');
    is(decode_json($absent->to_json)->{status} && $JSON->encode(decode_json($absent->to_json)->{status}), '{}',
      $kind.': and is not written');
  }
};

# -- AutoGen ----------------------------------------------------------------

subtest 'AutoGen: nullable: true gets the runtime behaviour, false does not' => sub {
  my $class = IO::K8s::AutoGen::get_or_generate('k158.Nullables', {
    type       => 'object',
    properties => {
      yes   => { type => 'string', nullable => JSON::PP::true() },
      no    => { type => 'string', nullable => JSON::PP::false() },
      quote => { type => 'string', nullable => 'false' },
      obj   => { type => 'object', nullable => JSON::PP::true(), properties => { a => { type => 'string' } } },
    },
  }, {}, 'IO::K8s::_AUTOGEN_k158');
  ok($class->can('has_yes'), 'nullable: true gets the predicate');
  ok(!$class->can('has_no') && !$class->can('has_quote'), 'false and the string "false" do not');
  my $obj = $class->FROM_HASH({ yes => undef, no => undef, quote => undef, obj => undef });
  is($obj->to_json, '{"obj":null,"yes":null}', 'nulls kept for the nullable properties only');
};

done_testing;
