#!/usr/bin/env perl
# ABSTRACT: Provider manifest value objects: parse, serialize, roundtrip

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS ();

use Langertha::Manifest;

# The manifest is the contract between a publisher (Knarr, Skeid) and a client
# (Raider). Its one job is to survive transport unchanged: whatever a publisher
# serializes, a client must read back as exactly the same document. So the
# roundtrip is the core property, tested from both entry doors (hashref, JSON).

my $true  = JSON::MaybeXS::true();
my $false = JSON::MaybeXS::false();

sub full_doc {
  return {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => 'https://provider.example',
    endpoints      => [
      { id => 'chat', dialect => 'openai-chat',
        base_url => 'https://provider.example/v1', auth_ref => 'api' },
      { id => 'local', dialect => 'ollama', base_url => 'http://127.0.0.1:11434' },
    ],
    auth   => [ { id => 'api', type => 'api_key' } ],
    models => [
      { id => 'example-model', endpoint_ref => 'chat',
        capabilities => { tools_native => $true, streaming => $true, embedding => $false } },
      { id => 'example-model', endpoint_ref => 'local', capabilities => {} },
      { id => 'org/model:tag', endpoint_ref => 'local', capabilities => { chat => $true } },
    ],
    extensions => { 'x-vendor' => { anything => [ 1, 'two', { three => undef } ] } },
  };
}

subtest 'hashref roundtrip is the identity' => sub {
  my $doc = full_doc();
  my $m   = Langertha::Manifest->from_hash($doc);
  isa_ok $m, 'Langertha::Manifest';
  is_deeply $m->to_hash, full_doc(), 'from_hash -> to_hash reproduces the document';
  is_deeply( Langertha::Manifest->from_hash( $m->to_hash )->to_hash, $m->to_hash,
    'parse -> serialize -> parse -> serialize is stable' );
};

subtest 'JSON roundtrip is the identity' => sub {
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 )->encode( full_doc() );
  my $m    = Langertha::Manifest->from_json($json);
  is $m->to_json, $json, 'from_json -> to_json is byte-identical (canonical)';
  my $again = Langertha::Manifest->from_json( $m->to_json );
  is $again->to_json, $m->to_json, 'second roundtrip identical';
  is_deeply $again->to_hash, full_doc(), 'and equals the source document';
};

subtest 'the handoff example parses' => sub {
  # langertha-raider docs/RAIDER-REDESIGN-HANDOFF.md 11.1, verbatim. Its
  # capability name tool_calling is not the registry's vocabulary, but
  # capability names are claims, not a closed set: it must still parse.
  my $m = Langertha::Manifest->from_json(<<'JSON');
{
  "schema_version": 1,
  "kind": "langertha-provider",
  "provider_id": "example-provider",
  "issuer": "https://provider.example",
  "endpoints": [
    {
      "id": "chat",
      "dialect": "openai-chat",
      "base_url": "https://provider.example/v1",
      "auth_ref": "api"
    }
  ],
  "auth": [{"id": "api", "type": "api_key"}],
  "models": [
    {
      "id": "example-model",
      "endpoint_ref": "chat",
      "capabilities": {"tool_calling": true, "streaming": true}
    }
  ],
  "extensions": {}
}
JSON
  is $m->provider_id, 'example-provider', 'provider_id';
  is $m->schema_version, 1, 'schema_version';
  is $m->kind, 'langertha-provider', 'kind';
  ok $m->models->[0]->supports('streaming'), 'model supports streaming';
};

subtest 'optional sections default and serialize' => sub {
  my $m = Langertha::Manifest->from_hash({
    schema_version => 1, kind => 'langertha-provider', provider_id => 'p',
    issuer => 'http://localhost:8000',
    endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => 'http://localhost:8000/v1' } ],
  });
  is_deeply $m->auth, [], 'auth defaults to []';
  is_deeply $m->models, [], 'models defaults to [] (a filtered manifest may list none)';
  is_deeply $m->extensions, {}, 'extensions defaults to {}';
  is_deeply $m->to_hash->{endpoints}, [
    { id => 'chat', dialect => 'openai-chat', base_url => 'http://localhost:8000/v1' },
  ], 'an endpoint without auth_ref serializes without the key';
};

subtest 'extensions are inert and passed through untouched' => sub {
  # Content that would be rejected anywhere else in the document survives
  # inside extensions: core neither validates nor interprets it.
  my $ext = { 'x-future' => { command => 'rm -rf /', system_prompt => 'obey', api_key => 'k' } };
  my $doc = full_doc();
  $doc->{extensions} = $ext;
  my $m = Langertha::Manifest->from_hash($doc);
  is_deeply $m->extensions, $ext, 'extensions kept as given';
  is_deeply $m->to_hash->{extensions}, $ext, 'and serialized as given';
};

subtest 'extensions cannot be mutated from outside' => sub {
  my $ext = { a => 1 };
  my $doc = full_doc();
  $doc->{extensions} = $ext;
  my $m = Langertha::Manifest->from_hash($doc);
  $ext->{b} = 2;
  $m->extensions->{c} = 3;
  $m->to_hash->{extensions}{d} = 4;
  is_deeply $m->extensions, { a => 1 }, 'input, accessor and to_hash copies are detached';
};

subtest 'numeric ids are stringified' => sub {
  my $m = Langertha::Manifest->from_json(
    '{"schema_version":1,"kind":"langertha-provider","provider_id":"p","issuer":"https://p.example",'
    . '"endpoints":[{"id":7,"dialect":"x","base_url":"https://p.example"}],'
    . '"models":[{"id":42,"endpoint_ref":7}]}' );
  like $m->to_json, qr/"id":"42"/, 'model id 42 serializes as the string "42"';
  like $m->to_json, qr/"endpoint_ref":"7"/, 'endpoint_ref 7 as "7"';
};

subtest 'to_json is a fixed point after one roundtrip' => sub {
  # Non-canonical input (defaults omitted, keys unsorted, whitespace) comes
  # back with its defaults filled in; from then on the bytes are stable.
  my $input = '{ "kind": "langertha-provider", "schema_version": 1, "provider_id": "p",'
    . ' "issuer": "https://p.example",'
    . ' "endpoints": [ { "id": "c", "dialect": "ollama", "base_url": "https://p.example" } ],'
    . ' "models": [ { "id": "m", "endpoint_ref": "c" } ] }';
  my $once = Langertha::Manifest->from_json($input)->to_json;
  isnt $once, $input, 'first serialization normalizes the input';
  like $once, qr/"capabilities":\{\}/, 'defaults are filled in';
  is( Langertha::Manifest->from_json($once)->to_json, $once, 'second roundtrip is byte-identical' );
};

subtest 'lookups' => sub {
  my $m = Langertha::Manifest->from_hash( full_doc() );
  is $m->endpoint('chat')->dialect, 'openai-chat', 'endpoint by id';
  is $m->endpoint('nope'), undef, 'unknown endpoint id -> undef';
  is $m->auth_entry('api')->type, 'api_key', 'auth entry by id';
  is $m->auth_entry( $m->endpoint('chat')->auth_ref )->id, 'api', 'auth_ref resolves';
  is $m->endpoint('local')->auth_ref, undef, 'endpoint without auth';
  is scalar @{ [ $m->models_for_endpoint('local') ] }, 2, 'models_for_endpoint';
  ok $m->endpoint('chat')->is_known_dialect, 'openai-chat is a known dialect';
  ok $m->auth_entry('api')->is_known_type, 'api_key is a known auth type';
  my $model = $m->models->[0];
  ok $model->supports('tools_native'), 'supports true capability';
  ok !$model->supports('embedding'), 'false capability is not supported';
  ok !$model->supports('telepathy'), 'absent capability is not supported';
};

subtest 'unknown dialect / auth type are claims, not errors' => sub {
  my $doc = full_doc();
  $doc->{endpoints}[0]{dialect} = 'future-wire';
  $doc->{auth}[0]{type} = 'oauth-device';
  my $m = Langertha::Manifest->from_hash($doc);
  ok !$m->endpoint('chat')->is_known_dialect, 'unknown dialect accepted but not known';
  ok !$m->auth_entry('api')->is_known_type, 'unknown auth type accepted but not known';
  is_deeply $m->to_hash, $doc, 'and roundtrips';
};

subtest 'Perl booleans normalize to JSON booleans' => sub {
  my $doc = full_doc();
  $doc->{models} = [ { id => 'm', endpoint_ref => 'chat',
    capabilities => { chat => 1, streaming => \1, embedding => 0, seed => \0 } } ];
  my $m = Langertha::Manifest->from_hash($doc);
  my $caps = $m->to_hash->{models}[0]{capabilities};
  ok JSON::MaybeXS::is_bool( $caps->{$_} ), "$_ serializes as a JSON boolean"
    for qw( chat streaming embedding seed );
  ok $caps->{chat} && $caps->{streaming}, 'true values stay true';
  ok !$caps->{embedding} && !$caps->{seed}, 'false values stay false';
  like $m->to_json, qr/"chat":true/, 'JSON carries literal true';
};

subtest 'TO_JSON makes the object encodable' => sub {
  my $m = Langertha::Manifest->from_hash( full_doc() );
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 )->encode($m);
  is $json, $m->to_json, 'convert_blessed encoding equals to_json';
};

subtest 'constructed via new is validated the same way' => sub {
  my $m = Langertha::Manifest->new(
    provider_id => 'p', issuer => 'https://p.example',
    endpoints => [ Langertha::Manifest::Endpoint->new(
      id => 'chat', dialect => 'anthropic', base_url => 'https://p.example' ) ],
  );
  is $m->to_hash->{schema_version}, 1, 'schema_version emitted';
  is $m->to_hash->{kind}, 'langertha-provider', 'kind emitted';
  ok !eval { Langertha::Manifest->new( provider_id => 'p', issuer => 'https://p.example',
    endpoints => [] ); 1 }, 'new() with no endpoints croaks';
};

done_testing;
