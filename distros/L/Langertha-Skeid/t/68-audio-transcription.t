use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::Asset::File;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::Server::Daemon;
use Digest::SHA qw( sha1_hex );
use Encode ();
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS qw( decode_json encode_json );
use Path::Tiny qw( path );
use POSIX qw( WNOHANG );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Protocol::Audio;
use Langertha::Skeid::Proxy;

# The audio routes of the OpenAI face (skeid k91, ADR 0021): POST /v1/audio/transcriptions and
# /v1/audio/translations. A multipart upload comes in behind the client gate, is routed like a
# chat request and goes to the node's own audio endpoint part for part -- only `model` is
# rewritten when an alias tier serves another one. The answer comes back as the node gave it,
# JSON, plain text or an event stream, byte for byte. Skeid reads along for the usage event:
# tokens where the node reports them, audio_seconds where it reports a duration, and nothing
# where it reports nothing. The upstreams here are the two dialects a Whisper node speaks, vLLM
# and speaches (which is also OpenAI's own event dialect), plus OpenAI's token usage.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_K91_NODE_KEY SKEID_K91_UNSET_KEY SKEID_USAGE_DB )};

# Where the server spools an upload. A directory of its own, so the test can see that every
# spooled upload is gone once its request is over.
my $TMP   = tempdir(CLEANUP => 1);
my $SPOOL = path($TMP)->child('spool');
$SPOOL->mkpath;
$ENV{MOJO_TMPDIR} = "$SPOOL";

my $ALICE_KEY = 'sk-alice-secret';
my $ALICE_ID  = Langertha::Skeid->key_id_for_key($ALICE_KEY);
my $BOUNDARY  = 'k91-client-boundary-5d1c';

# 300 KiB of every byte value: above the 256 KiB at which the server spools a part to disk, so
# the upload Skeid relays is a file asset, and binary, so nothing may be decoded on the way.
srand(91);
my $AUDIO     = pack('C*', map { int(rand(256)) } 1 .. 307_200);
my $AUDIO_SHA = sha1_hex($AUDIO);
my $SMALL     = "RIFF\x00\x01\x02\xff small";

my $TEXT   = "Grüße aus Köln";
my @PIECES = ('Grüße ', 'aus ', 'Köln');
my $TEXT_BYTES = length(Encode::encode_utf8($TEXT));

my (@UPSTREAM, @USAGE, @LOG);
# What the fake upstream does instead of answering: 'fail' (500), 'hold' (answers when told),
# 'cut' (a stream that ends without its chunked terminator).
my $MODE = '';
my $CFG  = {};

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
sub utf8_json { return $JSON->encode($_[0]) }
sub frame { return 'data: ' . utf8_json($_[0]) . "\n\n" }

# The answers of one upstream dialect, as the bytes it sends.
sub vllm_stream {
  my ($kind, $include_usage) = @_;
  my $object = $kind eq 'translations' ? 'translation.chunk' : 'transcription.chunk';
  return join '',
    (map { frame({ id => 'transcribe-1', object => $object, choices => [{ delta => { content => $_ } }] }) } @PIECES),
    ($include_usage
      ? frame({ id => 'transcribe-1', object => $object, choices => [],
          usage => { prompt_tokens => 21, completion_tokens => 9, total_tokens => 30 } })
      : ()),
    "data: [DONE]\n\n";
}

sub speaches_stream {
  return join '',
    (map { frame({ type => 'transcript.text.delta', delta => $_ }) } @PIECES),
    frame({ type => 'transcript.text.done', text => $TEXT });
}

sub openai_stream {
  return join '',
    (map { "event: transcript.text.delta\n" . frame({ type => 'transcript.text.delta', delta => $_ }) } @PIECES),
    "event: transcript.text.done\n" . frame({ type => 'transcript.text.done', text => $TEXT,
      usage => { type => 'tokens', input_tokens => 14, output_tokens => 45, total_tokens => 59 } });
}

my $SRT = "1\n00:00:00,000 --> 00:00:02,500\n$TEXT\n\n";

sub settle {
  my ($seconds) = @_;
  Mojo::IOLoop->timer(($seconds // 0.05) => sub { Mojo::IOLoop->stop });
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

# One fake upstream route per dialect, node tag and endpoint. It records the form as it arrived
# -- the parts in order, the file's digest, whether the server took it from disk -- and answers
# as that dialect does for the form's response_format and stream fields.
sub fake_upstream {
  my ($c) = @_;
  my $req     = $c->req;
  my $flavour = $c->stash('flavour');
  my $kind    = $c->stash('kind');
  my $upload  = $req->upload('file');
  my $seen = {
    flavour       => $flavour,
    tag           => $c->stash('tag'),
    kind          => $kind,
    content_type  => $req->headers->content_type,
    expect        => $req->headers->header('Expect'),
    authorization => $req->headers->authorization,
    x_api_key     => $req->headers->header('x-api-key'),
    parts         => [ map { {
      disposition => $_->headers->content_disposition,
      type        => $_->headers->content_type,
      size        => $_->asset->size,
    } } @{ $req->content->is_multipart ? $req->content->parts : [] } ],
    fields        => { map { $_ => $req->body_params->every_param($_) } @{ $req->body_params->names } },
    ($upload ? (
      file_sha  => sha1_hex($upload->slurp),
      file_size => $upload->size,
      filename  => $upload->filename,
      file_type => $upload->headers->content_type,
    ) : ()),
    answered => 0,
    hung_up  => 0,
  };
  push @UPSTREAM, $seen;
  $c->on(finish => sub { $seen->{hung_up} = 1 unless $seen->{answered}; delete $seen->{answer} });

  # A form has only strings; a FastAPI node reads its booleans as pydantic does.
  my $last = sub { my $values = $seen->{fields}{ $_[0] } || []; return $values->[-1] };
  my $true = sub { return lc($last->($_[0]) // '') =~ /\A(?:1|true|on|yes|t|y)\z/ ? 1 : 0 };
  my $format = $last->('response_format') // 'json';
  my $stream = $true->('stream');
  my $with_usage = $true->('stream_include_usage');

  if ($MODE eq 'fail') {
    $seen->{answered} = 1;
    return $c->render(status => 500,
      json => { error => { message => 'CUDA out of memory', type => 'server_error' } });
  }

  if ($MODE eq 'hold') {
    $c->render_later;
    Mojo::IOLoop->stream($c->tx->connection)->timeout(0);
    if ($stream) {
      $c->res->headers->content_type('text/event-stream');
      $c->write_chunk(frame({ type => 'transcript.text.delta', delta => $PIECES[0] }) => sub { });
    }
    $seen->{answer} = sub { $seen->{answered} = 1; $c->render(json => { text => $TEXT }) };
    return;
  }

  if ($MODE eq 'cut') {
    $c->res->headers->content_type('text/event-stream');
    $seen->{answered} = 1;
    my $id = $c->tx->connection;
    return $c->write_chunk(frame({ type => 'transcript.text.delta', delta => $PIECES[0] }) => sub {
      Mojo::IOLoop->timer(0.02 => sub {
        my $stream = Mojo::IOLoop->stream($id) or return;
        $stream->close;
      });
    });
  }

  $seen->{answered} = 1;
  if ($stream) {
    my $bytes = $flavour eq 'vllm'     ? vllm_stream($kind, $with_usage)
              : $flavour eq 'speaches' ? speaches_stream()
              :                          openai_stream();
    $c->res->headers->content_type('text/event-stream; charset=utf-8');
    # In pieces that do not respect frame boundaries, as a network does.
    my @pieces = unpack('(a37)*', $bytes);
    $c->write_chunk($_) for @pieces;
    return $c->finish;
  }

  return $c->render(data => Encode::encode_utf8($TEXT) . "\n", format => 'txt') if $format eq 'text';
  if ($format eq 'srt') {
    $c->res->headers->content_type('text/plain; charset=utf-8');
    return $c->render(data => Encode::encode_utf8($SRT));
  }
  if ($format eq 'verbose_json') {
    return $c->render(json => {
      task => ($kind eq 'translations' ? 'translate' : 'transcribe'), language => 'de',
      duration => 7.25, text => $TEXT,
      segments => [{ id => 0, start => 0, end => 7.25, text => $TEXT }],
    });
  }
  return $c->render(json => { text => $TEXT, usage => undef }) if $flavour eq 'speaches';
  return $c->render(json => { text => $TEXT,
    usage => { type => 'tokens', input_tokens => 14, output_tokens => 45, total_tokens => 59,
      input_token_details => { text_tokens => 0, audio_tokens => 14 } } }) if $flavour eq 'openai';
  # vLLM: seconds on a transcription, nothing on a translation.
  return $c->render(json => { text => $TEXT }) if $kind eq 'translations';
  return $c->render(json => { text => $TEXT, usage => { type => 'duration', seconds => 12 } });
}

# A proxy over a Skeid whose config comes from $CFG (so a test changes it live), with the fake
# upstreams mounted on the same app, outside the client routes.
my $UP;
sub proxy {
  my (%opts) = @_;
  $CFG = delete($opts{config}) || {};
  @UPSTREAM = @USAGE = @LOG = ();
  $MODE = '';
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
  $app->routes->post('/__up/:flavour/:tag/v1/audio/:kind' => \&fake_upstream);
  my $t = Test::Mojo->new($app);
  $UP = $t->ua->server->nb_url->clone;
  return ($t, $skeid);
}

sub node_url { my ($flavour, $tag) = @_; return $UP->clone->path("/__up/$flavour/$tag/v1")->to_string }

sub add_node {
  my ($skeid, $id, $flavour, %extra) = @_;
  return $skeid->add_node(
    id => $id, url => node_url($flavour, $id), model => 'whisper', engine => 'openai',
    max_conns => 4, %extra,
  );
}

# The form, written out by hand so the test decides every byte of it: the order of the parts,
# how a name is quoted, which headers a part has.
# Names and text values are characters and go out as UTF-8; a file's content is bytes already.
sub field {
  my ($name, $value) = @_;
  return [ [ Encode::encode_utf8(qq{Content-Disposition: form-data; name="$name"}) ], Encode::encode_utf8($value) ];
}

sub file_part {
  my ($bytes, %o) = @_;
  return [ [
    Encode::encode_utf8('Content-Disposition: form-data; name="file"; filename="' . ($o{filename} // 'speech.wav') . '"'),
    'Content-Type: ' . ($o{type} // 'audio/wav'),
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

sub upload {
  my ($t, $path, @parts) = @_;
  my $headers = ref($parts[0]) eq 'HASH' ? shift(@parts) : {};
  return $t->post_ok($path => { 'Content-Type' => $FORM_TYPE, %$headers } => form(@parts));
}

sub inflight { my ($skeid, $id) = @_; return $skeid->node_metrics($id)->{inflight} }

sub paired {
  my ($skeid, $id, $label) = @_;
  my $m = $skeid->node_metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted}, $m->{started},
    "$label: every request.start on $id has its request.finish";
  return $m;
}

# A raw connection: it can stop sending in the middle of a request and hang up, which a
# well-behaved user agent does not do.
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

my $T  = '/v1/audio/transcriptions';
my $TL = '/v1/audio/translations';

subtest 'the form goes upstream as the client sent it, the upload from disk' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');

  # Every time a spooled file is read into memory as a whole. The fake node does it once, to
  # take the digest; Skeid has no business doing it at all.
  my @slurped;
  {
    no warnings 'redefine';
    my $slurp = \&Mojo::Asset::File::slurp;
    local *Mojo::Asset::File::slurp = sub { push @slurped, $_[0]->size; return $slurp->(@_) };
    upload($t, $T, { Authorization => "Bearer $ALICE_KEY", 'X-Request-Id' => 'req-k91-1' },
      field(model => 'whisper'),
      file_part($AUDIO, filename => 'Besprechung März.wav', type => 'audio/x-wav'),
      field(language => 'de'),
      field(prompt => "Köln, Grüße"),
      field('timestamp_granularities[]' => 'word'),
      field(temperature => '0.2'),
      field('timestamp_granularities[]' => 'segment'),
      field(vad_filter => 'true'),
    );
  }
  is_deeply \@slurped, [ length($AUDIO) ],
    'the upload is read into memory once, by the node: Skeid sends it from the spooled file';
  $t->status_is(200)
    ->header_is('x-skeid-node' => 'gpu-1')
    ->header_is('x-request-id' => 'req-k91-1')
    ->json_is('/text' => $TEXT)
    ->json_is('/usage/seconds' => 12, 'the answer is the upstream\'s own, usage block included');

  is scalar(@UPSTREAM), 1, 'one upstream call';
  my $seen = $UPSTREAM[0];
  is $seen->{kind}, 'transcriptions', 'at the node\'s /audio/transcriptions';
  is $seen->{content_type}, $FORM_TYPE, 'with the client\'s content type and boundary';
  is $seen->{file_size}, length($AUDIO), 'the file arrives whole';
  is $seen->{file_sha}, $AUDIO_SHA, 'and unchanged, byte for byte';
  is $seen->{filename}, 'Besprechung März.wav', 'under the client\'s file name';
  is $seen->{file_type}, 'audio/x-wav', 'and media type';
  is_deeply $seen->{fields}{'timestamp_granularities[]'}, [ 'word', 'segment' ],
    'a repeated field arrives as often as it was sent, in order';
  is_deeply $seen->{fields}{vad_filter}, ['true'], 'a field Skeid does not know passes through';
  is_deeply $seen->{fields}{language}, ['de'], 'language passes through';
  is_deeply $seen->{fields}{temperature}, ['0.2'], 'temperature passes through';
  is $seen->{fields}{prompt}[0], 'Köln, Grüße', 'a non-ASCII field arrives as it was sent';
  is_deeply $seen->{fields}{model}, ['whisper'], 'model as the client named it';
  is_deeply [ map { $_->{disposition} =~ /name="([^"]+)"/ ? $1 : '?' } @{ $seen->{parts} } ],
    [ 'model', 'file', 'language', 'prompt', 'timestamp_granularities[]', 'temperature',
      'timestamp_granularities[]', 'vad_filter' ],
    'the parts keep the client\'s order';
  is $seen->{authorization}, "Bearer $ALICE_KEY",
    'a node that names no key source gets the client\'s Authorization (pass-through)';
  cmp_ok scalar($SPOOL->children), '>=', 1, 'the upload was spooled to disk, not held in memory';

  is scalar(@USAGE), 1, 'one usage event';
  my $ev = $USAGE[0];
  is $ev->{endpoint}, $T, 'event endpoint';
  is $ev->{api_format}, 'openai', 'event api_format';
  is $ev->{api_key_id}, $ALICE_ID, 'event customer key id';
  is $ev->{model}, 'whisper', 'event model';
  is $ev->{requested_model}, 'whisper', 'event requested_model';
  is $ev->{node_id}, 'gpu-1', 'event node';
  is $ev->{request_id}, 'req-k91-1', 'event request id';
  is $ev->{status_code}, 200, 'event status';
  is $ev->{ok}, 1, 'event ok';
  is $ev->{audio_seconds}, 12, 'audio_seconds from usage.seconds of a duration usage block';
  is $ev->{total_tokens}, 0, 'a duration is not turned into tokens';
  is $ev->{cost_total_usd}, 0, 'and not priced';
  ok !exists($ev->{content_bytes}), 'a non-streamed event carries no content_bytes';
  paired($skeid, 'gpu-1', 'json answer');
};

subtest 'a small upload stays in memory and is relayed all the same' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');
  upload($t, $T, file_part($SMALL), field(model => 'whisper'));
  $t->status_is(200)->json_is('/text' => $TEXT);
  is $UPSTREAM[0]{file_sha}, sha1_hex($SMALL), 'the small file arrives unchanged';
  is $USAGE[0]{api_key_id}, 'anonymous', 'a caller without a key is anonymous, as on every route';
};

subtest 'what the node reports is what the event carries' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');

  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(response_format => 'verbose_json'));
  $t->status_is(200)->json_is('/duration' => 7.25)->json_is('/segments/0/text' => $TEXT);
  is $USAGE[-1]{audio_seconds}, 7.25, 'verbose_json: audio_seconds from the top-level duration';
  is $USAGE[-1]{total_tokens}, 0, 'verbose_json: no tokens';

  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(response_format => 'text'));
  $t->status_is(200)->content_type_like(qr{^text/plain})
    ->content_is("$TEXT\n", 'text: the plain body is relayed untouched');
  is $t->tx->res->body, Encode::encode_utf8($TEXT) . "\n", 'text: byte for byte';
  is $USAGE[-1]{status_code}, 200, 'text: event written';
  is $USAGE[-1]{ok}, 1, 'text: event ok';
  ok !exists($USAGE[-1]{audio_seconds}), 'text: no audio_seconds key -- not measured, not zero';
  is $USAGE[-1]{total_tokens}, 0, 'text: no tokens';

  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(response_format => 'srt'));
  $t->status_is(200);
  is $t->tx->res->body, Encode::encode_utf8($SRT), 'srt: the subtitle body is relayed byte for byte';
  ok !exists($USAGE[-1]{audio_seconds}), 'srt: no audio_seconds key';

  is scalar(@USAGE), 3, 'one event per request';
  paired($skeid, 'gpu-1', 'answer shapes');

  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'sp-1', 'speaches');
  upload($t2, $T, field(model => 'whisper'), file_part($SMALL));
  $t2->status_is(200)->json_is('/text' => $TEXT)->json_is('/usage' => undef);
  ok !exists($USAGE[-1]{audio_seconds}), 'speaches json, usage null: no audio_seconds key';
  is $USAGE[-1]{ok}, 1, 'speaches json: event ok';

  my ($t3, $skeid3) = proxy();
  add_node($skeid3, 'oa-1', 'openai');
  upload($t3, $T, field(model => 'whisper'), file_part($SMALL));
  $t3->status_is(200)->json_is('/usage/type' => 'tokens');
  is $USAGE[-1]{input_tokens}, 14, 'OpenAI token usage: input tokens';
  is $USAGE[-1]{output_tokens}, 45, 'OpenAI token usage: output tokens';
  is $USAGE[-1]{total_tokens}, 59, 'OpenAI token usage: total tokens';
  ok !exists($USAGE[-1]{audio_seconds}), 'OpenAI token usage: no audio_seconds key';
};

subtest 'translations go to the node\'s other endpoint' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');
  upload($t, $TL, field(model => 'whisper'), file_part($SMALL));
  $t->status_is(200)->json_is('/text' => $TEXT)->json_hasnt('/usage');
  is $UPSTREAM[0]{kind}, 'translations', 'the node\'s /audio/translations was called';
  is $UPSTREAM[0]{file_sha}, sha1_hex($SMALL), 'with the file';
  is $USAGE[0]{endpoint}, $TL, 'event endpoint is the translations route';
  ok !exists($USAGE[0]{audio_seconds}), 'a translation that reports no usage has no audio_seconds';

  upload($t, $TL, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'));
  $t->status_is(200);
  is $t->tx->res->body, vllm_stream('translations', 0), 'a translation stream is relayed byte for byte';
  is $UPSTREAM[1]{kind}, 'translations', 'the stream went to /audio/translations too';
  is $USAGE[1]{endpoint}, $TL, 'stream event endpoint';
  paired($skeid, 'gpu-1', 'translations');
};

subtest 'streams are relayed byte for byte in every dialect' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');

  upload($t, $T, field(model => 'whisper'), file_part($AUDIO), field(stream => 'true'));
  $t->status_is(200)->content_type_like(qr{^text/event-stream})->header_is('x-skeid-node' => 'gpu-1');
  is $t->tx->res->body, vllm_stream('transcriptions', 0), 'vLLM stream without a usage frame: identical';
  like $t->tx->res->body, qr/data: \[DONE\]\n\n\z/, 'its [DONE] is relayed';
  is $UPSTREAM[-1]{file_sha}, $AUDIO_SHA, 'the upload of a streamed request arrives intact';
  ok !exists($UPSTREAM[-1]{fields}{stream_include_usage}), 'Skeid adds no field to the form';
  is_deeply $UPSTREAM[-1]{fields}{stream}, ['true'], 'stream goes through as sent';
  my $ev = $USAGE[-1];
  is $ev->{ok}, 1, 'no usage frame: event ok';
  is $ev->{content_bytes}, $TEXT_BYTES, 'no usage frame: content_bytes counts the delta text in UTF-8 bytes';
  is $ev->{total_tokens}, 0, 'no usage frame: no tokens invented';
  ok !exists($ev->{audio_seconds}), 'no usage frame: no audio_seconds';

  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'),
    field(stream_include_usage => 'true'));
  $t->status_is(200);
  is $t->tx->res->body, vllm_stream('transcriptions', 1), 'vLLM stream with a usage frame: identical';
  $ev = $USAGE[-1];
  is $ev->{input_tokens}, 21, 'usage frame: input tokens';
  is $ev->{output_tokens}, 9, 'usage frame: output tokens';
  is $ev->{total_tokens}, 30, 'usage frame: total tokens';
  is $ev->{content_bytes}, $TEXT_BYTES, 'usage frame: content_bytes';
  is $ev->{endpoint}, $T, 'stream event endpoint';

  # `stream` is a string in a form. What the node reads as true has to be a stream for Skeid
  # too, or the event stream is held back until it is complete and its usage never read.
  for my $on (qw( True TRUE 1 on yes t Y )) {
    upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(stream => $on),
      field(stream_include_usage => 'true'));
    $t->status_is(200);
    is $USAGE[-1]{content_bytes}, $TEXT_BYTES, "stream=$on is relayed as a stream";
    is $USAGE[-1]{total_tokens}, 30, "stream=$on: and its usage frame is read";
  }
  for my $off ('false', '0', 'no', '', 'maybe') {
    upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(stream => $off));
    $t->status_is(200)->json_is('/text' => $TEXT);
    ok !exists($USAGE[-1]{content_bytes}), "stream=<$off> is not a stream";
  }
  # The last one decides, as for the node.
  upload($t, $T, field(stream => 'true'), field(model => 'whisper'), file_part($SMALL), field(stream => 'false'));
  $t->status_is(200)->json_is('/text' => $TEXT);
  ok !exists($USAGE[-1]{content_bytes}), 'of two stream fields the last decides';
  paired($skeid, 'gpu-1', 'vLLM streams');

  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'sp-1', 'speaches');
  upload($t2, $T, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'));
  $t2->status_is(200);
  is $t2->tx->res->body, speaches_stream(), 'speaches stream, ended by EOF without [DONE]: identical';
  unlike $t2->tx->res->body, qr/\[DONE\]/, 'no [DONE] is made up';
  $ev = $USAGE[-1];
  is $ev->{ok}, 1, 'EOF-terminated stream: event ok';
  is $ev->{status_code}, 200, 'EOF-terminated stream: status';
  is $ev->{content_bytes}, $TEXT_BYTES, 'transcript.text.delta frames count into content_bytes';
  is $ev->{total_tokens}, 0, 'speaches stream: no tokens';
  ok !exists($ev->{audio_seconds}), 'speaches stream: no audio_seconds';
  paired($skeid2, 'sp-1', 'speaches stream');

  my ($t3, $skeid3) = proxy();
  add_node($skeid3, 'oa-1', 'openai');
  upload($t3, $T, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'));
  $t3->status_is(200);
  is $t3->tx->res->body, openai_stream(), 'OpenAI event stream with event: lines: identical';
  $ev = $USAGE[-1];
  is $ev->{input_tokens}, 14, 'transcript.text.done usage: input tokens';
  is $ev->{output_tokens}, 45, 'transcript.text.done usage: output tokens';
  is $ev->{content_bytes}, $TEXT_BYTES, 'OpenAI stream: content_bytes';
};

subtest 'an alias tier rewrites model and nothing else' => sub {
  my ($t, $skeid) = proxy(config => {
    aliases => { transcribe => { tiers => [ { model => 'whisper' } ] } },
  });
  add_node($skeid, 'gpu-1', 'vllm');

  upload($t, $T, file_part($AUDIO), field(language => 'de'), field(model => 'transcribe'),
    field('timestamp_granularities[]' => 'word'), field('timestamp_granularities[]' => 'segment'));
  $t->status_is(200)->json_is('/text' => $TEXT);
  my $seen = $UPSTREAM[0];
  is_deeply $seen->{fields}{model}, ['whisper'], 'the node is asked for the served model';
  is $seen->{file_sha}, $AUDIO_SHA, 'the file is untouched by the rewrite';
  is_deeply $seen->{fields}{'timestamp_granularities[]'}, [ 'word', 'segment' ], 'repeated fields too';
  is_deeply [ map { $_->{disposition} =~ /name="([^"]+)"/ ? $1 : '?' } @{ $seen->{parts} } ],
    [ 'file', 'language', 'model', 'timestamp_granularities[]', 'timestamp_granularities[]' ],
    'the rewritten part keeps its place';
  is $seen->{content_type}, $FORM_TYPE, 'and the boundary is still the client\'s';
  is $USAGE[0]{model}, 'whisper', 'event model is the served one';
  is $USAGE[0]{requested_model}, 'transcribe', 'event requested_model is what the client asked for';

  upload($t, $T, file_part($SMALL), field(model => 'transcribe'), field(stream => 'true'));
  $t->status_is(200);
  is_deeply $UPSTREAM[1]{fields}{model}, ['whisper'], 'a streamed request is rewritten the same way';
  is $USAGE[1]{requested_model}, 'transcribe', 'stream event requested_model';
};

subtest 'two nodes of one model share the load; max_conns and health are respected' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-a', 'vllm', max_conns => 1);
  add_node($skeid, 'gpu-b', 'vllm', max_conns => 1);

  my %served;
  for (1 .. 6) {
    upload($t, $T, field(model => 'whisper'), file_part($SMALL));
    $t->status_is(200);
    $served{ $t->tx->res->headers->header('x-skeid-node') }++;
  }
  is_deeply \%served, { 'gpu-a' => 3, 'gpu-b' => 3 }, 'six requests, three per node';
  is_deeply [ sort map { $_->{tag} } @UPSTREAM ], [ ('gpu-a') x 3, ('gpu-b') x 3 ],
    'and each node\'s own upstream saw its three';

  # Both slots held: the third request finds no capacity and is not forwarded.
  $MODE = 'hold';
  my $before = scalar @UPSTREAM;
  my @held = map {
    raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE,
      'Content-Length' => length(form(field(model => 'whisper'), file_part($SMALL))))
      . form(field(model => 'whisper'), file_part($SMALL)))
  } 1 .. 2;
  ok run_until(sub { @UPSTREAM == $before + 2 }), 'two requests are held upstream';
  is_deeply [ sort map { $_->{tag} } @UPSTREAM[ $before .. $before + 1 ] ], [ 'gpu-a', 'gpu-b' ],
    'one on each node, as max_conns 1 demands';
  is inflight($skeid, 'gpu-a') + inflight($skeid, 'gpu-b'), 2, 'both slots are taken';

  upload($t, $T, field(model => 'whisper'), file_part($SMALL));
  $t->status_is(429, 'a third request is refused once the wait is over')
    ->json_is('/error/type' => 'rate_limit_error');
  is scalar(@UPSTREAM), $before + 2, 'and was never forwarded';

  $MODE = '';
  $_->{answer}->() for grep { $_->{answer} } @UPSTREAM;
  ok run_until(sub { !inflight($skeid, 'gpu-a') && !inflight($skeid, 'gpu-b') }), 'the held requests finish';
  $_->{stream}->close for grep { $_->{stream} } @held;

  $skeid->set_node_health('gpu-a', 0);
  %served = ();
  for (1 .. 3) {
    upload($t, $T, field(model => 'whisper'), file_part($SMALL));
    $t->status_is(200);
    $served{ $t->tx->res->headers->header('x-skeid-node') }++;
  }
  is_deeply \%served, { 'gpu-b' => 3 }, 'an unhealthy node gets nothing';

  $skeid->set_node_health('gpu-b', 0);
  my $calls = scalar @UPSTREAM;
  upload($t, $T, field(model => 'whisper'), file_part($SMALL));
  $t->status_is(503)->json_is('/error/type' => 'model_not_found');
  is scalar(@UPSTREAM), $calls, 'no healthy node: nothing forwarded';
  paired($skeid, $_, 'load sharing') for qw( gpu-a gpu-b );
};

subtest 'a form Skeid cannot route is refused before any node is touched' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');

  my %refused = (
    'no model field'     => [ file_part($SMALL), field(language => 'de') ],
    'an empty model'     => [ field(model => ''), file_part($SMALL) ],
    'two model fields'   => [ field(model => 'whisper'), file_part($SMALL), field(model => 'other') ],
    'a model too long to be one' => [ field(model => 'w' x 5000), file_part($SMALL) ],
  );
  for my $case (sort keys %refused) {
    upload($t, $T, @{ $refused{$case} });
    $t->status_is(400, "$case: 400")
      ->json_is('/error/type' => 'invalid_request_error', "$case: OpenAI error shape")
      ->json_like('/error/message' => qr/model/, "$case: the message names the field");
  }

  # A second model field cannot hide behind a spelling the node reads and Skeid would not.
  for my $disposition (
    'Content-Disposition: form-data; name=model',
    'Content-Disposition: form-data; NAME="model"',
    'Content-Disposition: form-data;name = "model"',
    'content-disposition: form-data; name="model"',
    'Content-Disposition: form-data; name="x"; name="model"',
    'Content-Disposition: form-data; name="mod\\el"',
    'Content-Disposition: name="model"',
  ) {
    upload($t, $T, field(model => 'whisper'), file_part($SMALL), [ [$disposition], 'other' ]);
    $t->status_is(400, "second model field spelled <$disposition>: 400");
  }
  upload($t, $T, field(model => 'whisper'), file_part($SMALL),
    [ [q{Content-Disposition: form-data; name*=UTF-8''model}], 'other' ]);
  $t->status_is(400, 'a name* parameter is refused, not skipped')
    ->json_is('/error/type' => 'invalid_request_error');

  $t->post_ok($T => json => { model => 'whisper', file => 'x' });
  $t->status_is(400, 'a JSON body: 400')
    ->json_is('/error/type' => 'invalid_request_error')
    ->json_like('/error/message' => qr/multipart/);
  $t->post_ok($T => form => { model => 'whisper' });
  $t->status_is(400, 'a urlencoded form: 400');

  upload($t, $T, field(model => 'no-such-model'), file_part($SMALL));
  $t->status_is(503, 'a model no node serves: 503')->json_is('/error/type' => 'model_not_found');

  is scalar(@UPSTREAM), 0, 'nothing was forwarded';
  is scalar(@USAGE), 0, 'nothing was metered';
  is $skeid->node_metrics('gpu-1')->{started}, 0, 'no request.start on the node';

  # A file part named model is a file, not the field.
  upload($t, $T, field(model => 'whisper'),
    [ [ 'Content-Disposition: form-data; name="model"; filename="model.bin"' ], 'not a model' ],
    file_part($SMALL));
  $t->status_is(200, 'an upload that happens to be called model does not count as the field');

  # An unquoted name, as some clients write it, is read like a quoted one.
  upload($t, $T, [ ['Content-Disposition: form-data; name=model'], 'whisper' ], file_part($SMALL),
    [ ['Content-Disposition: form-data; name=stream'], 'true' ]);
  $t->status_is(200, 'an unquoted name=model is the model field');
  ok exists($USAGE[-1]{content_bytes}), 'and an unquoted name=stream the stream field';
};

subtest 'uploads.max_bytes: 413 without touching a node, hot reloaded' => sub {
  my ($t, $skeid) = proxy(config => { uploads => { max_bytes => 4096 } });
  add_node($skeid, 'gpu-1', 'vllm');
  is $skeid->upload_max_bytes, 4096, 'the limit is read from the config';

  upload($t, $T, field(model => 'whisper'), file_part('a' x 8192));
  $t->status_is(413, 'a body over the limit: 413')
    ->json_is('/error/type' => 'invalid_request_error', 'in the OpenAI error shape')
    ->json_like('/error/message' => qr/4096/, 'naming the limit');
  is scalar(@UPSTREAM), 0, 'no upstream call';
  is scalar(@USAGE), 0, 'no usage event';
  is $skeid->node_metrics('gpu-1')->{started}, 0, 'no request.start';
  is inflight($skeid, 'gpu-1'), 0, 'nothing in flight';

  upload($t, $T, field(model => 'whisper'), file_part('a' x 1024));
  $t->status_is(200, 'a body under the limit passes');

  # The limit holds while the body arrives: the head declares more than the limit, a few bytes
  # of body follow, and the answer is there without the rest having been sent.
  my $client = raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE, 'Content-Length' => 20_000_000)
    . "--$BOUNDARY\r\n");
  ok run_until(sub { $client->{buffer} =~ m{\r\n\r\n.*\}}s }), 'answered while the body was still outstanding';
  like $client->{buffer}, qr{\AHTTP/1\.1 413 }, 'with 413';
  like $client->{buffer}, qr/invalid_request_error/, 'in the OpenAI error shape';
  ok run_until(sub { $client->{closed} }), 'and the connection is closed, the body is not waited for';

  # A body of undeclared length is cut off too, once it is past the limit and the head's allowance.
  my $chunk = 'b' x 65536;
  my $chunked = raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE, 'Transfer-Encoding' => 'chunked')
    . join('', map { sprintf("%x\r\n", length($chunk)) . $chunk . "\r\n" } 1 .. 20));
  ok run_until(sub { $chunked->{buffer} =~ m{\r\n\r\n.*\}}s }), 'a chunked body past the limit is answered unterminated';
  like $chunked->{buffer}, qr{\AHTTP/1\.1 413 }, 'with 413';
  ok run_until(sub { $chunked->{closed} }), 'and cut off';

  # One that ends inside that allowance is whole when the route runs, and measured exactly there.
  my $whole = form(field(model => 'whisper'), file_part('c' x 8192));
  my $complete = raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE, 'Transfer-Encoding' => 'chunked')
    . sprintf("%x\r\n", length($whole)) . $whole . "\r\n0\r\n\r\n");
  ok run_until(sub { $complete->{buffer} =~ m{\r\n\r\n.*\}}s }), 'a complete chunked body over the limit is answered';
  like $complete->{buffer}, qr{\AHTTP/1\.1 413 }, 'with 413, though it declared no length';
  $complete->{stream}->close if $complete->{stream};

  is scalar(@UPSTREAM), 1, 'still only the one request that fit was forwarded';
  is scalar(@USAGE), 1, 'and metered';

  # Raised: holds from the next request.
  $CFG = { uploads => { max_bytes => 1_000_000 } };
  upload($t, $T, field(model => 'whisper'), file_part($AUDIO));
  $t->status_is(200, 'after raising the limit the 300 KiB upload passes');
  is $UPSTREAM[-1]{file_sha}, $AUDIO_SHA, 'intact';

  $CFG = { uploads => { max_bytes => 100_000 } };
  upload($t, $T, field(model => 'whisper'), file_part($AUDIO));
  $t->status_is(413, 'after lowering it the same upload is refused');

  # Removed from the config: the built-in default again.
  $CFG = {};
  upload($t, $T, field(model => 'whisper'), file_part($AUDIO));
  $t->status_is(200, 'with the section removed the default limit applies');
  is $skeid->upload_max_bytes, 26214400, 'which is 25 MiB';

  # The JSON routes do not take their limit from uploads.
  $CFG = { uploads => { max_bytes => 10 } };
  $skeid->add_node(id => 'chat-1', url => node_url('vllm', 'chat-1'), model => 'chat', max_conns => 2);
  $t->post_ok('/v1/chat/completions' => json => { model => 'none', messages => [{ role => 'user', content => 'x' x 4000 }] });
  $t->status_is(503, 'a chat request far over uploads.max_bytes is routed as ever (no such model here)');
  paired($skeid, 'gpu-1', 'upload limit');

  for my $bad ({ max_bytes => 0 }, { max_bytes => '10MB' }, { max_bytes => -1 }, { max_byte => 5 }, [], 5) {
    my $ok = eval { Langertha::Skeid->new(config_loader => sub { { uploads => $bad } }); 1 };
    ok !$ok, 'a broken uploads section fails the load: ' . encode_json([$bad]);
    like $@, qr/uploads/, 'and the error names the section';
  }
};

subtest 'the default limit lets through what the server alone would not' => sub {
  # The server's own request limit is 16 MiB; uploads.max_bytes defaults to 25 MiB and replaces
  # it on these routes. The node answers on its own server here, so its limit is its own affair.
  my ($t, $skeid) = proxy();
  my $node = Mojolicious->new;
  $node->log->level('fatal');
  $node->max_request_size(0);
  my $got;
  $node->routes->post('/v1/audio/transcriptions' => sub {
    my ($c) = @_;
    my $upload = $c->req->upload('file');
    $got = { size => $upload->size, sha => sha1_hex($upload->slurp) };
    $c->render(json => { text => 'big' });
  });
  my $daemon = Mojo::Server::Daemon->new(app => $node, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  $skeid->add_node(id => 'big', url => 'http://127.0.0.1:' . $daemon->ports->[0] . '/v1', model => 'whisper',
    max_conns => 1);

  my $big = $AUDIO x 58;   # 17 MiB
  cmp_ok length($big), '>', 16_777_216, 'the upload is above the server\'s 16 MiB';
  cmp_ok length($big), '<', 26_214_400, 'and below the 25 MiB default';
  upload($t, $T, field(model => 'whisper'), file_part($big));
  $t->status_is(200)->json_is('/text' => 'big');
  is $got->{size}, length($big), 'the node received all of it';
  is $got->{sha}, sha1_hex($big), 'unchanged';
  paired($skeid, 'big', '17 MiB upload');
  $daemon->stop;
};

subtest 'client_auth answers 401 before anything is read or forwarded' => sub {
  my ($t, $skeid) = proxy(config => { client_auth => { keys => [$ALICE_ID] } });
  add_node($skeid, 'gpu-1', 'vllm');

  for my $path ($T, $TL) {
    upload($t, $path, field(model => 'whisper'), file_part($SMALL));
    $t->status_is(401, "$path without a key: 401")
      ->header_is('WWW-Authenticate' => 'Bearer realm="skeid"')
      ->json_is('/error/type' => 'invalid_request_error')
      ->json_is('/error/code' => 'invalid_api_key')
      ->json_is('/error/message' => 'Missing API key');
    upload($t, $path, { Authorization => 'Bearer sk-mallory' }, field(model => 'whisper'), file_part($AUDIO));
    $t->status_is(401, "$path with an unknown key: 401")->json_is('/error/message' => 'Invalid API key');
  }
  is scalar(@UPSTREAM), 0, 'nothing forwarded';
  is scalar(@USAGE), 0, 'nothing metered';
  is $skeid->node_metrics('gpu-1')->{started}, 0, 'no request.start';

  # A refused caller's upload is not received: the 401 is there while the body is outstanding.
  my $client = raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE, 'Content-Length' => 5_000_000,
    Authorization => 'Bearer sk-mallory') . "--$BOUNDARY\r\n");
  ok run_until(sub { $client->{buffer} =~ m{\r\n\r\n.*\}}s }), 'answered with the body still outstanding';
  like $client->{buffer}, qr{\AHTTP/1\.1 401 }, 'with 401';
  like $client->{buffer}, qr/Invalid API key/, 'the gate\'s own answer';
  ok run_until(sub { $client->{closed} }), 'and the connection is closed';

  upload($t, $T, { Authorization => "Bearer $ALICE_KEY" }, field(model => 'whisper'), file_part($AUDIO));
  $t->status_is(200, 'a listed key gets in')->json_is('/text' => $TEXT);
  is $UPSTREAM[0]{file_sha}, $AUDIO_SHA, 'with its upload intact';
  is $USAGE[0]{api_key_id}, $ALICE_ID, 'metered on its key id';
  is scalar(@UPSTREAM), 1, 'one request forwarded in all';
};

subtest 'the node\'s key replaces the client\'s; a node whose key is missing is not called' => sub {
  local $ENV{SKEID_K91_NODE_KEY} = 'node-secret-key';
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', api_key_env => 'SKEID_K91_NODE_KEY');
  upload($t, $T, { Authorization => "Bearer $ALICE_KEY", 'X-Api-Key' => $ALICE_KEY },
    field(model => 'whisper'), file_part($SMALL));
  $t->status_is(200);
  is $UPSTREAM[0]{authorization}, 'Bearer node-secret-key', 'the node gets its own key';
  is $UPSTREAM[0]{x_api_key}, undef, 'and none of the client\'s credentials';

  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'gpu-1', 'vllm', api_key_env => 'SKEID_K91_UNSET_KEY');
  for my $stream ('false', 'true') {
    upload($t2, $T, { Authorization => "Bearer $ALICE_KEY" }, field(model => 'whisper'),
      file_part($SMALL), field(stream => $stream));
    $t2->status_is(503, "stream=$stream: an unkeyed node answers 503")
      ->json_is('/error/type' => 'upstream_key_unavailable');
    is $USAGE[-1]{ok}, 0, "stream=$stream: one failed event";
    is $USAGE[-1]{error_type}, 'upstream_key_unavailable', "stream=$stream: naming the cause";
    is $USAGE[-1]{endpoint}, $T, "stream=$stream: on the audio endpoint";
  }
  is scalar(@UPSTREAM), 0, 'the node was never called';
  is scalar(@USAGE), 2, 'one event per refused request';
  paired($skeid2, 'gpu-1', 'unkeyed node');
};

subtest 'an upstream error is one failed event and a free slot' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', max_conns => 1);

  $MODE = 'fail';
  upload($t, $T, field(model => 'whisper'), file_part($SMALL));
  $t->status_is(500)
    ->json_is('/error/type' => 'upstream_error', 'the error is in the OpenAI shape')
    ->json_like('/error/message' => qr/CUDA out of memory/, 'with the node\'s own message');
  is scalar(@USAGE), 1, 'one usage event';
  is $USAGE[0]{ok}, 0, 'failed';
  is $USAGE[0]{status_code}, 500, 'with the upstream status';
  is $USAGE[0]{error_type}, 'upstream_error', 'and the cause';
  is $USAGE[0]{endpoint}, $T, 'on the audio endpoint';
  ok !exists($USAGE[0]{audio_seconds}), 'and no audio_seconds';
  paired($skeid, 'gpu-1', 'upstream 500');

  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'));
  $t->status_is(500, 'a stream the node refuses keeps the node\'s status');
  is scalar(@USAGE), 2, 'one usage event for the refused stream';
  is $USAGE[1]{ok}, 0, 'failed';
  is $USAGE[1]{status_code}, 500, 'with the upstream status';
  paired($skeid, 'gpu-1', 'refused stream');

  $MODE = 'cut';
  upload($t, $T, field(model => 'whisper'), file_part($SMALL), field(stream => 'true'));
  is scalar(@USAGE), 3, 'one usage event for the cut stream';
  is $USAGE[2]{ok}, 0, 'a stream cut short of its framing failed';
  is $USAGE[2]{content_bytes}, length(Encode::encode_utf8($PIECES[0])), 'what it relayed is counted';
  paired($skeid, 'gpu-1', 'cut stream');

  # A node that is gone: connection refused.
  $MODE = '';
  my ($t2, $skeid2) = proxy();
  my $dead = Mojo::IOLoop::Server->generate_port;
  $skeid2->add_node(id => 'dead', url => "http://127.0.0.1:$dead/v1", model => 'whisper', max_conns => 1);
  upload($t2, $T, field(model => 'whisper'), file_part($AUDIO));
  $t2->status_is(502)->json_is('/error/type' => 'upstream_error');
  is scalar(@USAGE), 1, 'one usage event for the unreachable node';
  is $USAGE[0]{ok}, 0, 'failed';
  paired($skeid2, 'dead', 'unreachable node');
};

subtest 'a client that hangs up frees the slot and leaves one failed event' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', max_conns => 1);
  $MODE = 'hold';

  for my $stream ('false', 'true') {
    my $events = scalar @USAGE;
    my $calls  = scalar @UPSTREAM;
    my $body = form(field(model => 'whisper'), file_part($AUDIO), field(stream => $stream));
    my $client = raw_client($t, request_head($T, 'Content-Type' => $FORM_TYPE,
      'Content-Length' => length($body)) . $body);
    ok run_until(sub { @UPSTREAM == $calls + 1 }), "stream=$stream: the request reached the node";
    my $seen = $UPSTREAM[-1];
    is $seen->{file_sha}, $AUDIO_SHA, "stream=$stream: with the upload";
    is inflight($skeid, 'gpu-1'), 1, "stream=$stream: the slot is taken";
    ok run_until(sub { $client->{buffer} =~ /transcript\.text\.delta/ }), 'the first frame reached the client'
      if $stream eq 'true';

    $client->{stream}->close;
    ok run_until(sub { $seen->{hung_up} }), "stream=$stream: the node saw its connection close";
    ok run_until(sub { !inflight($skeid, 'gpu-1') }), "stream=$stream: the slot is free";
    settle();
    is scalar(@USAGE) - $events, 1, "stream=$stream: one usage event";
    my $ev = $USAGE[-1];
    is $ev->{ok}, 0, "stream=$stream: failed";
    is $ev->{error_type}, 'client_abort', "stream=$stream: client_abort";
    is $ev->{status_code}, 499, "stream=$stream: 499";
    is $ev->{endpoint}, $T, "stream=$stream: on the audio endpoint";
    paired($skeid, 'gpu-1', "stream=$stream abort");
  }
  is $skeid->node_metrics('gpu-1')->{aborted}, 2, 'both requests counted as aborted';
};

subtest 'an Expect: 100-continue is not passed on to the node' => sub {
  # curl sends one with every upload above 1 MiB. Skeid has the body before it calls the node,
  # and a node answering the header with 100 Continue would derail the stream relay.
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');
  for my $stream ('false', 'true') {
    upload($t, $T, { Expect => '100-continue' }, field(model => 'whisper'), file_part($SMALL),
      field(stream => $stream));
    $t->status_is(200);
    is $UPSTREAM[-1]{expect}, undef, "stream=$stream: the node sees no Expect header";
  }
  is $t->tx->res->body, vllm_stream('transcriptions', 0), 'and the stream is relayed whole';
};

subtest 'no spooled upload outlives its request' => sub {
  # Every request above is over: answered, refused, failed or abandoned. An upload still on disk
  # now would be one something kept a reference to.
  undef $UP;
  @UPSTREAM = ();
  settle(0.1);
  ok run_until(sub { !$SPOOL->children }, 2), 'the spool directory is empty'
    or diag join("\n", map { "$_ (" . (-s $_) . ' bytes)' } $SPOOL->children);
};

subtest 'Protocol::Audio: what an answer reports, and what it does not' => sub {
  my $audio = 'Langertha::Skeid::Protocol::Audio';
  is_deeply [ $audio->routes ], [ $T, $TL ], 'the two client routes';
  is $audio->upstream_path($T), '/audio/transcriptions', 'transcriptions upstream path';
  is $audio->upstream_path($TL), '/audio/translations', 'translations upstream path';
  is $audio->upstream_path('/v1/chat/completions'), undef, 'no other route is an audio route';

  is_deeply [ $audio->usage_units({ usage => { type => 'duration', seconds => 12 } }) ],
    [ audio_seconds => 12 ], 'usage.seconds of a duration block';
  is_deeply [ $audio->usage_units({ duration => 7.25, text => 'x' }) ],
    [ audio_seconds => 7.25 ], 'the top-level duration of verbose_json';
  is_deeply [ $audio->usage_units({ duration => '8.5' }) ], [ audio_seconds => 8.5 ],
    'a duration sent as a numeric string';
  is_deeply [ $audio->usage_units({ usage => { type => 'duration', seconds => 3 }, duration => 9 }) ],
    [ audio_seconds => 3 ], 'the usage block comes before the duration';
  is_deeply [ $audio->usage_units({ usage => { type => 'duration', seconds => 0 } }) ],
    [ audio_seconds => 0 ], 'a reported zero is a measurement';
  is_deeply [ $audio->usage_units({ usage => { type => 'tokens', total_tokens => 5 }, duration => 4 }) ],
    [ audio_seconds => 4 ], 'token usage beside a duration leaves the duration';
  my @silent = (
    {}, { text => 'x' }, { usage => undef }, { usage => { type => 'tokens', seconds => 5 } },
    { usage => { type => 'duration' } }, { usage => { type => 'duration', seconds => 'long' } },
    { duration => 'long' }, { duration => -1 }, { duration => 'nan' }, { duration => 'inf' },
    { duration => [1] }, { duration => undef }, 'plain text', undef, [],
  );
  is_deeply [ $audio->usage_units($_) ], [], 'nothing reported, nothing returned: ' . $JSON->allow_nonref->encode($_)
    for @silent;

  is $audio->delta_text({ type => 'transcript.text.delta', delta => 'Köln' }), 'Köln', 'the text of a delta frame';
  is $audio->delta_text($_), undef, 'no text in ' . $JSON->encode($_)
    for { type => 'transcript.text.done', text => 'x' }, { type => 'transcript.text.delta' },
      { type => 'transcript.text.delta', delta => { a => 1 } }, { choices => [{ delta => { content => 'x' } }] };

  ok $audio->is_true($_), "<$_> is true" for qw( 1 true TRUE True on ON yes t y Y );
  ok !$audio->is_true($_), '<' . ($_ // 'undef') . '> is not' for 'false', '0', 'no', 'off', '', ' true', '2', undef;
};

# --- the usage event field through the stores -------------------------------------------------

my @AUDIO_EVENTS = (
  { api_key_id => 'k_alice', model => 'whisper', endpoint => $T, audio_seconds => 12 },
  { api_key_id => 'k_alice', model => 'whisper', endpoint => $T, audio_seconds => 7.25 },
  { api_key_id => 'k_bob',   model => 'whisper', endpoint => $TL },
  { api_key_id => 'k_bob',   model => 'chat',    endpoint => '/v1/chat/completions',
    metrics => { usage => { input => 10, output => 5, total => 15 } } },
);

sub record_events {
  my ($skeid, @events) = @_;
  for my $event (@events) {
    my $res = $skeid->call_function('usage.record', {
      api_format => 'openai', status_code => 200, ok => 1, %$event,
    });
    ok $res->{ok}, 'event recorded' or diag explain $res;
  }
}

sub check_report {
  my ($label, $report) = @_;
  ok $report->{ok}, "$label: report" or diag explain $report;
  is $report->{totals}{requests}, 4, "$label: four events";
  is $report->{totals}{audio_seconds}, 19.25, "$label: totals sum audio_seconds";
  is $report->{totals}{total_tokens}, 15, "$label: tokens are counted beside it";
  my %by_key = map { $_->{api_key_id} => $_ } @{ $report->{by_key} };
  is $by_key{k_alice}{audio_seconds}, 19.25, "$label: by key, the key that had audio";
  is $by_key{k_bob}{audio_seconds}, 0, "$label: by key, events that carry none add nothing";
  my %by_model = map { $_->{model} => $_ } @{ $report->{by_model} };
  is $by_model{whisper}{audio_seconds}, 19.25, "$label: by model";
  is $by_model{chat}{audio_seconds}, 0, "$label: by model, a chat model has none";
}

subtest 'record_usage carries audio_seconds only when given' => sub {
  my @events;
  my $skeid = Langertha::Skeid->new(store_usage_event => sub { push @events, $_[1]; return { ok => 1 } });
  record_events($skeid, @AUDIO_EVENTS[ 0, 2 ], { %{ $AUDIO_EVENTS[0] }, audio_seconds => 0 });
  is $events[0]{audio_seconds}, 12, 'a reported duration is kept';
  ok !exists($events[1]{audio_seconds}), 'an event without one has no such key';
  ok exists($events[2]{audio_seconds}) && $events[2]{audio_seconds} == 0,
    'a reported zero is a measurement and is kept as one';
};

subtest 'jsonlog writes audio_seconds and reports it' => sub {
  my $dir = "$TMP/jsonlog";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  record_events($skeid, @AUDIO_EVENTS);
  my @lines = map { decode_json($_) } map { path($_)->lines_utf8 } grep { -f } path($dir)->children;
  is scalar(@lines), 4, 'four events on disk';
  is_deeply [ sort { $a <=> $b } map { $_->{audio_seconds} } grep { exists $_->{audio_seconds} } @lines ],
    [ 7.25, 12 ], 'the two events that had a duration carry it';
  is scalar(grep { !exists $_->{audio_seconds} } @lines), 2, 'the other two have no such key';
  check_report('jsonlog', $skeid->call_function('usage.report', {}));
};

subtest 'the DBI store keeps audio_seconds in a nullable column' => sub {
  eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

  my $db = "$TMP/usage.sqlite";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  record_events($skeid, @AUDIO_EVENTS);
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  is_deeply $dbh->selectcol_arrayref('SELECT audio_seconds FROM usage_events ORDER BY id'),
    [ 12, 7.25, undef, undef ], 'a duration is stored, an event without one is NULL, not zero';
  $dbh->disconnect;
  check_report('sqlite', $skeid->call_function('usage.report', {}));

  # A table from before the column existed gains it on prepare, once, and its old rows read
  # as not measured.
  my $old = "$TMP/old.sqlite";
  my $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  $odbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, requested_model TEXT,
      node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
      duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0, total_tokens INTEGER NOT NULL DEFAULT 0,
      cached_tokens INTEGER, cache_write_tokens INTEGER, content_bytes INTEGER,
      tool_calls INTEGER NOT NULL DEFAULT 0, cost_input_usd REAL NOT NULL DEFAULT 0,
      cost_output_usd REAL NOT NULL DEFAULT 0, cost_total_usd REAL NOT NULL DEFAULT 0,
      cost_cache_read_usd REAL, cost_cache_write_usd REAL,
      error_type TEXT, error_message TEXT
    )
  });
  $odbh->do(q{INSERT INTO usage_events (created_at, api_key_id, model, ok, total_tokens)
    VALUES ('2026-09-01T00:00:00Z', 'k_old', 'chat', 1, 7)});
  $odbh->disconnect;

  my $upgraded = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  record_events($upgraded, $AUDIO_EVENTS[0]);
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  my @cols = grep { $_->{name} eq 'audio_seconds' }
    @{ $odbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} }) };
  is scalar(@cols), 1, 'the column is added to a table that predates it, and only once';
  ok !$cols[0]{notnull}, 'and it is nullable';
  is_deeply $odbh->selectcol_arrayref('SELECT audio_seconds FROM usage_events ORDER BY id'),
    [ undef, 12 ], 'the old row reads NULL, the new one its duration';
  $odbh->disconnect;
  my $report = $upgraded->call_function('usage.report', {});
  is $report->{totals}{audio_seconds}, 12, 'a report over old and new rows sums what there is';
  is $report->{totals}{requests}, 2, 'and counts both';
};

subtest 'a relayed request reaches the configured store with its audio_seconds' => sub {
  my $dir = "$TMP/proxy-jsonlog";
  my ($t, $skeid) = proxy(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  add_node($skeid, 'gpu-1', 'vllm');
  upload($t, $T, { Authorization => "Bearer $ALICE_KEY" }, field(model => 'whisper'), file_part($SMALL));
  $t->status_is(200);
  upload($t, $T, { Authorization => "Bearer $ALICE_KEY" }, field(model => 'whisper'), file_part($SMALL),
    field(response_format => 'text'));
  $t->status_is(200);
  my $report = $skeid->call_function('usage.report', {});
  is $report->{totals}{requests}, 2, 'two events in the store';
  is $report->{totals}{audio_seconds}, 12, 'the one with a duration counted';
  is $report->{by_key}[0]{api_key_id}, $ALICE_ID, 'under the caller\'s key id';
  is $report->{by_model}[0]{audio_seconds}, 12, 'and its model';
};

# --- skeid usage ------------------------------------------------------------------------------

my $BIN = path($FindBin::Bin)->parent->child('bin', 'skeid')->stringify;

sub run_skeid {
  my (@args) = @_;
  my $out = path($TMP)->child('out-' . $$ . '-' . int(rand(1e9)));
  local $ENV{PERL5LIB} = join(':', grep { !ref } @INC);
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    open STDOUT, '>', "$out" or die $!;
    open STDERR, '>&', \*STDOUT or die $!;
    chdir $TMP or die $!;
    exec $^X, '-w', $BIN, @args;
    die "exec: $!";
  }
  my $deadline = time + 20;
  my $code;
  while (time < $deadline) {
    if (waitpid($pid, WNOHANG) == $pid) { $code = $? >> 8; last }
    select(undef, undef, undef, 0.1);
  }
  unless (defined $code) {
    kill 'TERM', $pid;
    waitpid($pid, 0);
    $code = -1;
  }
  return ($code, (-f "$out" ? $out->slurp_utf8 : ''));
}

subtest 'skeid usage prints audio seconds only where there are some' => sub {
  # A store without audio events: the report is what it was before the field existed.
  my $plain = "$TMP/cli-plain";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $plain, mode => 'dir' });
  record_events($skeid, $AUDIO_EVENTS[3], $AUDIO_EVENTS[3]);
  my ($code, $output) = run_skeid('usage', '--log-path', $plain);
  is $code, 0, 'exits 0' or diag $output;
  my ($head) = $output =~ /\A(.*?\nRecent:\n)/s;
  is $head, <<"REPORT", 'the report of a store without audio events is unchanged';
Usage backend: jsonlog
Store: $plain
Since: (all)

Totals: requests=2 input=20 output=10 total=30 cached=0 cache_write=0 tools=0 cost=\$0.00000000

By API key:
  k_bob            requests=2 tokens=30 cost=\$0.00000000

By model:
  chat                     requests=2 tokens=30 cost=\$0.00000000

Recent:
REPORT
  unlike $output, qr/audio/i, 'and nowhere mentions audio';

  my $audio = "$TMP/cli-audio";
  $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $audio, mode => 'dir' });
  record_events($skeid, @AUDIO_EVENTS);
  ($code, $output) = run_skeid('usage', '--log-path', $audio);
  is $code, 0, 'exits 0 with audio events' or diag $output;
  unlike $output, qr/isn't numeric|uninitialized/, 'no warnings';
  like $output, qr/^Totals: requests=4 .*\nAudio:  seconds=19\.25\n/m, 'an Audio line follows the totals';
  like $output, qr/^  k_alice +requests=2 tokens=0 cost=\$0\.00000000 audio_seconds=19\.25$/m,
    'the key with audio ends in its seconds';
  like $output, qr/^  k_bob +requests=2 tokens=15 cost=\$0\.00000000$/m, 'a key without is printed as ever';
  like $output, qr/^  whisper +requests=3 tokens=0 cost=\$0\.00000000 audio_seconds=19\.25$/m, 'by model likewise';
  like $output, qr/^  chat +requests=1 tokens=15 cost=\$0\.00000000$/m, 'a model without is printed as ever';

  ($code, $output) = run_skeid('usage', '--log-path', $audio, '--json');
  is $code, 0, '--json exits 0';
  is decode_json(Encode::encode_utf8($output))->{totals}{audio_seconds}, 19.25, '--json carries the sum';
};

done_testing;
