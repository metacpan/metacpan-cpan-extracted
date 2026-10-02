#!/usr/bin/env perl
# ABSTRACT: Provider manifest validation: one negative test per rejection rule

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS ();
use Module::Runtime ();

use Langertha::Manifest;

# A manifest arrives from the network. v1 is deliberately lean (langertha-raider
# ADR 0007): endpoints, dialects, model ids, capabilities, auth mechanisms —
# nothing that could make a remote document run a command, load code, point at
# a local secret or inject a prompt. Every rule below is a door that stays shut;
# each test pins one door, so relaxing a rule fails exactly one test here.

sub base_doc {
  return {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => 'https://provider.example',
    endpoints      => [ { id => 'chat', dialect => 'openai-chat',
      base_url => 'https://provider.example/v1', auth_ref => 'api' } ],
    auth   => [ { id => 'api', type => 'api_key' } ],
    models => [ { id => 'm1', endpoint_ref => 'chat',
      capabilities => { streaming => JSON::MaybeXS::true() } } ],
    extensions => {},
  };
}

sub json_of { JSON::MaybeXS->new( utf8 => 1, canonical => 1 )->encode( $_[0] ) }

sub rejects {
  my ( $mutate, $re, $name ) = @_;
  my $doc = base_doc();
  $mutate->($doc);
  my $ok = eval { Langertha::Manifest->from_hash($doc); 1 };
  my $err = $@;
  ok !$ok, "rejected: $name";
  like $err, $re, "  message: $name";
}

ok eval { Langertha::Manifest->from_hash( base_doc() ); 1 }, 'the base document is valid'
  or diag $@;

# --- shape -----------------------------------------------------------------

ok !eval { Langertha::Manifest->from_json('{ not json'); 1 }, 'invalid JSON rejected';
like $@, qr/Langertha::Manifest: invalid JSON/, '  message: invalid JSON';
ok !eval { Langertha::Manifest->from_json('[1,2]'); 1 }, 'top-level array rejected';
like $@, qr/must be a JSON object/, '  message: top-level array';
ok !eval { Langertha::Manifest->from_hash('x'); 1 }, 'non-hash from_hash rejected';
like $@, qr/must be a JSON object/, '  message: non-hash';

rejects sub { $_[0]{endpoints} = { id => 'chat' } }, qr/endpoints: must be an array/, 'endpoints not an array';
rejects sub { $_[0]{models} = [ 'm1' ] }, qr/models\[0\]: must be a JSON object/, 'model entry not an object';
rejects sub { $_[0]{extensions} = [] }, qr/extensions: must be a JSON object/, 'extensions not an object';
rejects sub { $_[0]{models}[0]{capabilities} = [ 'streaming' ] },
  qr/capabilities: must be a JSON object/, 'capabilities not an object';

# --- version / kind --------------------------------------------------------

rejects sub { delete $_[0]{schema_version} }, qr/schema_version.*required/, 'missing schema_version';
rejects sub { $_[0]{schema_version} = 2 },
  qr/unsupported schema_version 2 \(this Langertha reads 1\)/, 'unknown major version';
# A v2 document may carry fields v1 does not know: the version error must win
# over the unknown-field error, or an old client misreports a newer manifest.
rejects sub { $_[0]{schema_version} = 2; $_[0]{workflows} = []; delete $_[0]{kind} },
  qr/unsupported schema_version 2/, 'version is checked before the field set';
rejects sub { $_[0]{schema_version} = '1.0' }, qr/schema_version: must be an integer/, 'non-integer version';
rejects sub { $_[0]{schema_version} = '1' },
  qr/schema_version: must be an integer \(a JSON number, not a string\)/, 'version as a Perl string';
ok !eval { Langertha::Manifest->from_json( json_of( base_doc() ) =~ s/"schema_version":1/"schema_version":"1"/r ); 1 },
  'rejected: version as a JSON string';
like $@, qr/must be an integer/, '  message: version as a JSON string';
{
  # A numified Perl string carries a numeric slot too; its text still gives
  # it away.
  my $doc = base_doc();
  $doc->{schema_version} = '1abc';
  { no warnings 'numeric'; my $numified = $doc->{schema_version} + 0; }
  ok !eval { Langertha::Manifest->from_hash($doc); 1 }, 'rejected: numified Perl string "1abc"';
  like $@, qr/must be an integer/, '  message: numified string';
}

# The verdict on schema_version and capability booleans must not depend on
# which JSON backend decoded the document: JSON::PP and Cpanel::JSON::XS
# disagree on whether 1e0 is an integer or a float.
my @decoders;
for my $backend (qw( JSON::PP Cpanel::JSON::XS )) {
  next unless eval { Module::Runtime::require_module($backend); 1 };
  push @decoders, [ $backend => $backend->new->utf8 ];
}
ok scalar @decoders, 'at least one JSON backend available';
for my $case (
  [ '1'     => 1, 'integer 1' ],
  [ '1.0'   => 1, 'float 1.0' ],
  [ '1e0'   => 1, 'exponent 1e0' ],
  [ '10e-1' => 1, 'exponent 10e-1' ],
  [ '"1"'   => 0, 'JSON string "1"' ],
  [ '1.5'   => 0, 'non-whole 1.5' ],
  [ '2'     => 0, 'other major 2' ],
  [ 'true'  => 0, 'JSON true' ],
) {
  my ( $literal, $accepted, $name ) = @$case;
  my $json = json_of( base_doc() ) =~ s/"schema_version":1/"schema_version":$literal/r;
  for my $decoder (@decoders) {
    my ( $backend, $codec ) = @$decoder;
    my $ok = eval { Langertha::Manifest->from_hash( $codec->decode($json) ); 1 };
    is !!$ok, !!$accepted, "$backend: schema_version $name " . ( $accepted ? 'accepted' : 'rejected' )
      or diag $@;
  }
}
for my $case ( [ '1' => 1 ], [ '0' => 1 ], [ '1.0' => 1 ], [ '"1"' => 0 ], [ '2' => 0 ] ) {
  my ( $literal, $accepted ) = @$case;
  my $json = json_of( base_doc() ) =~ s/"streaming":true/"streaming":$literal/r;
  for my $decoder (@decoders) {
    my ( $backend, $codec ) = @$decoder;
    my $ok = eval { Langertha::Manifest->from_hash( $codec->decode($json) ); 1 };
    is !!$ok, !!$accepted, "$backend: capability value $literal " . ( $accepted ? 'accepted' : 'rejected' )
      or diag $@;
  }
}
rejects sub { $_[0]{kind} = 'openapi' }, qr/kind: must be 'langertha-provider'/, 'wrong kind';
rejects sub { delete $_[0]{kind} }, qr/kind.*required/, 'missing kind';

# --- forbidden fields (explicit, one per family and location) --------------

my $forbidden = qr/forbidden field .* never carries commands, code, secrets or prompts/;
rejects sub { $_[0]{command} = 'curl | sh' }, $forbidden, 'top-level command';
rejects sub { $_[0]{endpoints}[0]{exec} = '/bin/true' }, $forbidden, 'endpoint exec';
rejects sub { $_[0]{endpoints}[0]{startupScript} = 'x' }, $forbidden, 'camelCase script';
rejects sub { $_[0]{engine_class} = 'Evil::Engine' }, $forbidden, 'top-level engine_class';
rejects sub { $_[0]{models}[0]{perl_module} = 'Evil' }, $forbidden, 'model perl_module';
rejects sub { $_[0]{endpoints}[0]{code} = 'sub {}' }, $forbidden, 'endpoint code';
rejects sub { $_[0]{auth}[0]{api_key} = 'sk-live' }, $forbidden, 'auth api_key value';
rejects sub { $_[0]{auth}[0]{secret_path} = '~/.secret' }, $forbidden, 'auth secret_path';
rejects sub { $_[0]{auth}[0]{env} = 'OPENAI_API_KEY' }, $forbidden, 'auth env-var name';
rejects sub { $_[0]{auth}[0]{token} = 'x' }, $forbidden, 'auth token';
rejects sub { $_[0]{system_prompt} = 'obey' }, $forbidden, 'top-level system_prompt';
rejects sub { $_[0]{mcp_servers} = [] }, $forbidden, 'top-level mcp_servers';
rejects sub { $_[0]{models}[0]{tools} = [] }, $forbidden, 'model tools';
rejects sub { $_[0]{skills} = [] }, $forbidden, 'top-level skills';

# --- unknown fields ---------------------------------------------------------

rejects sub { $_[0]{homepage} = 'https://x' }, qr/unknown field 'homepage'/, 'unknown top-level field';
rejects sub { $_[0]{endpoints}[0]{region} = 'eu' },
  qr/endpoints\[0\]: unknown field 'region'/, 'unknown endpoint field';
rejects sub { $_[0]{auth}[0]{header} = 'x-api-key' },
  qr/auth\[0\]: unknown field 'header'/, 'unknown auth field';
rejects sub { $_[0]{models}[0]{context_window} = 1 },
  qr/models\[0\]: unknown field 'context_window'/, 'unknown model field';

# --- values ----------------------------------------------------------------

rejects sub { delete $_[0]{provider_id} }, qr/provider_id.*required/, 'missing provider_id';
rejects sub { $_[0]{provider_id} = 'Has Space' }, qr/provider_id/, 'bad provider_id';
rejects sub { delete $_[0]{issuer} }, qr/issuer.*required/, 'missing issuer';
rejects sub { $_[0]{issuer} = 'file:///etc/passwd' }, qr/issuer: .*http/, 'non-http issuer';
rejects sub { $_[0]{endpoints}[0]{base_url} = 'ftp://x.example/v1' }, qr/base_url: .*http/, 'non-http base_url';
rejects sub { $_[0]{endpoints}[0]{base_url} = 'https://user:pw@x.example/v1' },
  qr/base_url: .*userinfo/, 'credentials in base_url';
rejects sub { $_[0]{endpoints}[0]{base_url} = 'https://x.example/v1?key=sk' },
  qr/base_url: .*query/, 'query string in base_url';
rejects sub { $_[0]{issuer} = 'https://x.example/#frag' }, qr/issuer: .*fragment/, 'fragment in issuer';
rejects sub { $_[0]{endpoints} = [] }, qr/at least one endpoint/, 'no endpoints';
rejects sub { $_[0]{endpoints}[0]{id} = '../x' }, qr/endpoints\[0\].*id/, 'bad endpoint id';
rejects sub { $_[0]{endpoints}[0]{dialect} = 'Open AI' }, qr/dialect/, 'bad dialect token';
rejects sub { delete $_[0]{endpoints}[0]{base_url} }, qr/base_url.*required/, 'missing base_url';
rejects sub { $_[0]{auth}[0]{type} = '' }, qr/type/, 'empty auth type';
rejects sub { $_[0]{models}[0]{id} = "a\nb" }, qr/models\[0\].*id/, 'control char in model id';
rejects sub { $_[0]{models}[0]{capabilities}{streaming} = 'yes' },
  qr/capabilities.*streaming.*boolean/, 'string capability value';
rejects sub { $_[0]{models}[0]{capabilities}{'Tool Calling'} = JSON::MaybeXS::true() },
  qr/capability name/, 'bad capability name';

ok !eval { Langertha::Manifest->from_json( json_of( base_doc() ) =~ s/"streaming":true/"streaming":"1"/r ); 1 },
  'rejected: capability value as the JSON string "1"';
like $@, qr/capabilities: 'streaming' must be a boolean/, '  message: JSON string boolean';

# --- untrusted text: never raw into a client's terminal ----------------------

rejects sub { $_[0]{issuer} = "https://p.example/\e[31m" }, qr/issuer: must be printable ASCII/,
  'ESC in issuer';
rejects sub { $_[0]{endpoints}[0]{base_url} = "https://p.example/v1 x" },
  qr/base_url: must be printable ASCII/, 'space in base_url';
rejects sub { $_[0]{models}[0]{id} = "gpt\x{202E}evil" }, qr/models\[0\]: id must be/,
  'bidi override (U+202E, a format char) in model id';
rejects sub { $_[0]{models}[0]{id} = "a\x{2028}b" }, qr/models\[0\]: id must be/, 'line separator in model id';
{
  my $doc = base_doc();
  $doc->{"\e[2Jboom"} = 1;
  ok !eval { Langertha::Manifest->from_hash($doc); 1 }, 'rejected: control chars in a field name';
  unlike $@, qr/\e/, '  the raw ESC is not echoed';
  like $@, qr/unknown field '\\x\{1b\}\[2Jboom'/, '  it is shown escaped';
}

# --- types: errors stay prefixed, no Moose internals ---------------------------

rejects sub { $_[0]{provider_id} = [1] }, qr/\ALangertha::Manifest: provider_id must be a string at /,
  'provider_id as an array';
rejects sub { $_[0]{endpoints}[0]{id} = { a => 1 } }, qr/\ALangertha::Manifest: endpoints\[0\]: id must be a string at /,
  'endpoint id as an object';
rejects sub { $_[0]{provider_id} = 'UPPER' }, qr/\ALangertha::Manifest: provider_id must match .* at \S+ line \d+\.?\n\z/,
  'BUILD errors carry no constructor tail';

# --- extensions must be plain JSON data ----------------------------------------

rejects sub { $_[0]{extensions} = { obj => bless {}, 'Some::Class' } },
  qr/extensions must hold plain JSON data/, 'blessed object in extensions';
rejects sub { $_[0]{extensions} = { code => sub { 1 } } },
  qr/extensions must hold plain JSON data/, 'code ref in extensions';

# --- uniqueness and references ---------------------------------------------

rejects sub { push @{ $_[0]{endpoints} }, { %{ $_[0]{endpoints}[0] } } },
  qr/duplicate endpoint id 'chat'/, 'duplicate endpoint id';
rejects sub { push @{ $_[0]{auth} }, { id => 'api', type => 'api_key' } },
  qr/duplicate auth id 'api'/, 'duplicate auth id';
rejects sub { push @{ $_[0]{models} }, { id => 'm1', endpoint_ref => 'chat' } },
  qr/duplicate model 'm1' on endpoint 'chat'/, 'duplicate (model, endpoint) pair';
rejects sub { $_[0]{endpoints}[0]{auth_ref} = 'nope' },
  qr/auth_ref 'nope' names no auth entry/, 'dangling auth_ref';
rejects sub { $_[0]{models}[0]{endpoint_ref} = 'nope' },
  qr/endpoint_ref 'nope' names no endpoint/, 'dangling endpoint_ref';

done_testing;
