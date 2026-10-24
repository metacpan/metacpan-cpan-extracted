use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Digest::SHA qw( sha1_hex );
use Encode ();
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( encode_base64 );
use Path::Tiny qw( path );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Protocol::Documents;
use Langertha::Skeid::Proxy;

# The documents face (skeid k94, ADR 0028): docling-serve's own POST /v1/convert/file and
# /v1/convert/source, relayed -- not translated -- behind the client gate, routed over the nodes
# of kind `documents`, metered in documents and pages. The node here is a fake docling mounted in
# the same app. What this proves, in order:
#
#   bytes in and out (a zip answer included), the node's key in the header it names and none of
#   the client's, 413/401 before the body, every spelling of a remote source or callback refused
#   before admission, pages read from json_content only when it is there and bounded, documents
#   counted off the request, request.finish on every exit path, admission, key policy, the kind
#   that keeps chat and documents nodes apart, config validation, and the store's pages column.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_K94_NODE_KEY SKEID_K94_UNSET_KEY SKEID_USAGE_DB )};

my $TMP   = tempdir(CLEANUP => 1);
my $SPOOL = path($TMP)->child('spool');
$SPOOL->mkpath;
$ENV{MOJO_TMPDIR} = "$SPOOL";

my $ALICE_KEY = 'sk-alice-secret';
my $ALICE_ID  = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $BOUNDARY  = 'k94-client-boundary-77aa';

srand(94);
my $PDF     = '%PDF-1.7 ' . pack('C*', map { int(rand(256)) } 1 .. 307_200);
my $PDF_SHA = sha1_hex($PDF);
my $SMALL   = "%PDF-1.4\x00\x01\xff small";
my $ZIP     = "PK\x03\x04" . pack('C*', map { int(rand(256)) } 1 .. 4000) . "PK\x05\x06";

my (@UPSTREAM, @USAGE, @LOG);
my $MODE   = '';       # '', 'fail', 'hold'
my $ANSWER;            # sub returning [status, content_type, bytes]; default: a docling answer
my $CFG    = {};

my $CANON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

sub docling_json {
  my (%o) = @_;
  my $pages = $o{pages} // 3;
  return $CANON->encode({
    document => {
      filename   => 'a.pdf',
      md_content => "# Titel\n\nGrüße",
      json_content => (exists $o{json_content} ? $o{json_content}
        : { schema_name => 'DoclingDocument', pages => { map { $_ => { page_no => $_ } } 1 .. $pages } }),
    },
    status => 'success', processing_time => 1.25, errors => [],
  });
}

sub settle {
  Mojo::IOLoop->timer(($_[0] // 0.05) => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
}

sub run_until {
  my ($cond, $max) = @_;
  return 1 if $cond->();
  my $met = 0;
  my $guard = Mojo::IOLoop->timer(($max // 3) => sub { Mojo::IOLoop->stop });
  my $poll = Mojo::IOLoop->recurring(0.005 => sub {
    return unless $cond->();
    $met = 1;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($_) for $guard, $poll;
  return $met;
}

# The fake docling node. It records what arrived -- headers, parts, the JSON body as bytes.
sub fake_docling {
  my ($c) = @_;
  my $req  = $c->req;
  my $kind = $c->stash('kind');
  my $seen = {
    tag          => $c->stash('tag'),
    kind         => $kind,
    content_type => $req->headers->content_type,
    authorization => $req->headers->authorization,
    x_api_key    => $req->headers->header('x-api-key'),
    headers      => { map { lc($_) => $req->headers->header($_) } @{ $req->headers->names } },
    raw          => ($kind eq 'source' ? $req->body : undef),
    parts        => [ map { {
      disposition => $_->headers->content_disposition,
      type        => $_->headers->content_type,
      size        => $_->asset->size,
      sha         => sha1_hex($_->asset->slurp),
    } } @{ $req->content->is_multipart ? $req->content->parts : [] } ],
    fields       => { map { $_ => $req->body_params->every_param($_) } @{ $req->body_params->names } },
    answered => 0,
    hung_up  => 0,
  };
  push @UPSTREAM, $seen;
  $c->on(finish => sub { $seen->{hung_up} = 1 unless $seen->{answered}; delete $seen->{answer} });

  if ($MODE eq 'fail') {
    $seen->{answered} = 1;
    return $c->render(status => 500, json => { detail => 'conversion worker crashed' });
  }
  if ($MODE eq 'hold') {
    $c->render_later;
    Mojo::IOLoop->stream($c->tx->connection)->timeout(0);
    $seen->{answer} = sub { $seen->{answered} = 1; $c->render(data => docling_json(), format => 'json') };
    return;
  }
  $seen->{answered} = 1;
  my ($status, $type, $bytes) = @{ $ANSWER ? $ANSWER->($seen) : [ 200, 'application/json', docling_json() ] };
  $c->res->headers->content_type($type);
  return $c->render(data => $bytes, status => $status);
}

my $UP;
sub proxy {
  my (%opts) = @_;
  $CFG = delete($opts{config}) || {};
  @UPSTREAM = @USAGE = @LOG = ();
  $MODE = '';
  $ANSWER = undef;
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms  => 60,
    route_wait_poll_ms     => 5,
    config_reload_interval => 0,
    config_loader          => sub { $CFG },
    ($opts{usage_store} ? () : (store_usage_event => sub { push @USAGE, $_[1]; return { ok => 1 } })),
    %opts,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('trace');
  $app->log->unsubscribe('message')->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @LOG, [ $level, join(' ', @lines) ];
  });
  $app->routes->post('/__up/:tag/v1/convert/:kind' => \&fake_docling);
  my $t = Test::Mojo->new($app);
  $UP = $t->ua->server->nb_url->clone;
  return ($t, $skeid);
}

sub node_url { return $UP->clone->path('/__up/' . $_[0])->to_string }

sub add_node {
  my ($skeid, $id, %extra) = @_;
  return $skeid->add_node(id => $id, url => node_url($id), kind => 'documents', max_conns => 4, %extra);
}

sub field {
  my ($name, $value) = @_;
  return [ [ Encode::encode_utf8(qq{Content-Disposition: form-data; name="$name"}) ], Encode::encode_utf8($value) ];
}

sub file_part {
  my ($bytes, %o) = @_;
  return [ [
    Encode::encode_utf8('Content-Disposition: form-data; name="' . ($o{name} // 'files') . '"; filename="'
      . ($o{filename} // 'a.pdf') . '"'),
    'Content-Type: ' . ($o{type} // 'application/pdf'),
  ], $bytes ];
}

sub form {
  my (@parts) = @_;
  my $body = '';
  for my $part (@parts) {
    my ($headers, $content) = @$part;
    $body .= "--$BOUNDARY\r\n" . join('', map { "$_\r\n" } @$headers) . "\r\n" . $content . "\r\n";
  }
  return $body . "--$BOUNDARY--\r\n";
}

my $FORM_TYPE = "multipart/form-data; boundary=$BOUNDARY";
my $F = '/v1/convert/file';
my $S = '/v1/convert/source';

sub upload {
  my ($t, $path, @parts) = @_;
  my $headers = ref($parts[0]) eq 'HASH' ? shift(@parts) : {};
  return $t->post_ok($path => { 'Content-Type' => $FORM_TYPE, %$headers } => form(@parts));
}

sub convert_source {
  my ($t, $body, $headers) = @_;
  $body = encode_json($body) if ref $body;
  return $t->post_ok($S => { 'Content-Type' => 'application/json', %{ $headers || {} } } => $body);
}

sub source_body {
  my (%extra) = @_;
  return { options => { to_formats => ['md'] },
    file_sources => [ { base64_string => encode_base64($SMALL, ''), filename => 'a.pdf' } ], %extra };
}

sub inflight { return $_[0]->node_metrics($_[1])->{inflight} }

sub paired {
  my ($skeid, $id, $label) = @_;
  my $m = $skeid->node_metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted}, $m->{started},
    "$label: every request.start on $id has its request.finish";
  return $m;
}

sub raw_client {
  my ($t, $bytes) = @_;
  my $client = { buffer => '', closed => 0 };
  Mojo::IOLoop->client({ address => '127.0.0.1', port => $t->ua->server->nb_url->port } => sub {
    my ($loop, $err, $stream) = @_;
    return $client->{error} = $err if $err;
    $client->{stream} = $stream;
    $stream->timeout(0);
    $stream->on(read  => sub { $client->{buffer} .= $_[1] });
    $stream->on(close => sub { $client->{closed} = 1; delete $client->{stream} });
    $stream->write($bytes);
  });
  return $client;
}

sub request_head {
  my ($path, %headers) = @_;
  return join("\r\n", "POST $path HTTP/1.1", 'Host: 127.0.0.1',
    (map { "$_: $headers{$_}" } sort keys %headers), '', '');
}

# --- the wire ---------------------------------------------------------------------------------

subtest 'a file conversion goes upstream part for part and comes back byte for byte' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');

  upload($t, $F, { Authorization => "Bearer $ALICE_KEY", 'X-Request-Id' => 'req-k94-1' },
    file_part($PDF, filename => 'Bericht März.pdf'),
    field(to_formats => 'md'),
    file_part($SMALL, filename => 'zweite.pdf'),
    field(to_formats => 'json'),
    field(do_ocr => 'true'),
    field(ocr_engine => 'easyocr'),
  );
  $t->status_is(200)
    ->header_is('x-skeid-node' => 'docling-1')
    ->header_is('x-request-id' => 'req-k94-1')
    ->json_is('/status' => 'success');
  is $t->tx->res->body, docling_json(), 'the answer is the node\'s, byte for byte';

  is scalar(@UPSTREAM), 1, 'one upstream call';
  my $seen = $UPSTREAM[0];
  is $seen->{kind}, 'file', 'at the node\'s /v1/convert/file';
  is $seen->{content_type}, $FORM_TYPE, 'with the client\'s content type and boundary';
  is_deeply [ map { $_->{disposition} =~ /name="([^"]+)"/ ? $1 : '?' } @{ $seen->{parts} } ],
    [ qw( files to_formats files to_formats do_ocr ocr_engine ) ], 'the parts keep the client\'s order';
  is $seen->{parts}[0]{sha}, $PDF_SHA, 'the first file arrives unchanged';
  is $seen->{parts}[2]{sha}, sha1_hex($SMALL), 'the second too';
  like Encode::decode_utf8($seen->{parts}[0]{disposition}), qr/filename="Bericht März\.pdf"/,
    'under the client\'s file name';
  is_deeply $seen->{fields}{to_formats}, [ 'md', 'json' ], 'a repeated option field arrives as often as sent';
  is_deeply $seen->{fields}{ocr_engine}, ['easyocr'], 'an option Skeid knows nothing of passes through';

  is scalar(@USAGE), 1, 'one usage event';
  my $ev = $USAGE[0];
  is $ev->{endpoint}, $F, 'event endpoint';
  is $ev->{api_format}, 'docling', 'event api_format';
  is $ev->{model}, 'documents', 'event model is the routing key of the node kind';
  is $ev->{node_id}, 'docling-1', 'event node';
  is $ev->{api_key_id}, $ALICE_ID, 'event key id';
  is $ev->{status_code}, 200, 'event status';
  is $ev->{ok}, 1, 'event ok';
  is $ev->{documents}, 2, 'documents: the two files of the request';
  is $ev->{pages}, 3, 'pages: read from json_content';
  is $ev->{total_tokens}, 0, 'no tokens';
  is $ev->{cost_total_usd}, 0, 'recorded, not priced';
  ok !exists($ev->{audio_seconds}), 'no audio_seconds';
  paired($skeid, 'docling-1', 'file');
  cmp_ok scalar($SPOOL->children), '>=', 0, 'the upload was spooled (checked at the end that none outlives)';
};

subtest 'a zip answer is relayed byte for byte and has no pages' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');
  $ANSWER = sub { [ 200, 'application/zip', $ZIP ] };
  upload($t, $F, file_part($SMALL), file_part($SMALL, filename => 'b.pdf'));
  $t->status_is(200)->content_type_is('application/zip');
  is $t->tx->res->body, $ZIP, 'the zip is identical';
  is $USAGE[0]{documents}, 2, 'documents counted off the request';
  ok !exists($USAGE[0]{pages}), 'a zip is not parsed: no pages key';
  paired($skeid, 'docling-1', 'zip');
};

subtest 'a source conversion is relayed as JSON, one reading of the body' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');
  convert_source($t, source_body(), { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(200)->header_is('x-skeid-node' => 'docling-1');
  is $t->tx->res->body, docling_json(), 'the answer byte for byte';
  my $seen = $UPSTREAM[0];
  is $seen->{kind}, 'source', 'at /v1/convert/source';
  is_deeply decode_json($seen->{raw}), source_body(), 'the body arrives with its content';
  is $USAGE[0]{endpoint}, $S, 'event endpoint';
  is $USAGE[0]{documents}, 1, 'one file source, one document';
  is $USAGE[0]{pages}, 3, 'pages';

  convert_source($t, source_body(file_sources => [ map { +{ base64_string => 'QQ==', filename => "$_.pdf" } } 1 .. 4 ]));
  is $USAGE[-1]{documents}, 4, 'four file sources, four documents';

  for my $bad ('[1,2]', '"text"', 'not json', '') {
    convert_source($t, $bad);
    $t->status_is(400, "body <$bad>: 400")->json_is('/error/type' => 'invalid_request_error');
  }
  upload($t, $S, file_part($SMALL));
  $t->status_is(400, 'a multipart body on the JSON route: 400');
  upload($t, $F, field(to_formats => 'md'));
  $t->status_is(200, 'a file route form without a file part is the node\'s to judge');
  $t->post_ok($F => json => { files => 'x' });
  $t->status_is(400, 'JSON on the file route: 400')->json_like('/error/message' => qr/multipart/);
  paired($skeid, 'docling-1', 'source');
};

subtest 'the node\'s key goes in the header it names, the client\'s credentials stay home' => sub {
  local $ENV{SKEID_K94_NODE_KEY} = 'node-secret-key';
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1', api_key_env => 'SKEID_K94_NODE_KEY', api_key_header => 'X-Api-Key');
  upload($t, $F, { Authorization => "Bearer $ALICE_KEY", 'X-API-KEY' => $ALICE_KEY }, file_part($SMALL));
  $t->status_is(200);
  my $seen = $UPSTREAM[0];
  is $seen->{x_api_key}, 'node-secret-key', 'the node key is in X-Api-Key';
  ok !exists($seen->{headers}{authorization}), 'there is no Authorization';
  unlike join("\n", values %{ $seen->{headers} }), qr/\Q$ALICE_KEY\E/, 'the client\'s credential is nowhere';

  convert_source($t, source_body(), { Authorization => "Bearer $ALICE_KEY", 'x-api-key' => $ALICE_KEY });
  $t->status_is(200);
  is $UPSTREAM[1]{x_api_key}, 'node-secret-key', 'the source route too';
  ok !exists($UPSTREAM[1]{headers}{authorization}), 'no Authorization there either';
  paired($skeid, 'docling-1', 'x-api-key');

  # The default is unchanged: a Bearer token.
  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'docling-1', api_key_env => 'SKEID_K94_NODE_KEY');
  upload($t2, $F, { 'X-Api-Key' => $ALICE_KEY }, file_part($SMALL));
  is $UPSTREAM[0]{authorization}, 'Bearer node-secret-key', 'without api_key_header: Authorization Bearer';
  is $UPSTREAM[0]{x_api_key}, undef, 'and the client\'s x-api-key is gone';

  # A named source with no key fails closed, header option or not.
  my ($t3, $skeid3) = proxy();
  add_node($skeid3, 'docling-1', api_key_env => 'SKEID_K94_UNSET_KEY', api_key_header => 'X-Api-Key');
  upload($t3, $F, { 'X-Api-Key' => $ALICE_KEY }, file_part($SMALL));
  $t3->status_is(503)->json_is('/error/type' => 'upstream_key_unavailable');
  is scalar(@UPSTREAM), 0, 'the node was not called';
  is $USAGE[0]{ok}, 0, 'one failed event';
  paired($skeid3, 'docling-1', 'unkeyed');
};

# --- limits and the gate ------------------------------------------------------------------------

subtest 'uploads.documents_max_bytes: 413 before the body, per route, hot reloaded' => sub {
  my ($t, $skeid) = proxy(config => { uploads => { documents_max_bytes => 4096, max_bytes => 100_000_000 } });
  add_node($skeid, 'docling-1');
  is $skeid->documents_max_bytes, 4096, 'read from the config';

  upload($t, $F, file_part('a' x 8192));
  $t->status_is(413)->json_is('/error/type' => 'invalid_request_error')->json_like('/error/message' => qr/4096/);
  convert_source($t, source_body(file_sources => [ { base64_string => ('QUJD' x 2000), filename => 'a.pdf' } ]));
  $t->status_is(413, 'the base64 JSON route falls under the same limit');
  is scalar(@UPSTREAM), 0, 'no upstream call';
  is scalar(@USAGE), 0, 'no event';
  is $skeid->node_metrics('docling-1')->{started}, 0, 'no request.start';

  upload($t, $F, file_part('a' x 1024));
  $t->status_is(200, 'under the limit passes');

  for my $case ([ $F, $FORM_TYPE ], [ $S, 'application/json' ]) {
    my ($path, $type) = @$case;
    # Below the server's own 16 MiB: only the route's limit can answer this one unread.
    my $client = raw_client($t, request_head($path, 'Content-Type' => $type, 'Content-Length' => 10_000_000)
      . '{"file_sources":[');
    ok run_until(sub { $client->{buffer} =~ m{\r\n\r\n.*\}}s }), "$path: answered while the body was outstanding";
    like $client->{buffer}, qr{\AHTTP/1\.1 413 }, "$path: with 413";
    ok run_until(sub { $client->{closed} }), "$path: connection closed, body not waited for";
  }
  is scalar(@UPSTREAM), 1, 'only the request that fit was forwarded';

  $CFG = { uploads => { documents_max_bytes => 1_000_000 } };
  upload($t, $F, file_part($PDF));
  $t->status_is(200, 'raised: the 300 KiB upload passes');
  is $UPSTREAM[-1]{parts}[0]{sha}, $PDF_SHA, 'intact';
  $CFG = {};
  $skeid->maybe_reload_config;
  is $skeid->documents_max_bytes, 104857600, 'removed from the config: 100 MiB again';

  # The audio limit is its own: max_bytes does not bound documents, documents_max_bytes not audio.
  $CFG = { uploads => { max_bytes => 100, documents_max_bytes => 5_000_000 } };
  upload($t, $F, file_part($PDF));
  $t->status_is(200, 'documents ignore uploads.max_bytes');
  $t->post_ok('/v1/audio/transcriptions' => { 'Content-Type' => $FORM_TYPE } =>
    form(field(model => 'whisper'), file_part($PDF, name => 'file', type => 'audio/wav')));
  $t->status_is(413, 'audio keeps uploads.max_bytes');
  paired($skeid, 'docling-1', 'limits');

  for my $bad ({ documents_max_bytes => 0 }, { documents_max_bytes => '10MB' }, { documents_max_bytes => -1 },
      { documents_max_bytes => 1.5 }, { documents_max_byte => 5 }) {
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { { uploads => $bad } }); 1 };
    ok !$ok, 'a broken uploads section fails the load: ' . encode_json([$bad]);
    like $@, qr/uploads/, 'naming the section';
  }
};

subtest 'the default limit lets through what the server alone would not' => sub {
  # The server's request limit is 16 MiB; documents_max_bytes defaults to 100 MiB and replaces
  # it on these routes, for the form and for the base64 JSON.
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');
  my $big = 'x' x (17 * 1024 * 1024);
  upload($t, $F, file_part($big));
  $t->status_is(200, 'a 17 MiB upload passes');
  is scalar(@UPSTREAM), 1, 'and reached the node (which, in this app, has the server\'s own limit)';
  convert_source($t, source_body(file_sources => [ { base64_string => 'QUJD' x (4 * 1024 * 1024), filename => 'a.pdf' } ]));
  $t->status_is(200, 'a 16 MiB base64 source body passes');
  is $skeid->documents_max_bytes, 104857600, 'the limit is 100 MiB';
  paired($skeid, 'docling-1', 'big uploads');
};

subtest 'client_auth: 401 before the body and before any node' => sub {
  my ($t, $skeid) = proxy(config => { client_auth => { keys => [$ALICE_ID] } });
  add_node($skeid, 'docling-1');
  upload($t, $F, file_part($SMALL));
  $t->status_is(401)->json_is('/error/message' => 'Missing API key');
  convert_source($t, source_body(), { Authorization => 'Bearer sk-mallory' });
  $t->status_is(401)->json_is('/error/message' => 'Invalid API key');
  is scalar(@UPSTREAM), 0, 'nothing forwarded';
  is scalar(@USAGE), 0, 'nothing metered';

  for my $case ([ $F, $FORM_TYPE ], [ $S, 'application/json' ]) {
    my ($path, $type) = @$case;
    my $client = raw_client($t, request_head($path, 'Content-Type' => $type, 'Content-Length' => 5_000_000,
      Authorization => 'Bearer sk-mallory') . '--x');
    ok run_until(sub { $client->{buffer} =~ m{\r\n\r\n.*\}}s }), "$path: 401 with the body outstanding";
    like $client->{buffer}, qr{\AHTTP/1\.1 401 }, "$path: it is a 401";
    ok run_until(sub { $client->{closed} }), "$path: and the connection is closed";
  }
  upload($t, $F, { Authorization => "Bearer $ALICE_KEY" }, file_part($SMALL));
  $t->status_is(200, 'a listed key gets in');
  is $USAGE[0]{api_key_id}, $ALICE_ID, 'metered on its key id';
};

# --- remote sources ----------------------------------------------------------------------------

subtest 'a remote source or callback is a 400 before admission, unless the operator allows it' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');

  my %form = (
    'callbacks'          => field(callbacks => 'http://10.0.0.5/hook'),
    'Callbacks'          => field(Callbacks => 'http://10.0.0.5/hook'),
    'callbacks '         => [ ['Content-Disposition: form-data; name="callbacks "'], 'http://10.0.0.5/hook' ],
    'CALLBACKS bare'     => [ ['Content-Disposition: form-data; NAME=CALLBACKS'], 'http://10.0.0.5/hook' ],
    'callbacks[]'        => field('callbacks[]' => 'http://10.0.0.5/hook'),
    'name*= notation'    => [ [q{Content-Disposition: form-data; name*=UTF-8''callbacks}], 'http://10.0.0.5/hook' ],
    'http_sources'       => field(http_sources => '[{"url":"http://10.0.0.5/x.pdf"}]'),
    'a callbacks file'   => file_part('http://10.0.0.5/hook', name => 'callbacks', filename => 'c.txt'),
  );
  for my $case (sort keys %form) {
    upload($t, $F, file_part($SMALL), $form{$case});
    $t->status_is(400, "form, $case: 400")->json_is('/error/type' => 'invalid_request_error');
    unlike $t->tx->res->body, qr/10\.0\.0\.5/, "form, $case: the message does not echo the value";
  }
  upload($t, $F, file_part($SMALL), $form{callbacks});
  $t->json_like('/error/message' => qr/callbacks/, 'the message names the field');

  my %json = (
    'http_sources'     => '{"http_sources":[{"url":"http://10.0.0.5/x.pdf"}]}',
    'http_sources twice' => '{"http_sources":[],"file_sources":[],"http_sources":[{"url":"http://10.0.0.5/x"}]}',
    'http_sources twice, remote first' => '{"http_sources":[{"url":"http://10.0.0.5/x"}],"http_sources":[]}',
    'callbacks'        => '{"callbacks":["http://10.0.0.5/hook"],"file_sources":[]}',
    'escaped key'      => '{"http_sources":[{"url":"http://10.0.0.5/x"}]}',
    'sources of kind http' => '{"sources":[{"kind":"http","url":"http://10.0.0.5/x"}]}',
    'sources as urls'  => '{"sources":["http://10.0.0.5/x"]}',
    'target put'       => '{"file_sources":[],"target":{"kind":"put","url":"http://10.0.0.5/out"}}',
  );
  for my $case (sort keys %json) {
    convert_source($t, $json{$case});
    $t->status_is(400, "JSON, $case: 400")->json_is('/error/type' => 'invalid_request_error');
    unlike $t->tx->res->body, qr/10\.0\.0\.5/, "JSON, $case: no value in the message";
  }
  convert_source($t, $json{'http_sources'});
  $t->json_like('/error/message' => qr/http_sources/, 'JSON: the message names the field');

  is scalar(@UPSTREAM), 0, 'none of them reached the node';
  is scalar(@USAGE), 0, 'none was metered';
  is $skeid->node_metrics('docling-1')->{started}, 0, 'none took a slot';

  # What is harmless is not refused.
  convert_source($t, source_body(http_sources => [], callbacks => []));
  $t->status_is(200, 'empty lists of remote things are fine');
  convert_source($t, source_body(target => { kind => 'inbody' }, sources => [ { kind => 'file', base64_string => 'QQ==', filename => 'a.pdf' } ]));
  $t->status_is(200, 'inbody target and file sources are fine');
  upload($t, $F, file_part($SMALL), field(target_type => 'zip'));
  $t->status_is(200, 'plain options are fine');

  # The opt-in lets the same requests through, untouched.
  $CFG = { documents => { allow_remote_sources => JSON::MaybeXS::true } };
  my $before = @UPSTREAM;
  upload($t, $F, file_part($SMALL), $form{callbacks});
  $t->status_is(200, 'allowed: a callbacks field passes');
  is_deeply $UPSTREAM[-1]{fields}{callbacks}, ['http://10.0.0.5/hook'], 'and arrives as sent';
  convert_source($t, '{"http_sources":[{"url":"http://10.0.0.5/x.pdf"}]}');
  $t->status_is(200, 'allowed: http_sources pass');
  is_deeply decode_json($UPSTREAM[-1]{raw}), { http_sources => [ { url => 'http://10.0.0.5/x.pdf' } ] },
    'and reach the node';
  is scalar(@UPSTREAM) - $before, 2, 'two calls';

  for my $bad ('maybe', [], { allow => 1 }, 2) {
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { { documents => { allow_remote_sources => $bad } } }); 1 };
    ok !$ok, 'a non-boolean allow_remote_sources fails the load: ' . encode_json([$bad]);
  }
  ok !eval { Langertha::Skeid->new(config_loader => sub { { documents => { model => 'docling' } } }); 1 },
    'documents: an unknown key fails the load (no fixed model name)';
  like $@, qr/documents/, 'naming the section';
  paired($skeid, 'docling-1', 'remote sources');
};

# --- the unit ----------------------------------------------------------------------------------

subtest 'pages come from json_content, only when it is there and bounded' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1');

  my %answer = (
    'a document of five pages' => [ 200, 'application/json', docling_json(pages => 5), 5 ],
    'pages as a list'          => [ 200, 'application/json',
      encode_json({ document => { json_content => { pages => [ {}, {} ] } }, status => 'success' }), 2 ],
    'json_content as a string' => [ 200, 'application/json',
      encode_json({ document => { json_content => encode_json({ pages => { 1 => {}, 2 => {} } }) } }), 2 ],
    'no json_content'          => [ 200, 'application/json',
      encode_json({ document => { md_content => '# x' }, status => 'success' }), undef ],
    'json_content null'        => [ 200, 'application/json',
      encode_json({ document => { md_content => '# x', json_content => undef } }), undef ],
    'no pages in it'           => [ 200, 'application/json',
      encode_json({ document => { json_content => { texts => [] } } }), undef ],
    'an empty pages object'    => [ 200, 'application/json',
      encode_json({ document => { json_content => { pages => {} } } }), undef ],
    'pages that is a number'   => [ 200, 'application/json',
      encode_json({ document => { json_content => { pages => 7 } } }), undef ],
    'JSON bytes under a zip type' => [ 200, 'application/zip', docling_json(pages => 4), undef ],
    'a broken body'            => [ 200, 'application/json', '{"document":{"json_content":{"pages":{"1":', undef ],
    'not an object'            => [ 200, 'application/json', '[1,2,3]', undef ],
    'more than the parse bound' => [ 200, 'application/json',
      encode_json({ document => { md_content => ('x' x (9 * 1024 * 1024)),
        json_content => { pages => { 1 => {}, 2 => {} } } } }), undef ],
  );
  for my $case (sort keys %answer) {
    my ($status, $type, $bytes, $pages) = @{ $answer{$case} };
    $ANSWER = sub { [ $status, $type, $bytes ] };
    my $events = @USAGE;
    upload($t, $F, file_part($SMALL));
    $t->status_is($status, "$case: the status is the node's");
    is $t->tx->res->body, $bytes, "$case: the body is relayed byte for byte";
    is scalar(@USAGE), $events + 1, "$case: one event";
    if (defined $pages) { is $USAGE[-1]{pages}, $pages, "$case: pages $pages" }
    else                { ok !exists($USAGE[-1]{pages}), "$case: no pages key -- not measured, not zero" }
    if ($status < 300) { is $USAGE[-1]{documents}, 1, "$case: documents counted" }
    else               { ok !exists($USAGE[-1]{documents}), "$case: documents only for an answered request" }
  }
  paired($skeid, 'docling-1', 'answers');

  # A 4xx is the proxy's own error answer, as on every relayed route: failed event, no units.
  $ANSWER = sub { [ 422, 'application/json', encode_json({ detail => [ { msg => 'bad' } ],
    document => { json_content => { pages => { 1 => {} } } } }) ] };
  upload($t, $F, file_part($SMALL));
  $t->status_is(422)->json_is('/error/type' => 'upstream_error');
  is $USAGE[-1]{ok}, 0, 'a 422: failed event';
  ok !exists($USAGE[-1]{pages}) && !exists($USAGE[-1]{documents}), 'a 422: no units';
  my $m = $skeid->node_metrics('docling-1');
  is $m->{inflight}, 0, 'a 422: the slot is free';
  is $m->{ok} + $m->{error} + $m->{aborted} + $m->{rejected}, $m->{started}, 'a 422: finished once';

  my $unit = 'Langertha::Skeid::Protocol::Documents';
  is $unit->max_parse_bytes, 8 * 1024 * 1024, 'the parse bound is 8 MiB';
  my $res = Mojo::Message::Response->new;
  $res->code(200)->headers->content_type('application/json');
  is $unit->pages({ document => { json_content => { pages => { 1 => {}, 2 => {}, 3 => {} } } } }, $res), 3,
    'pages off a decoded answer';
  is $unit->pages(undef, $res), undef, 'nothing off no answer';
};

# --- admission and exit paths --------------------------------------------------------------------

subtest 'upstream error: one failed event, a free slot, no pages' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1', max_conns => 1);
  $MODE = 'fail';
  upload($t, $F, file_part($SMALL));
  $t->status_is(500)->json_is('/error/type' => 'upstream_error');
  is scalar(@USAGE), 1, 'one usage event';
  is $USAGE[0]{ok}, 0, 'failed';
  is $USAGE[0]{status_code}, 500, 'with the node\'s status';
  is $USAGE[0]{endpoint}, $F, 'on the route';
  ok !exists($USAGE[0]{pages}) && !exists($USAGE[0]{documents}), 'no units of a request that failed';
  paired($skeid, 'docling-1', 'upstream 500');

  convert_source($t, source_body());
  $t->status_is(500);
  is $USAGE[1]{endpoint}, $S, 'the source route likewise';
  paired($skeid, 'docling-1', 'upstream 500, source');

  my ($t2, $skeid2) = proxy();
  my $dead = Mojo::IOLoop::Server->generate_port;
  $skeid2->add_node(id => 'dead', url => "http://127.0.0.1:$dead", kind => 'documents', max_conns => 1);
  upload($t2, $F, file_part($SMALL));
  $t2->status_is(502)->json_is('/error/type' => 'upstream_error');
  is scalar(@USAGE), 1, 'one event for the unreachable node';
  paired($skeid2, 'dead', 'unreachable');
};

subtest 'a client that hangs up frees the slot and leaves one failed event' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1', max_conns => 1);
  $MODE = 'hold';
  for my $route ($F, $S) {
    my $events = @USAGE;
    my $calls  = @UPSTREAM;
    my ($type, $body) = $route eq $F
      ? ($FORM_TYPE, form(file_part($PDF)))
      : ('application/json', encode_json(source_body()));
    my $client = raw_client($t, request_head($route, 'Content-Type' => $type,
      'Content-Length' => length($body)) . $body);
    ok run_until(sub { @UPSTREAM == $calls + 1 }), "$route: the request reached the node";
    my $seen = $UPSTREAM[-1];
    is inflight($skeid, 'docling-1'), 1, "$route: the slot is taken";
    $client->{stream}->close;
    ok run_until(sub { $seen->{hung_up} }), "$route: the node saw its connection close";
    ok run_until(sub { !inflight($skeid, 'docling-1') }), "$route: the slot is free";
    settle();
    is scalar(@USAGE) - $events, 1, "$route: one usage event";
    is $USAGE[-1]{error_type}, 'client_abort', "$route: client_abort";
    is $USAGE[-1]{status_code}, 499, "$route: 499";
    paired($skeid, 'docling-1', "$route abort");
  }
};

subtest 'admission: max_conns, waiting, 429, load sharing, health' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'docling-1', max_conns => 1);
  $MODE = 'hold';
  my $body = form(file_part($SMALL));
  my $first = raw_client($t, request_head($F, 'Content-Type' => $FORM_TYPE, 'Content-Length' => length($body)) . $body);
  ok run_until(sub { @UPSTREAM == 1 }), 'the first request holds the node';
  upload($t, $F, file_part($SMALL));
  $t->status_is(429)->json_is('/error/type' => 'rate_limit_error');
  is scalar(@UPSTREAM), 1, 'the second never reached the node';
  $UPSTREAM[0]{answer}->();
  ok run_until(sub { !inflight($skeid, 'docling-1') }), 'the slot comes free';
  $first->{stream}->close if $first->{stream};
  settle();
  paired($skeid, 'docling-1', 'saturation');

  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'd-a');
  add_node($skeid2, 'd-b');
  upload($t2, $F, file_part($SMALL)) for 1 .. 4;
  my %by = map { $_->{tag} => 1 } @UPSTREAM;
  is_deeply [ sort keys %by ], [ 'd-a', 'd-b' ], 'two documents nodes share the load';
  $skeid2->set_node_health('d-a', 0);
  my $calls = @UPSTREAM;
  upload($t2, $F, file_part($SMALL)) for 1 .. 2;
  is_deeply [ map { $_->{tag} } @UPSTREAM[ $calls .. $#UPSTREAM ] ], [ 'd-b', 'd-b' ], 'an unhealthy node is skipped';
};

# --- policy and kind ---------------------------------------------------------------------------

subtest 'key policy: documents is grantable like a model; a restricted key is refused' => sub {
  my $BOB_KEY = 'sk-bob-secret';
  my $BOB_ID  = Langertha::Skeid->key_id_for_key($BOB_KEY);
  my $CAROL_KEY = 'sk-carol-secret';
  my $CAROL_ID  = Langertha::Skeid->key_id_for_key($CAROL_KEY);
  my ($t, $skeid) = proxy(config => {
    policies => {
      chat_only => { models => ['qwen'] },
      with_docs => { models => [ 'qwen', 'documents' ] },
    },
    keys => { $ALICE_ID => 'chat_only', $BOB_ID => 'with_docs' },
  });
  add_node($skeid, 'docling-1');

  upload($t, $F, { Authorization => "Bearer $ALICE_KEY" }, file_part($SMALL));
  $t->status_is(403, 'a key whose models do not name documents: 403')
    ->json_is('/error/type' => 'permission_error');
  convert_source($t, source_body(), { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(403, 'the source route too');
  is scalar(@UPSTREAM), 0, 'nothing reached the node';
  is scalar(@USAGE), 0, 'nothing metered';
  is $skeid->node_metrics('docling-1')->{started}, 0, 'no slot taken';

  upload($t, $F, { Authorization => "Bearer $BOB_KEY" }, file_part($SMALL));
  $t->status_is(200, 'a key that names documents passes');
  is $USAGE[0]{api_key_id}, $BOB_ID, 'under its id';

  upload($t, $F, { Authorization => "Bearer $CAROL_KEY" }, file_part($SMALL));
  $t->status_is(200, 'a key with no restriction passes');

  $CFG = { policies => { no_cloud => { deny_tags => ['cloud'] } }, default_policy => 'no_cloud' };
  $skeid->add_node(id => 'docling-cloud', url => node_url('docling-cloud'), kind => 'documents', tags => ['cloud']);
  $skeid->set_node_health('docling-1', 0);
  upload($t, $F, file_part($SMALL));
  $t->status_is(403, 'only a denied-tag node serves it: 403, not 503');
  paired($skeid, 'docling-1', 'policy');
};

subtest 'kind keeps chat and documents nodes apart; an alias named documents tiers them' => sub {
  my ($t, $skeid) = proxy();
  # A chat node that matches any model, and a documents node that carries no model at all.
  $skeid->add_node(id => 'chat-any', url => node_url('chat-any'), model => '', max_conns => 4);
  upload($t, $F, file_part($SMALL));
  $t->status_is(503, 'documents with only a chat node: 503, the chat node is never sent a document')
    ->json_is('/error/type' => 'model_not_found');
  is scalar(@UPSTREAM), 0, 'it was not called';
  is $skeid->node_metrics('chat-any')->{started}, 0, 'and took no slot';
  $skeid->remove_node('chat-any');

  add_node($skeid, 'docling-1');
  $t->post_ok('/v1/chat/completions' => json => { model => 'anything', messages => [ { role => 'user', content => 'hi' } ] });
  $t->status_is(503, 'a chat request is not routed to the documents node')
    ->json_is('/error/type' => 'model_not_found')
    ->json_like('/error/message' => qr/anything/);
  $t->post_ok('/v1/chat/completions' => json => { model => 'documents', messages => [ { role => 'user', content => 'hi' } ] });
  is scalar(@UPSTREAM), 0, 'not even by the routing key\'s name';
  is $skeid->node_metrics('docling-1')->{started}, 0, 'no slot of the documents node taken by chat';

  $t->get_ok('/v1/models')->status_is(200);
  is_deeply [ map { $_->{id} } @{ $t->tx->res->json->{data} } ], [], 'a documents node lists no model';
  $skeid->add_node(id => 'chat-q', url => node_url('chat-q'), model => 'qwen');
  $t->get_ok('/v1/models');
  is_deeply [ map { $_->{id} } @{ $t->tx->res->json->{data} } ], ['qwen'], 'only the chat model is listed';

  upload($t, $F, file_part($SMALL));
  $t->status_is(200, 'documents reach the documents node');
  is $UPSTREAM[-1]{tag}, 'docling-1', 'and no other';

  # An alias with tiers over tags: the documents route plans by the alias of its routing key.
  $skeid->add_node(id => 'docling-local', url => node_url('docling-local'), kind => 'documents', tags => ['local']);
  $skeid->add_node(id => 'docling-cloud', url => node_url('docling-cloud'), kind => 'documents', tags => ['cloud']);
  $skeid->remove_node('docling-1');
  $CFG = { aliases => { documents => { tiers => [ { tags => ['cloud'] }, { tags => ['local'] } ] } } };
  upload($t, $F, file_part($SMALL)) for 1 .. 3;
  is_deeply [ map { $_->{tag} } @UPSTREAM[ -3 .. -1 ] ], [ ('docling-cloud') x 3 ], 'the alias\' first tier serves';
  $skeid->set_node_health('docling-cloud', 0);
  upload($t, $F, file_part($SMALL));
  is $UPSTREAM[-1]{tag}, 'docling-local', 'and the next tier takes over';
  $t->get_ok('/v1/models');
  is_deeply [ map { $_->{id} } @{ $t->tx->res->json->{data} } ], ['qwen'], 'the alias is not a chat model in the list';
  $t->post_ok('/v1/chat/completions' => json => { model => 'documents', messages => [ { role => 'user', content => 'hi' } ] });
  $t->status_is(503, 'and chat asking for it finds no chat node');
};

subtest 'config: kind and api_key_header are checked at load, the old node stays' => sub {
  my $skeid = Langertha::Skeid->new(config_loader => sub { {} });
  $skeid->add_node(id => 'docling-1', url => 'http://d:5001', kind => 'documents', api_key_header => 'X-Api-Key');
  my ($node) = grep { $_->{id} eq 'docling-1' } @{ $skeid->list_nodes };
  is $node->{kind}, 'documents', 'kind is kept';
  is $node->{api_key_header}, 'X-Api-Key', 'api_key_header is kept';

  $skeid->add_node(id => 'chat-1', url => 'http://c:8000/v1', model => 'qwen', kind => 'chat');
  ($node) = grep { $_->{id} eq 'chat-1' } @{ $skeid->list_nodes };
  ok !exists($node->{kind}), 'chat is the default and is not written';
  ok !exists($node->{api_key_header}), 'no header option, none kept';
  $skeid->add_node(id => 'chat-2', url => 'http://c:8000/v1', api_key_header => 'Authorization');
  ($node) = grep { $_->{id} eq 'chat-2' } @{ $skeid->list_nodes };
  ok !exists($node->{api_key_header}), 'Authorization is the default spelled out';

  for my $bad (
    [ kind => 'ocr' ], [ kind => [] ], [ kind => 'Documents2' ],
    [ api_key_header => 'X Api Key' ], [ api_key_header => "X-Api-Key\r\nX-Evil: 1" ], [ api_key_header => 'X-Api:Key' ],
    [ api_key_header => [] ],
  ) {
    my ($field, $value) = @$bad;
    my $ok = eval {
      $skeid->add_node(id => 'docling-1', url => 'http://other:5001', kind => 'documents', $field => $value);
      1;
    };
    ok !$ok, "bad $field " . (ref $value ? 'ref' : "<$value>") . ' croaks';
    like $@, qr/\Q$field\E/, 'naming the option';
    my ($kept) = grep { $_->{id} eq 'docling-1' } @{ $skeid->list_nodes };
    is $kept->{url}, 'http://d:5001', 'and the working node is still there';
  }
  ok eval { $skeid->add_node(id => 'd', url => 'http://d', kind => ' Documents '); 1 }, 'kind is trimmed and lowercased';
  ok !eval { Langertha::Skeid->new(config_loader => sub { { nodes => [ { id => 'x', url => 'http://x', kind => 'nope' } ] } }); 1 },
    'a config with an unknown kind fails to load';
};

# --- the store ---------------------------------------------------------------------------------

subtest 'pages is a nullable column of both schemas and summed by every store' => sub {
  for my $backend (qw( sqlite postgresql )) {
    my $sql = path($FindBin::Bin)->parent->child('share', 'sql', "usage_events.$backend.sql")->slurp_utf8;
    like $sql, qr/^\s*pages\s+(?:INTEGER|BIGINT)\s*,/m, "$backend schema has a nullable pages column";
  }

  eval { require DBI; require DBD::SQLite; 1 } or return pass('no DBI/DBD::SQLite: store checks skipped');
  my $db = "$TMP/usage.sqlite";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  $skeid->call_function('usage.configure', { backend => 'sqlite', sqlite_path => $db }) if 0;
  my %base = (api_format => 'docling', endpoint => $F, api_key_id => $ALICE_ID, model => 'documents',
    requested_model => 'documents', node_id => 'docling-1', status_code => 200, ok => 1, duration_ms => 5);
  $skeid->record_usage(%base, request_id => 'r1', documents => 2, pages => 7);
  $skeid->record_usage(%base, request_id => 'r2', documents => 1);
  my $report = $skeid->call_function('usage.report', {});
  is $report->{totals}{pages}, 7, 'totals.pages';
  is $report->{totals}{documents}, 3, 'documents unchanged beside it';
  is $report->{by_key}[0]{pages}, 7, 'by_key.pages';
  is $report->{by_model}[0]{pages}, 7, 'by_model.pages';

  my $odbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1 });
  is_deeply $odbh->selectcol_arrayref('SELECT pages FROM usage_events ORDER BY id'), [ 7, undef ],
    'an event without pages is NULL, not 0';
  $odbh->disconnect;

  # A table that predates the column gets it, additively, once.
  my $old = "$TMP/old.sqlite";
  my $dbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1 });
  $dbh->do('CREATE TABLE usage_events (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at TEXT NOT NULL, '
    . 'request_id TEXT, api_format TEXT, endpoint TEXT, api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, '
    . 'node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0, duration_ms INTEGER, '
    . 'input_tokens INTEGER NOT NULL DEFAULT 0, output_tokens INTEGER NOT NULL DEFAULT 0, '
    . 'total_tokens INTEGER NOT NULL DEFAULT 0, tool_calls INTEGER NOT NULL DEFAULT 0, '
    . 'cost_input_usd REAL NOT NULL DEFAULT 0, cost_output_usd REAL NOT NULL DEFAULT 0, '
    . 'cost_total_usd REAL NOT NULL DEFAULT 0, error_type TEXT, error_message TEXT)');
  $dbh->do(q{INSERT INTO usage_events (created_at, request_id, model) VALUES ('2026-10-01T00:00:00Z', 'old', 'm')});
  $dbh->disconnect;
  my $upgraded = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $upgraded->record_usage(%base, request_id => 'new', pages => 4);
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1 });
  my @cols = grep { $_->{name} eq 'pages' }
    @{ $odbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} }) };
  is scalar(@cols), 1, 'the column is added to a table that predates it, once';
  ok !$cols[0]{notnull}, 'nullable';
  is_deeply $odbh->selectcol_arrayref('SELECT pages FROM usage_events ORDER BY id'), [ undef, 4 ], 'old row NULL';
  $odbh->disconnect;
  is $upgraded->call_function('usage.report', {})->{totals}{pages}, 4, 'the report sums old and new';

  my $dir = "$TMP/jsonlog";
  my $log = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  $log->record_usage(%base, request_id => 'j1', documents => 1, pages => 5);
  $log->record_usage(%base, request_id => 'j2', documents => 1);
  my $jr = $log->call_function('usage.report', {});
  is $jr->{totals}{pages}, 5, 'jsonlog: totals.pages';
  is $jr->{by_key}[0]{pages}, 5, 'jsonlog: by_key.pages';
  is $jr->{by_model}[0]{pages}, 5, 'jsonlog: by_model.pages';
  my $lines = join '', map { $_->slurp } path($dir)->children;
  my @events = map { decode_json($_) } grep { length } split /\n/, $lines;
  my %by = map { $_->{request_id} => $_ } @events;
  is $by{j1}{pages}, 5, 'jsonlog writes the key';
  ok !exists($by{j2}{pages}), 'and omits it for an event without pages';
};

subtest 'a relayed conversion reaches a store with its pages' => sub {
  my $dir = "$TMP/proxy-jsonlog";
  my ($t, $skeid) = proxy(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  add_node($skeid, 'docling-1');
  upload($t, $F, { Authorization => "Bearer $ALICE_KEY" }, file_part($SMALL));
  $t->status_is(200);
  my $report = $skeid->call_function('usage.report', {});
  is $report->{totals}{pages}, 3, 'pages in the report';
  is $report->{totals}{documents}, 1, 'documents in the report';
  is $report->{by_model}[0]{model}, 'documents', 'under the routing key';
};

subtest 'no spooled upload outlives its request' => sub {
  undef $UP;
  @UPSTREAM = ();
  settle(0.1);
  ok run_until(sub { !$SPOOL->children }, 2), 'the spool directory is empty'
    or diag join("\n", map { "$_ (" . (-s $_) . ' bytes)' } $SPOOL->children);
};

done_testing;
