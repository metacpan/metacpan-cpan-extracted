use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::JSON qw( encode_json );
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# GET /openapi.json and GET /skeid/openapi.json (skeid k105, ADR 0025). The client document
# describes the client routes this configuration enables -- a face that is switched off is not
# in it -- sits behind client_auth like /v1/models does, documents client_auth as its bearer
# scheme and takes the model names of its examples from the list /v1/models answers. The admin
# routes are another document behind the admin key. No secret of the config is ever in either.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER )};

my $ALICE_KEY = 'sk-alice-secret-79';
my $ALICE_ID  = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $ADMIN_KEY = 'admin-secret-79-zzz';
my $UP_KEY    = 'upstream-secret-79-qqq';
my $REG_KEY   = 'registry-secret-79-0123456789abcdef';
$ENV{SKEID_T79_UP}  = $UP_KEY;
$ENV{SKEID_T79_REG} = $REG_KEY;

my $HAS_MANIFEST = eval { require Langertha::Manifest; require Langertha::Manifest::Builder; 1 };

sub config {
  my (%extra) = @_;
  return {
    nodes => [
      { id => 'gpu01', url => 'http://10.0.0.5:8000/v1', model => 'qwen3-32b', api_key_env => 'SKEID_T79_UP' },
      { id => 'gpu02', url => 'http://10.0.0.6:8000/v1', model => 'llama-3.3-70b' },
    ],
    aliases => { 'house-model' => { tiers => [ { model => 'qwen3-32b' } ] } },
    %extra,
  };
}

sub app_for {
  my ($cfg, %opts) = @_;
  my $skeid = Langertha::Skeid->new(config_loader => sub { $cfg }, config_reload_interval => 0,
    (defined $opts{admin_api_key} ? (admin_api_key => $opts{admin_api_key}) : ()));
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid, %opts));
  return ($t, $skeid);
}

# What the first-party OpenAPI 3.1 shape needs, without a validator dependency: version,
# info, every operation answering something, every $ref resolving, every path parameter
# declared, operationIds unique.
sub structural_problems {
  my ($doc) = @_;
  my @p;
  push @p, 'openapi is not 3.1.x' unless ($doc->{openapi} // '') =~ /\A3\.1\.\d+\z/;
  push @p, 'no info.title'   unless length($doc->{info}{title} // '');
  push @p, 'no info.version' unless length($doc->{info}{version} // '');
  push @p, 'no paths' unless ref($doc->{paths}) eq 'HASH';
  my %op_ids;
  for my $path (sort keys %{$doc->{paths} || {}}) {
    push @p, "$path does not start with /" unless $path =~ m{\A/};
    my @declared = $path =~ /\{([^}]+)\}/g;
    for my $method (sort keys %{$doc->{paths}{$path}}) {
      my $op = $doc->{paths}{$path}{$method};
      push @p, "$method $path: not an HTTP method" unless $method =~ /\A(?:get|put|post|delete|patch|head|options)\z/;
      push @p, "$method $path: no responses" unless ref($op->{responses}) eq 'HASH' && %{$op->{responses}};
      push @p, "$method $path: no operationId" unless length($op->{operationId} // '');
      push @p, "$method $path: duplicate operationId $op->{operationId}" if $op_ids{$op->{operationId} // ''}++;
      my %params = map { $_->{name} => 1 } grep { $_->{in} eq 'path' } @{$op->{parameters} || []};
      for my $name (@declared) {
        push @p, "$method $path: path parameter $name not declared" unless $params{$name};
      }
    }
  }
  my $text = encode_json($doc);
  for my $ref ($text =~ /"\$ref":"#\/components\/schemas\/([^"]+)"/g) {
    push @p, "unresolved \$ref $ref" unless $doc->{components}{schemas}{$ref};
  }
  return @p;
}

sub all_ops {
  my ($doc) = @_;
  return { map { my $p = $_; map { (uc($_) . " $p" => $doc->{paths}{$p}{$_}) } keys %{$doc->{paths}{$p}} }
    keys %{$doc->{paths}} };
}

# --- the client document of a plain config ---
{
  my ($t) = app_for(config());
  $t->get_ok('/openapi.json')->status_is(200)->content_type_like(qr{application/json});
  my $doc = $t->tx->res->json;
  is_deeply [ structural_problems($doc) ], [], 'a valid OpenAPI 3.1 document in shape';
  is $doc->{openapi}, '3.1.0', 'OpenAPI 3.1';

  my $ops = all_ops($doc);
  for my $want ('GET /v1/models', 'POST /v1/chat/completions', 'POST /v1/embeddings',
    'POST /v1/audio/transcriptions', 'POST /v1/audio/translations', 'POST /v1/rerank',
    'POST /rerank', 'POST /v1/messages', 'POST /api/chat', 'POST /api/generate', 'GET /api/tags',
    'GET /api/ps', 'GET /health', 'GET /openapi.json', 'GET /v1/realtime') {
    ok $ops->{$want}, "$want is documented";
  }

  # The realtime route (skeid k95) is an upgrade, not a request with a body: its input is the
  # query, its success is 101, and it sits behind the same client gate as every client route.
  my $rt = $ops->{'GET /v1/realtime'};
  my ($model) = grep { $_->{name} eq 'model' } @{ $rt->{parameters} || [] };
  ok $model && $model->{in} eq 'query' && $model->{required}, 'realtime: the model is a required query parameter';
  ok $rt->{responses}{101}, 'realtime: the success is 101 Switching Protocols';
  ok !$rt->{responses}{200}, 'realtime: there is no 200';
  ok !$rt->{requestBody}, 'realtime: no request body';
  is_deeply $rt->{security}, [ {}, { client_auth => [] } ], 'realtime: the client key like the other routes';
  ok !grep({ m{^\w+ /skeid} } keys %$ops), 'no admin route is in the client document';
  ok !grep({ m{/\.well-known|/mcp} } keys %$ops),
    'the manifest and the MCP routes are not there while their sections are off';
  ok !grep({ m{/docs} } keys %$ops), 'the UI is not an API operation';

  is_deeply $doc->{components}{securitySchemes}{client_auth},
    { type => 'http', scheme => 'bearer', description => $doc->{components}{securitySchemes}{client_auth}{description} },
    'client_auth is a bearer scheme';
  is_deeply $ops->{'POST /v1/chat/completions'}{security}, [ {}, { client_auth => [] } ],
    'without a client_auth section a key is optional';
  is_deeply $ops->{'GET /health'}{security}, [], '/health needs none';

  # Model names come from the list /v1/models answers.
  $t->get_ok('/v1/models')->status_is(200);
  my @models = map { $_->{id} } @{$t->tx->res->json->{data}};
  my $example = $ops->{'POST /v1/chat/completions'}{requestBody}{content}{'application/json'}{example};
  is $example->{model}, $models[0], 'the example model is the first /v1/models lists';
  is $ops->{'POST /v1/messages'}{requestBody}{content}{'application/json'}{example}{model}, $models[0],
    'on every face';
  ok scalar(@models) >= 3, 'models and an alias are listed';
}

# --- faces that are switched on appear, and only then ---
{
  my $mcp = { mcp => { servers => { notes => { url => 'http://mcp.internal:8080/mcp', keys => [ $ALICE_ID ] } } } };
  my ($t) = app_for(config(%$mcp));
  $t->get_ok('/openapi.json' => { Authorization => "Bearer $ALICE_KEY" })->status_is(200);
  my $doc = $t->tx->res->json;
  is_deeply [ structural_problems($doc) ], [], 'still valid with the MCP routes in';
  my $ops = all_ops($doc);
  ok $ops->{'GET /v1/mcp/servers'}, 'the MCP listing appears with an mcp section';
  ok $ops->{'POST /mcp/{mcp_server}'} && $ops->{'GET /mcp/{mcp_server}/{mcp_path}'},
    'and the relay under its two path templates, one operation per method';
  ok !$ops->{'GET /.well-known/langertha.json'}, 'the manifest, still off, does not';
}
SKIP: {
  skip 'Langertha::Manifest is not installed', 3 unless $HAS_MANIFEST;
  my ($t, $skeid) = app_for(config(manifest => { enabled => 1, public_url => 'https://llm.example.com/',
    provider_id => 'example-llm' }));
  ok $skeid->manifest_enabled, 'manifest on';
  $t->get_ok('/openapi.json');
  ok all_ops($t->tx->res->json)->{'GET /.well-known/langertha.json'}, 'the manifest route is documented';
  my ($off) = app_for(config());
  $off->get_ok('/openapi.json');
  ok !all_ops($off->tx->res->json)->{'GET /.well-known/langertha.json'}, 'and not without';
}

# --- client_auth: the document is behind the gate, and says so ---
{
  my ($t) = app_for(config(client_auth => { keys => [ $ALICE_ID ] }));
  $t->get_ok('/openapi.json')->status_is(401, 'no key, no model names')
    ->header_like('WWW-Authenticate' => qr/Bearer/);
  $t->get_ok('/openapi.json' => { Authorization => 'Bearer sk-someone-else' })->status_is(401);
  $t->get_ok('/openapi.json' => { Authorization => "Bearer $ALICE_KEY" })->status_is(200)
    ->header_like('Cache-Control' => qr/private/);
  my $ops = all_ops($t->tx->res->json);
  is_deeply $ops->{'GET /v1/models'}{security}, [ { client_auth => [] } ], 'the key is required, as documented';
}

# --- the example names what this key may use ---
{
  my $cfg = config(
    policies       => { narrow => { models => ['llama-3.3-70b'] }, wide => {} },
    default_policy => 'wide',
    keys           => { $ALICE_ID => 'narrow' },
  );
  my ($t) = app_for($cfg);
  $t->get_ok('/openapi.json' => { Authorization => "Bearer $ALICE_KEY" })->status_is(200);
  is all_ops($t->tx->res->json)->{'POST /v1/chat/completions'}{requestBody}{content}{'application/json'}{example}{model},
    'llama-3.3-70b', 'a key restricted by policy gets the one model it may use in the example';
}

# --- admin document ---
{
  my ($t) = app_for(config(), admin_api_key => $ADMIN_KEY);
  $t->get_ok('/skeid/openapi.json')->status_is(401);
  $t->get_ok('/skeid/openapi.json' => { Authorization => 'Bearer nope' })->status_is(401);
  $t->get_ok('/skeid/openapi.json' => { Authorization => "Bearer $ALICE_KEY" })->status_is(401,
    'a customer key does not open it');
  $t->get_ok('/skeid/openapi.json' => { Authorization => "Bearer $ADMIN_KEY" })->status_is(200);
  my $doc = $t->tx->res->json;
  is_deeply [ structural_problems($doc) ], [], 'the admin document is valid in shape';
  my $ops = all_ops($doc);
  ok $ops->{'GET /skeid/nodes'} && $ops->{'POST /skeid/nodes'} && $ops->{'POST /skeid/nodes/{id}/health'}
    && $ops->{'GET /skeid/usage'} && $ops->{'GET /skeid/config'} && $ops->{'GET /skeid/metrics/nodes'},
    'the admin routes are in it';
  ok !grep({ m{/v1/|/api/} } keys %$ops), 'no client route is';
  ok !$ops->{'GET /skeid/registry/snapshot'}, 'the registry snapshot is not there while the registry is off';
  ok $doc->{components}{securitySchemes}{admin_key}, 'the scheme is admin_key';
  ok !$doc->{components}{securitySchemes}{client_auth}, 'client_auth is not part of it';

  my ($none) = app_for(config());
  $none->get_ok('/skeid/openapi.json')->status_is(404, 'without an admin key it is absent, like /skeid/*');
}
{
  my ($t) = app_for(config(registry => { enabled => 1, secret_env => 'SKEID_T79_REG' }),
    admin_api_key => $ADMIN_KEY);
  $t->get_ok('/skeid/openapi.json' => { Authorization => "Bearer $ADMIN_KEY" })->status_is(200);
  ok all_ops($t->tx->res->json)->{'GET /skeid/registry/snapshot'}, 'the registry snapshot is, once enabled';
}

# --- no secret reaches a document (ADR 0003) ---
{
  my ($t) = app_for(config(
    client_auth => { keys => [ $ALICE_ID ] },
    registry    => { enabled => 1, secret_env => 'SKEID_T79_REG' },
    mcp         => { servers => { notes => { url => 'http://mcp.internal:8080/mcp', keys => [ $ALICE_ID ],
      headers => { 'X-Tenant' => 'example' } } } },
  ), admin_api_key => $ADMIN_KEY);
  $t->get_ok('/openapi.json' => { Authorization => "Bearer $ALICE_KEY" })->status_is(200);
  my $client = $t->tx->res->body;
  $t->get_ok('/skeid/openapi.json' => { Authorization => "Bearer $ADMIN_KEY" })->status_is(200);
  my $admin = $t->tx->res->body;
  for my $secret ($ALICE_KEY, $ADMIN_KEY, $UP_KEY, $REG_KEY, 'SKEID_T79_UP', 'SKEID_T79_REG',
    '10.0.0.5', 'mcp.internal') {
    ok index($client . $admin, $secret) < 0, "'$secret' is in no document";
  }
}

done_testing;
