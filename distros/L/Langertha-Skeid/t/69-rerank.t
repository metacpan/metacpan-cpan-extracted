use strict;
use warnings;
use utf8;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::JSON ();
use Encode ();
use File::Temp qw( tempdir );
use FindBin;
use JSON::MaybeXS qw( decode_json );
use Path::Tiny qw( path );
use POSIX qw( WNOHANG );
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Protocol::Rerank;
use Langertha::Skeid::Proxy;

# The rerank route (skeid k92, ADR 0021): POST /v1/rerank and its alias POST /rerank. A JSON body
# in the shape Cohere, vLLM, Jina and infinity share comes in behind the client gate and is
# routed by its model like a chat request. To a node that speaks that shape it is relayed -- only
# `model` is replaced, the answer comes back byte for byte. A node marked `rerank_format: tei`
# (Hugging Face text-embeddings-inference) is translated in both directions. The usage event
# counts the documents itself and takes the tokens from wherever that node reports them, as
# input tokens. The upstreams here are local fakes of those dialects: vLLM, infinity, Cohere,
# a node that reports only total_tokens (Jina, older vLLM), one that reports nothing, and TEI.

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER SKEID_K92_NODE_KEY SKEID_K92_UNSET_KEY SKEID_USAGE_DB )};

my $TMP = tempdir(CLEANUP => 1);

my $ALICE_KEY = 'sk-alice-secret';
my $ALICE_ID  = Langertha::Skeid->key_id_for_key($ALICE_KEY);

my $R  = '/v1/rerank';
my $RA = '/rerank';

# Three documents whose scores are not in document order, so an answer in score order differs
# from one in document order: index 1, then 2, then 0.
my @DOCS  = ('Köln liegt am Rhein', 'Berlin ist die Hauptstadt', 'Paris is in France');
my %SCORE = ($DOCS[0] => 0.12, $DOCS[1] => 0.93, $DOCS[2] => 0.61);
my $QUERY = 'Was ist die Hauptstadt von Deutschland?';

# What each fake reports as its token count, and where.
my %TOKENS = (vllm => 17, infinity => 61, cohere => 23, total => 29, tei => 41);

my (@UPSTREAM, @USAGE, @LOG);
# What the fake upstream does instead of answering: 'fail' (an error in its own dialect),
# 'hold' (answers when told), 'object' (a TEI node answering something that is no array).
my $MODE = '';
# Whether the TEI fake sends its x-compute-tokens header.
my $TEI_HEADER = 1;
my $CFG = {};

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
sub j { return $JSON->encode($_[0]) }

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

# The results of a node that speaks the client's shape: scored, highest first, cut to top_n.
# $document turns a text into what that node calls a document, or into nothing.
sub ranked {
  my ($body, $document) = @_;
  my @texts = map { ref($_) eq 'HASH' ? $_->{text} : $_ } @{ $body->{documents} };
  my @rows = sort { $b->{relevance_score} <=> $a->{relevance_score} }
    map { { index => $_, relevance_score => ($SCORE{ $texts[$_] // '' } // 0), $document->($texts[$_]) } } 0 .. $#texts;
  splice(@rows, $body->{top_n}) if $body->{top_n} && $body->{top_n} < @rows;
  return \@rows;
}

# The answer of one dialect as the bytes it sends. Written out by hand, with spaces a JSON
# encoder would not put there and a trailing newline, so an answer Skeid decoded and encoded
# again is not the answer the node gave.
sub answer_bytes {
  my ($flavour, $body) = @_;
  my $model = j($body->{model});
  if ($flavour eq 'vllm') {
    # Always returns the documents, whatever return_documents says.
    my $results = ranked($body, sub { (document => { text => $_[0], multi_modal => undef }) });
    return qq[{ "id": "rerank-7c1", "model": $model, "usage": { "prompt_tokens": $TOKENS{vllm}, "total_tokens": $TOKENS{vllm} },]
      . ' "results": ' . j($results) . " }\n";
  }
  if ($flavour eq 'infinity') {
    # A document is a plain string here, and only there when asked for. The usage counts
    # characters unless the server tokenizes; Skeid records what it says.
    my $with = $body->{return_documents} ? 1 : 0;
    my $results = ranked($body, sub { $with ? (document => $_[0]) : () });
    return qq[{ "object": "rerank", "results": ] . j($results)
      . qq[, "model": $model, "usage": { "prompt_tokens": $TOKENS{infinity}, "total_tokens": $TOKENS{infinity} },]
      . qq[ "id": "infinity-4f", "created": 1790000000 }\n];
  }
  if ($flavour eq 'cohere') {
    my $with = $body->{return_documents} ? 1 : 0;
    my $results = ranked($body, sub { $with ? (document => { text => $_[0] }) : () });
    return qq[{ "id": "c0de", "results": ] . j($results)
      . qq[, "meta": { "api_version": { "version": "1" }, "billed_units": { "search_units": 1 },]
      . qq[ "tokens": { "input_tokens": $TOKENS{cohere}, "output_tokens": 0 } } }\n];
  }
  my $results = ranked($body, sub { () });
  # Jina and older vLLM: only a total.
  return qq[{ "model": $model, "usage": { "total_tokens": $TOKENS{total} }, "results": ] . j($results) . " }\n"
    if $flavour eq 'total';
  # A node that reports no tokens at all.
  return qq[{ "results": ] . j($results) . " }\n";
}

sub remember {
  my ($c, %more) = @_;
  my $req = $c->req;
  my $seen = {
    flavour       => $c->stash('flavour'),
    tag           => $c->stash('tag'),
    path          => $req->url->path->to_string,
    raw           => $req->body,
    json          => scalar(eval { decode_json($req->body) }),
    content_type  => $req->headers->content_type,
    authorization => $req->headers->authorization,
    x_api_key     => $req->headers->header('x-api-key'),
    answered      => 0,
    hung_up       => 0,
    %more,
  };
  push @UPSTREAM, $seen;
  $c->on(finish => sub { $seen->{hung_up} = 1 unless $seen->{answered}; delete $seen->{answer} });
  return $seen;
}

sub hold {
  my ($c, $seen, $answer) = @_;
  $c->render_later;
  Mojo::IOLoop->stream($c->tx->connection)->timeout(0);
  $seen->{answer} = sub { $seen->{answered} = 1; $answer->() };
  return;
}

# A node that speaks the client's shape, at {node url}/rerank below /v1.
sub fake_upstream {
  my ($c) = @_;
  # A TEI server has no such route.
  return $c->render(status => 404, text => 'Not Found') if $c->stash('flavour') eq 'tei';
  my $seen = remember($c);
  my $send = sub {
    $seen->{sent} = answer_bytes($seen->{flavour}, $seen->{json});
    $c->res->headers->header('x-node-header' => 'kept');
    $c->render(data => $seen->{sent}, format => 'json');
  };
  return hold($c, $seen, $send) if $MODE eq 'hold';
  $seen->{answered} = 1;
  return $c->render(status => 500,
    json => { error => { message => 'CUDA out of memory', type => 'server_error' } }) if $MODE eq 'fail';
  return $send->();
}

# Hugging Face text-embeddings-inference: POST /rerank at the server root, { query, texts },
# answering a bare array in document order with its token count in a header.
sub fake_tei {
  my ($c) = @_;
  my $seen = remember($c, flavour => 'tei');
  my $body = $seen->{json};
  $seen->{answered} = 1;
  return $c->render(status => 413,
    json => { error => 'batch size 3 > maximum allowed batch size 2', error_type => 'Validation' })
    if $MODE eq 'fail';
  return $c->render(json => { unexpected => Mojo::JSON->true }) if $MODE eq 'object';
  return $c->render(status => 422, json => { error => 'missing field `texts`', error_type => 'Validation' })
    unless ref($body) eq 'HASH' && ref($body->{texts}) eq 'ARRAY';
  my @texts = @{ $body->{texts} };
  $c->res->headers->header('x-compute-tokens' => $TOKENS{tei}) if $TEI_HEADER;
  return $c->render(json => [ map { {
    index => $_, score => ($SCORE{ $texts[$_] } // 0),
    ($body->{return_text} ? (text => $texts[$_]) : ()),
  } } 0 .. $#texts ]);
}

# A proxy over a Skeid whose config comes from $CFG (so a test changes it live), with the fake
# upstreams mounted on the same app, outside the client routes.
my $UP;
sub proxy {
  my (%opts) = @_;
  $CFG = delete($opts{config}) || {};
  @UPSTREAM = @USAGE = @LOG = ();
  $MODE = '';
  $TEI_HEADER = 1;
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
  $app->routes->post('/__up/tei/:tag/rerank' => \&fake_tei);
  $app->routes->post('/__up/:flavour/:tag/v1/rerank' => \&fake_upstream);
  my $t = Test::Mojo->new($app);
  $UP = $t->ua->server->nb_url->clone;
  return ($t, $skeid);
}

sub node_url { my ($flavour, $tag, $v1) = @_; return $UP->clone->path("/__up/$flavour/$tag" . ($v1 // '/v1'))->to_string }

sub add_node {
  my ($skeid, $id, $flavour, %extra) = @_;
  return $skeid->add_node(
    id => $id, url => node_url($flavour, $id), model => 'bge-reranker', engine => 'openai',
    max_conns => 4, %extra,
  );
}

sub add_tei {
  my ($skeid, $id, %extra) = @_;
  my $v1 = exists $extra{v1} ? delete $extra{v1} : '/v1';
  return $skeid->add_node(
    id => $id, url => node_url('tei', $id, $v1), model => 'bge-reranker',
    max_conns => 4, rerank_format => 'tei', %extra,
  );
}

sub request { return { model => 'bge-reranker', query => $QUERY, documents => [@DOCS], @_ } }

sub rerank {
  my ($t, $path, $body, $headers) = @_;
  return $t->post_ok($path => ($headers || {}) => json => $body);
}

sub inflight { my ($skeid, $id) = @_; return $skeid->node_metrics($id)->{inflight} }

sub paired {
  my ($skeid, $id, $label) = @_;
  my $m = $skeid->node_metrics($id);
  is $m->{inflight}, 0, "$label: nothing in flight on $id";
  is $m->{ok} + $m->{error} + $m->{aborted} + $m->{rejected}, $m->{started},
    "$label: every request.start on $id has its request.finish";
  return $m;
}

# A raw connection: it can hang up in the middle of a request, which a well-behaved user agent
# does not do.
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

sub raw_request {
  my ($path, $body) = @_;
  my $bytes = j($body);
  return join("\r\n", "POST $path HTTP/1.1", 'Host: 127.0.0.1', 'Content-Type: application/json',
    'Content-Length: ' . length($bytes), '', '') . $bytes;
}

subtest 'both spellings are one route' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');

  my @answers;
  for my $path ($R, $RA) {
    rerank($t, $path, request(), { Authorization => "Bearer $ALICE_KEY" });
    $t->status_is(200, "$path answers")
      ->json_is('/results/0/index' => 1, "$path: the best document first")
      ->json_is('/results/2/index' => 0, "$path: the worst last")
      ->header_is('x-skeid-node' => 'gpu-1');
    push @answers, $t->tx->res->body;
  }
  is $answers[0], $answers[1], 'the same answer on both';
  is scalar(@UPSTREAM), 2, 'two requests forwarded';
  is $UPSTREAM[0]{path}, '/__up/vllm/gpu-1/v1/rerank', "$R goes to {node url}/rerank";
  is $UPSTREAM[1]{path}, $UPSTREAM[0]{path}, "$RA goes to the same upstream path";
  is $UPSTREAM[1]{raw}, $UPSTREAM[0]{raw}, 'with the same body';

  is scalar(@USAGE), 2, 'one usage event each';
  for my $i (0, 1) {
    my $ev = $USAGE[$i];
    is $ev->{endpoint}, '/v1/rerank', "event $i: the endpoint is /v1/rerank whichever spelling was used";
    is $ev->{api_format}, 'openai', "event $i: on the OpenAI face";
    is $ev->{api_key_id}, $ALICE_ID, "event $i: on the caller's key id";
    is $ev->{ok}, 1, "event $i: ok";
    is $ev->{status_code}, 200, "event $i: 200";
    is $ev->{node_id}, 'gpu-1', "event $i: the node";
    is $ev->{documents}, 3, "event $i: three documents";
    ok !exists($ev->{audio_seconds}), "event $i: and no unit of another route";
  }
  paired($skeid, 'gpu-1', 'both spellings');
};

subtest 'the body goes upstream as sent, the answer comes back byte for byte' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');
  add_node($skeid, 'inf-1', 'infinity', model => 'infinity-reranker');

  # Fields Skeid knows nothing of, in every JSON type, and documents that are objects.
  my $body = {
    model => 'bge-reranker', query => $QUERY,
    documents => [ $DOCS[0], { text => $DOCS[1], title => 'Hauptstädte', meta => { page => 7 } }, $DOCS[2] ],
    top_n => 2, return_documents => Mojo::JSON->false, rank_fields => [ 'text', 'title' ],
    max_tokens_per_doc => 512, truncate_prompt_tokens => undef, raw_scores => Mojo::JSON->true,
    temperature => 0.25, user => 'ünïcode',
  };
  # Sent in the encoding the proxy's own encoder writes: nothing in it may move, so the node
  # gets the very bytes the client sent.
  my $sent = Mojo::JSON::encode_json($body);
  $t->post_ok($R => { 'Content-Type' => 'application/json' } => $sent)->status_is(200);
  my $seen = $UPSTREAM[0];
  is $seen->{raw}, $sent, 'the node gets the body byte for byte';
  is_deeply $seen->{json}, decode_json($sent), 'every field as sent, the unknown ones included';
  like $seen->{content_type}, qr{\Aapplication/json}, 'as JSON';
  is $t->tx->res->body, $seen->{sent}, 'the answer is the node\'s, byte for byte';
  unlike $t->tx->res->body, qr/\A\{"/, 'which a re-encoded answer would not be';
  is $t->tx->res->headers->header('x-node-header'), 'kept', 'with the node\'s headers';
  like $t->tx->res->headers->content_type, qr{\Aapplication/json}, 'and its content type';
  is scalar(@{ $t->tx->res->json->{results} }), 2, 'top_n is the node\'s to apply';
  ok exists($t->tx->res->json->{results}[0]{document}{multi_modal}),
    'vLLM returns the documents although not asked: left as it is';

  # A body written by hand: its layout is not kept, its content is.
  my $handwritten = qq[{\n  "query" : "$QUERY",\n  "documents" : [ "a", "b" ],\n  "model" : "bge-reranker",\n  "top_n" : 1\n}];
  $t->post_ok($R => { 'Content-Type' => 'application/json' } => Encode::encode_utf8($handwritten))->status_is(200);
  is_deeply $UPSTREAM[1]{json},
    { query => $QUERY, documents => [ 'a', 'b' ], model => 'bge-reranker', top_n => 1 },
    'a body in another layout arrives with the same content';
  is scalar(() = $UPSTREAM[1]{raw} =~ /"model"/g), 1, 'and one model field';
  is $USAGE[1]{documents}, 2, 'two documents counted';

  # infinity: a document is a plain string, returned only when asked for. Not normalised.
  rerank($t, $R, request(model => 'infinity-reranker', return_documents => Mojo::JSON->true));
  $t->status_is(200)->json_is('/results/0/document' => $DOCS[1], 'infinity\'s document stays a plain string')
    ->json_is('/object' => 'rerank');
  is $t->tx->res->body, $UPSTREAM[2]{sent}, 'infinity\'s answer byte for byte';
  rerank($t, $R, request(model => 'infinity-reranker'));
  $t->status_is(200);
  ok !exists($t->tx->res->json->{results}[0]{document}), 'and no document where none was asked for';
  paired($skeid, $_, 'relay') for qw( gpu-1 inf-1 );
};

subtest 'an alias tier rewrites model and nothing else' => sub {
  my ($t, $skeid) = proxy(config => {
    aliases => { 'house-rerank' => { tiers => [ { model => 'bge-reranker' } ] } },
  });
  add_node($skeid, 'gpu-1', 'vllm');

  my $body = request(model => 'house-rerank', top_n => 2, rank_fields => ['text']);
  rerank($t, $RA, $body);
  $t->status_is(200)->json_is('/model' => 'bge-reranker');
  is $UPSTREAM[0]{json}{model}, 'bge-reranker', 'the node is asked for the served model';
  is_deeply $UPSTREAM[0]{json}, { %$body, model => 'bge-reranker' }, 'and for nothing else that changed';
  is $USAGE[0]{model}, 'bge-reranker', 'event model is the served one';
  is $USAGE[0]{requested_model}, 'house-rerank', 'event requested_model is what the client asked for';
  is $USAGE[0]{documents}, 3, 'with its documents';
};

subtest 'tokens are input tokens wherever the node reports them, and are priced' => sub {
  my ($t, $skeid) = proxy(config => {
    pricing => { 'bge-reranker' => { input_per_million => 2, output_per_million => 50 } },
  });
  my @flavours = qw( vllm infinity cohere total bare );
  # One node per dialect, each the only one of its tag, reached through an alias.
  for my $flavour (@flavours) {
    add_node($skeid, "n-$flavour", $flavour, tags => [$flavour]);
    $skeid->set_model_alias("rerank-$flavour", { tiers => [ { tags => [$flavour], model => 'bge-reranker' } ] });
  }

  my %where = (
    vllm     => 'usage.prompt_tokens',
    infinity => 'usage.prompt_tokens (characters, as infinity counts)',
    cohere   => 'meta.tokens.input_tokens',
    total    => 'usage.total_tokens alone',
  );
  for my $flavour (@flavours) {
    rerank($t, $R, request(model => "rerank-$flavour"));
    $t->status_is(200, "$flavour answers");
    my $ev = $USAGE[-1];
    is $ev->{node_id}, "n-$flavour", "$flavour: its own node";
    is $ev->{documents}, 3, "$flavour: documents counted by Skeid, whatever the node reports";
    is $ev->{output_tokens}, 0, "$flavour: a reranker has no output tokens";
    if (my $tokens = $TOKENS{$flavour}) {
      is $ev->{input_tokens}, $tokens, "$flavour: $where{$flavour} is recorded as input tokens";
      is $ev->{total_tokens}, $tokens, "$flavour: and as the total";
      cmp_ok abs($ev->{cost_input_usd} - $tokens * 2 / 1e6), '<', 1e-12, "$flavour: priced at input_per_million";
      cmp_ok abs($ev->{cost_total_usd} - $tokens * 2 / 1e6), '<', 1e-12, "$flavour: which is the whole cost";
      is $ev->{cost_output_usd}, 0, "$flavour: nothing at the output rate";
    } else {
      is $ev->{input_tokens}, 0, "$flavour: a node that reports no tokens leaves none";
      is $ev->{total_tokens}, 0, "$flavour: no total";
      is $ev->{cost_total_usd}, 0, "$flavour: and no cost";
    }
  }
  is scalar(@USAGE), scalar(@flavours), 'one event per request';
};

subtest 'a body Skeid cannot route is 400 before any node is touched' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm');
  add_tei($skeid, 'tei-1', model => 'tei-reranker');

  my @bad = (
    [ 'not JSON'             => 'this is not json',                              qr/Invalid JSON body/ ],
    [ 'a JSON array'         => '["bge-reranker"]',                              qr/Invalid JSON body/ ],
    [ 'a JSON string'        => '"bge-reranker"',                                qr/Invalid JSON body/ ],
    [ 'no model'             => j({ query => 'q', documents => ['a'] }),         qr/'model'/ ],
    [ 'an empty model'       => j(request(model => '')),                         qr/'model'/ ],
    [ 'a null model'         => j(request(model => undef)),                      qr/'model'/ ],
    [ 'a model that is a list' => j(request(model => ['bge-reranker'])),         qr/'model'/ ],
    [ 'no query'             => j({ model => 'bge-reranker', documents => ['a'] }), qr/'query' must be a string/ ],
    [ 'a null query'         => j(request(query => undef)),                      qr/'query' must be a string/ ],
    [ 'a query that is a number' => '{"model":"bge-reranker","query":42,"documents":["a"]}', qr/'query' must be a string/ ],
    [ 'a query that is a list'   => j(request(query => ['q'])),                  qr/'query' must be a string/ ],
    [ 'a query that is an object' => j(request(query => { text => 'q' })),       qr/'query' must be a string/ ],
    [ 'no documents'         => j({ model => 'bge-reranker', query => 'q' }),    qr/'documents' must be a non-empty array/ ],
    [ 'no document in it'    => j(request(documents => [])),                     qr/'documents' must be a non-empty array/ ],
    [ 'documents as a string' => j(request(documents => 'a')),                   qr/'documents' must be a non-empty array/ ],
    [ 'documents as an object' => j(request(documents => { 0 => 'a' })),         qr/'documents' must be a non-empty array/ ],
  );
  for my $case (@bad) {
    my ($label, $bytes, $message) = @$case;
    for my $path ($R, $RA) {
      $t->post_ok($path => { 'Content-Type' => 'application/json' } => $bytes)
        ->status_is(400, "$label on $path: 400")
        ->json_is('/error/type' => 'invalid_request_error', "$label: in the OpenAI shape")
        ->json_like('/error/message' => $message, "$label: says what is wrong");
    }
  }
  # The same checks stand before a TEI node: they are the route's, not a dialect's.
  rerank($t, $R, request(model => 'tei-reranker', documents => []));
  $t->status_is(400)->json_like('/error/message' => qr/'documents'/);

  is scalar(@UPSTREAM), 0, 'nothing forwarded';
  is scalar(@USAGE), 0, 'nothing metered';
  for my $id (qw( gpu-1 tei-1 )) {
    is $skeid->node_metrics($id)->{started}, 0, "no request.start on $id";
    is inflight($skeid, $id), 0, "nothing in flight on $id";
  }

  # A string that looks like a number is a string, and an empty query is one too.
  rerank($t, $R, request(query => '42'));
  $t->status_is(200, 'a query "42" is a string');
  rerank($t, $R, request(query => ''));
  $t->status_is(200, 'an empty query is the node\'s to judge');
  is scalar(@UPSTREAM), 2, 'both were forwarded';
};

subtest 'a TEI node is translated in both directions' => sub {
  my ($t, $skeid) = proxy(config => {
    pricing => { 'bge-reranker' => { input_per_million => 2, output_per_million => 50 } },
  });
  add_tei($skeid, 'tei-1');

  # Documents as strings and as objects with a text; return_documents not sent.
  my $body = request(documents => [ $DOCS[0], { text => $DOCS[1], title => 'ignored' }, $DOCS[2] ],
    rank_fields => ['text'], max_tokens_per_doc => 512, user => 'someone');
  rerank($t, $R, $body, { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(200)->header_is('x-skeid-node' => 'tei-1');
  my $seen = $UPSTREAM[0];
  is $seen->{path}, '/__up/tei/tei-1/rerank', 'sent to /rerank at the server root, not below /v1';
  is_deeply $seen->{json}, { query => $QUERY, texts => [@DOCS] },
    'query and the documents as texts, and nothing else: no model, no top_n, no unknown field';
  like $seen->{content_type}, qr{\Aapplication/json}, 'as JSON';

  is_deeply $t->tx->res->json, {
    model   => 'bge-reranker',
    results => [
      { index => 1, relevance_score => 0.93 },
      { index => 2, relevance_score => 0.61 },
      { index => 0, relevance_score => 0.12 },
    ],
    usage => { total_tokens => $TOKENS{tei} },
  }, 'the bare array in document order becomes results in score order, with the header\'s tokens';
  like $t->tx->res->headers->content_type, qr{\Aapplication/json}, 'as JSON';

  my $ev = $USAGE[0];
  is $ev->{endpoint}, '/v1/rerank', 'event endpoint';
  is $ev->{api_format}, 'openai', 'event api_format';
  is $ev->{api_key_id}, $ALICE_ID, 'event key id';
  is $ev->{documents}, 3, 'event documents';
  is $ev->{input_tokens}, $TOKENS{tei}, 'x-compute-tokens is recorded as input tokens';
  is $ev->{output_tokens}, 0, 'no output tokens';
  is $ev->{total_tokens}, $TOKENS{tei}, 'and as the total';
  cmp_ok abs($ev->{cost_total_usd} - $TOKENS{tei} * 2 / 1e6), '<', 1e-12, 'priced at input_per_million';

  # return_documents on: asked of the node as return_text, answered as document { text }.
  rerank($t, $RA, request(return_documents => Mojo::JSON->true));
  $t->status_is(200);
  is_deeply $UPSTREAM[1]{json}, { query => $QUERY, texts => [@DOCS], return_text => Mojo::JSON->true },
    'return_documents goes as return_text';
  is $UPSTREAM[1]{path}, '/__up/tei/tei-1/rerank', "$RA goes the same way";
  is_deeply [ map { $_->{document} } @{ $t->tx->res->json->{results} } ],
    [ map { { text => $_ } } @DOCS[ 1, 2, 0 ] ], 'each result carries its document as { text }';
  is $USAGE[1]{endpoint}, '/v1/rerank', "$RA: the same event endpoint";

  # return_documents off: sent as false, no documents.
  rerank($t, $R, request(return_documents => Mojo::JSON->false));
  $t->status_is(200);
  is_deeply $UPSTREAM[2]{json}, { query => $QUERY, texts => [@DOCS], return_text => Mojo::JSON->false },
    'return_documents false goes as return_text false';
  ok !grep({ exists $_->{document} } @{ $t->tx->res->json->{results} }), 'and no result has a document';

  # truncate is TEI's own and passes when sent.
  rerank($t, $R, request(truncate => Mojo::JSON->true));
  $t->status_is(200);
  is_deeply $UPSTREAM[3]{json}, { query => $QUERY, texts => [@DOCS], truncate => Mojo::JSON->true },
    'truncate is passed when the client sent it';

  # top_n: TEI has none, Skeid cuts the sorted answer.
  rerank($t, $R, request(top_n => 2, return_documents => Mojo::JSON->true));
  $t->status_is(200);
  is_deeply $t->tx->res->json->{results}, [
    { index => 1, relevance_score => 0.93, document => { text => $DOCS[1] } },
    { index => 2, relevance_score => 0.61, document => { text => $DOCS[2] } },
  ], 'top_n keeps the best two';
  ok !exists($UPSTREAM[4]{json}{top_n}), 'and is not sent to the node';
  is $USAGE[4]{documents}, 3, 'the event counts the documents sent, not the results kept';
  for my $all (0, undef, 3, 99) {
    rerank($t, $R, request(top_n => $all));
    $t->status_is(200);
    is scalar(@{ $t->tx->res->json->{results} }), 3, 'top_n ' . ($all // 'null') . ': all three';
  }

  # No header, no tokens: neither in the answer nor on the event.
  $TEI_HEADER = 0;
  rerank($t, $R, request());
  $t->status_is(200);
  ok !exists($t->tx->res->json->{usage}), 'without x-compute-tokens the answer has no usage';
  is $USAGE[-1]{input_tokens}, 0, 'and the event no tokens';
  is $USAGE[-1]{documents}, 3, 'but its documents';
  is $USAGE[-1]{ok}, 1, 'and is ok';
  $TEI_HEADER = 1;

  is scalar(@USAGE), scalar(@UPSTREAM), 'one event per forwarded request';
  paired($skeid, 'tei-1', 'tei');
};

subtest 'a TEI node url is a base, with or without /v1' => sub {
  my ($t, $skeid) = proxy(config => {
    aliases => { 'house-rerank' => { tiers => [ { model => 'bge-reranker' } ] } },
  });
  for my $v1 ('', '/', '/v1', '/v1/') {
    $skeid->nodes([]);
    add_tei($skeid, 'tei-1', v1 => $v1);
    my $before = scalar @UPSTREAM;
    rerank($t, $R, request(model => 'house-rerank'));
    $t->status_is(200, "node url ending in '$v1'")
      ->json_is('/model' => 'bge-reranker', 'the answer names the served model');
    is scalar(@UPSTREAM), $before + 1, "'$v1': one upstream call";
    is $UPSTREAM[-1]{path}, '/__up/tei/tei-1/rerank', "'$v1': at the server root";
    is $USAGE[-1]{requested_model}, 'house-rerank', "'$v1': the event has the requested model";
    is $USAGE[-1]{model}, 'bge-reranker', "'$v1': and the served one";
  }
};

subtest 'what cannot be put to a TEI node is refused, with a slot given back' => sub {
  my ($t, $skeid) = proxy();
  add_tei($skeid, 'tei-1', max_conns => 1);

  my @unsendable = (
    [ 'a document without text' => request(documents => [ $DOCS[0], { image => 'aGk=' } ]), qr/documents\[1\] is not text/ ],
    [ 'a document whose text is no string' => request(documents => [ { text => ['x'] } ]),  qr/documents\[0\] is not text/ ],
    [ 'a document that is a list'   => request(documents => [ $DOCS[0], $DOCS[1], ['x'] ]), qr/documents\[2\] is not text/ ],
    [ 'a document that is null'     => request(documents => [undef]),                       qr/documents\[0\] is not text/ ],
    [ 'a top_n that is no count'    => request(top_n => -1),                                qr/'top_n'/ ],
    [ 'a fractional top_n'          => request(top_n => 1.5),                               qr/'top_n'/ ],
  );
  for my $case (@unsendable) {
    my ($label, $body, $message) = @$case;
    my $events = scalar @USAGE;
    rerank($t, $R, $body);
    $t->status_is(400, "$label: 400")
      ->json_is('/error/type' => 'invalid_request_error', "$label: in the OpenAI shape")
      ->json_like('/error/message' => $message, "$label: says which");
    is scalar(@USAGE) - $events, 1, "$label: one usage event";
    my $ev = $USAGE[-1];
    is $ev->{ok}, 0, "$label: failed";
    is $ev->{status_code}, 400, "$label: with 400";
    is $ev->{error_type}, 'invalid_request_error', "$label: and the cause";
    is $ev->{node_id}, 'tei-1', "$label: on the node that was admitted";
    is $ev->{endpoint}, '/v1/rerank', "$label: on the rerank endpoint";
    ok !exists($ev->{documents}), "$label: no documents on a request that was not answered";
    is inflight($skeid, 'tei-1'), 0, "$label: the slot is free";
  }
  is scalar(@UPSTREAM), 0, 'the node was never called';
  unlike $t->tx->res->body, qr/aGk=/, 'the refusal quotes nothing of the request';
  paired($skeid, 'tei-1', 'unsendable');

  # max_conns is 1: had a refusal kept its slot, this would wait and answer 429.
  rerank($t, $R, request());
  $t->status_is(200, 'the node still takes the next request');

  # The same documents are fine for a node that is relayed: what a document may be is the
  # node's to say.
  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'gpu-1', 'vllm');
  rerank($t2, $R, request(documents => [ $DOCS[0], { image => 'aGk=' } ], top_n => -1));
  $t2->status_is(200, 'a relayed node gets the request as it is');
  is_deeply $UPSTREAM[0]{json}{documents}[1], { image => 'aGk=' }, 'with its document';
  is $USAGE[0]{documents}, 2, 'and the event counts both';
};

subtest 'a TEI answer Skeid cannot translate, and a TEI error' => sub {
  my ($t, $skeid) = proxy();
  add_tei($skeid, 'tei-1', max_conns => 1);

  $MODE = 'object';
  rerank($t, $R, request());
  $t->status_is(500, 'an answer that is no array is a failed translation')
    ->json_is('/error/type' => 'api_error')
    ->json_is('/error/message' => 'Response translation failed');
  is scalar(@USAGE), 1, 'one usage event';
  is $USAGE[0]{ok}, 0, 'failed';
  is $USAGE[0]{status_code}, 500, 'with 500';
  is $USAGE[0]{error_type}, 'translation_error', 'as a translation error';
  ok !exists($USAGE[0]{documents}), 'and no documents';
  paired($skeid, 'tei-1', 'untranslatable answer');

  $MODE = 'fail';
  rerank($t, $R, request());
  $t->status_is(413, 'a TEI error keeps its status')
    ->json_is('/error/type' => 'upstream_error', 'in the OpenAI shape')
    ->json_like('/error/message' => qr/batch size 3 > maximum allowed batch size 2/, 'with TEI\'s own message');
  is scalar(@USAGE), 2, 'one usage event';
  is $USAGE[1]{ok}, 0, 'failed';
  is $USAGE[1]{status_code}, 413, 'with the upstream status';
  is $USAGE[1]{error_type}, 'upstream_error', 'and the cause';
  ok !exists($USAGE[1]{documents}), 'and no documents';
  paired($skeid, 'tei-1', 'tei error');

  $MODE = '';
  rerank($t, $R, request());
  $t->status_is(200, 'and the node is fine afterwards');
};

subtest 'rerank_format is kept by add_node and an unknown one is refused' => sub {
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'tei-1', url => 'http://tei:8080', model => 'bge', rerank_format => ' TEI ');
  $skeid->add_node(id => 'gpu-1', url => 'http://gpu:8000/v1', model => 'bge');
  $skeid->add_node(id => 'gpu-2', url => 'http://gpu:8000/v1', model => 'bge', rerank_format => '');
  my %node = map { $_->{id} => $_ } @{ $skeid->list_nodes };
  is $node{'tei-1'}{rerank_format}, 'tei', 'kept on the node, normalised';
  ok !exists($node{'gpu-1'}{rerank_format}), 'a node without one has no such field';
  ok !exists($node{'gpu-2'}{rerank_format}), 'nor has one that left it empty';
  is $skeid->call_function('nodes.list', {})->{nodes}[0]{rerank_format}, 'tei', 'shown by nodes.list';

  ok !eval { $skeid->add_node(id => 'tei-1', url => 'http://tei:8080', rerank_format => 'cohere'); 1 },
    'an unknown rerank_format croaks';
  like $@, qr/unknown rerank_format 'cohere' \(expected one of: tei\)/, 'naming the value and the known ones';
  is scalar(grep { $_->{id} eq 'tei-1' && ($_->{rerank_format} // '') eq 'tei' } @{ $skeid->list_nodes }), 1,
    'and the node it would have replaced is still there';

  # At config load: the load fails, as for an unknown engine.
  my $bad = { nodes => [ { id => 'tei-1', url => 'http://tei:8080', model => 'bge', rerank_format => 'huggingface' } ] };
  ok !eval { Langertha::Skeid->new(config_loader => sub { $bad }); 1 }, 'a config with an unknown rerank_format does not load';
  like $@, qr/unknown rerank_format 'huggingface'/, 'and says why';

  # On a reload the running config stays, and the failure is reported.
  my $cfg = { nodes => [ { id => 'tei-1', url => 'http://tei:8080', model => 'bge', rerank_format => 'tei' } ] };
  my $live = Langertha::Skeid->new(config_loader => sub { $cfg }, config_reload_interval => 0);
  is $live->list_nodes->[0]{rerank_format}, 'tei', 'a config node carries its rerank_format';
  $cfg = $bad;
  {
    local $SIG{__WARN__} = sub { };
    $live->call_function('nodes.list', {});
  }
  like $live->reload_status->{error} // '', qr/unknown rerank_format/, 'a reload with an unknown one fails';
  is $live->list_nodes->[0]{rerank_format}, 'tei', 'and the running node is kept';

  my $over_admin = eval { $skeid->call_function('nodes.add', { id => 'x', url => 'http://x', rerank_format => 'nope' }) };
  like $@, qr/unknown rerank_format 'nope'/, 'nodes.add refuses it too';
};

subtest 'two nodes of one model share the load; max_conns and health are respected' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-a', 'vllm', max_conns => 1);
  add_tei($skeid, 'gpu-b', max_conns => 1);

  my %served;
  for my $i (1 .. 6) {
    rerank($t, ($i % 2 ? $R : $RA), request());
    $t->status_is(200)->json_is('/results/0/index' => 1);
    $served{ $t->tx->res->headers->header('x-skeid-node') }++;
  }
  is_deeply \%served, { 'gpu-a' => 3, 'gpu-b' => 3 }, 'six requests, three per node';
  is_deeply [ sort map { $_->{tag} } @UPSTREAM ], [ ('gpu-a') x 3, ('gpu-b') x 3 ],
    'and each node\'s own upstream saw its three, each in its dialect';

  # A second relayed node instead of the TEI one, so both can be held.
  $skeid->remove_node('gpu-b');
  add_node($skeid, 'gpu-b', 'infinity', max_conns => 1);
  $MODE = 'hold';
  my $before = scalar @UPSTREAM;
  my @held = map { raw_client($t, raw_request($R, request())) } 1 .. 2;
  ok run_until(sub { @UPSTREAM == $before + 2 }), 'two requests are held upstream';
  is_deeply [ sort map { $_->{tag} } @UPSTREAM[ $before .. $before + 1 ] ], [ 'gpu-a', 'gpu-b' ],
    'one on each node, as max_conns 1 demands';
  is inflight($skeid, 'gpu-a') + inflight($skeid, 'gpu-b'), 2, 'both slots are taken';

  my $events = scalar @USAGE;
  rerank($t, $R, request());
  $t->status_is(429, 'a third request is refused once the wait is over')
    ->json_is('/error/type' => 'rate_limit_error');
  is scalar(@UPSTREAM), $before + 2, 'and was never forwarded';
  is scalar(@USAGE), $events, 'nor metered';

  $MODE = '';
  $_->{answer}->() for grep { $_->{answer} } @UPSTREAM;
  ok run_until(sub { !inflight($skeid, 'gpu-a') && !inflight($skeid, 'gpu-b') }), 'the held requests finish';
  ok run_until(sub { !grep { $_->{buffer} !~ /relevance_score/ } @held }), 'and their clients have the answer';
  $_->{stream}->close for grep { $_->{stream} } @held;

  $skeid->set_node_health('gpu-a', 0);
  %served = ();
  for (1 .. 3) {
    rerank($t, $R, request());
    $t->status_is(200);
    $served{ $t->tx->res->headers->header('x-skeid-node') }++;
  }
  is_deeply \%served, { 'gpu-b' => 3 }, 'an unhealthy node gets nothing';

  $skeid->set_node_health('gpu-b', 0);
  my $calls = scalar @UPSTREAM;
  rerank($t, $R, request());
  $t->status_is(503)->json_is('/error/type' => 'model_not_found');
  is scalar(@UPSTREAM), $calls, 'no healthy node: nothing forwarded';
  rerank($t, $R, request(model => 'no-such-reranker'));
  $t->status_is(503, 'a model no node serves is 503 as well')->json_is('/error/type' => 'model_not_found');
  paired($skeid, $_, 'load sharing') for qw( gpu-a gpu-b );
};

subtest 'client_auth answers 401 before anything is forwarded' => sub {
  my ($t, $skeid) = proxy(config => { client_auth => { keys => [$ALICE_ID] } });
  add_node($skeid, 'gpu-1', 'vllm');

  for my $path ($R, $RA) {
    rerank($t, $path, request());
    $t->status_is(401, "$path without a key: 401")
      ->header_is('WWW-Authenticate' => 'Bearer realm="skeid"')
      ->json_is('/error/type' => 'invalid_request_error')
      ->json_is('/error/code' => 'invalid_api_key')
      ->json_is('/error/message' => 'Missing API key');
    rerank($t, $path, request(), { Authorization => 'Bearer sk-mallory' });
    $t->status_is(401, "$path with an unknown key: 401")->json_is('/error/message' => 'Invalid API key');
    # The gate comes first: a body that would be a 400 is still a 401.
    $t->post_ok($path => { 'Content-Type' => 'application/json' } => 'not json')
      ->status_is(401, "$path: the gate answers before the body is looked at");
  }
  is scalar(@UPSTREAM), 0, 'nothing forwarded';
  is scalar(@USAGE), 0, 'nothing metered';
  is $skeid->node_metrics('gpu-1')->{started}, 0, 'no request.start';

  for my $path ($R, $RA) {
    rerank($t, $path, request(), { Authorization => "Bearer $ALICE_KEY" });
    $t->status_is(200, "$path: a listed key gets in");
    is $USAGE[-1]{api_key_id}, $ALICE_ID, "$path: metered on its key id";
  }
  is scalar(@UPSTREAM), 2, 'two requests forwarded in all';
};

subtest 'a key\'s policy holds on the rerank route' => sub {
  my ($t, $skeid) = proxy(config => {
    policies       => { chat_only => { models => ['some-chat-model'] }, open => {} },
    default_policy => 'chat_only',
    keys           => { $ALICE_ID => 'open' },
  });
  add_node($skeid, 'gpu-1', 'vllm');
  rerank($t, $R, request());
  $t->status_is(403, 'a key whose policy does not grant the model is refused')
    ->json_is('/error/type' => 'permission_error');
  is scalar(@UPSTREAM), 0, 'and nothing is forwarded';
  is scalar(@USAGE), 0, 'nor metered';
  rerank($t, $R, request(), { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(200, 'a key whose policy grants it is served');
};

subtest 'the node\'s key replaces the client\'s; a node whose key is missing is not called' => sub {
  local $ENV{SKEID_K92_NODE_KEY} = 'node-secret-key';
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', api_key_env => 'SKEID_K92_NODE_KEY');
  add_tei($skeid, 'tei-1', model => 'tei-reranker', api_key_env => 'SKEID_K92_NODE_KEY');
  for my $model ('bge-reranker', 'tei-reranker') {
    rerank($t, $R, request(model => $model), { Authorization => "Bearer $ALICE_KEY", 'X-Api-Key' => $ALICE_KEY });
    $t->status_is(200);
    is $UPSTREAM[-1]{authorization}, 'Bearer node-secret-key', "$model: the node gets its own key";
    is $UPSTREAM[-1]{x_api_key}, undef, "$model: and none of the client's credentials";
  }

  my ($t2, $skeid2) = proxy();
  add_node($skeid2, 'gpu-1', 'vllm', api_key_env => 'SKEID_K92_UNSET_KEY', max_conns => 1);
  add_tei($skeid2, 'tei-1', model => 'tei-reranker', api_key_env => 'SKEID_K92_UNSET_KEY', max_conns => 1);
  for my $model ('bge-reranker', 'tei-reranker') {
    rerank($t2, $R, request(model => $model), { Authorization => "Bearer $ALICE_KEY" });
    $t2->status_is(503, "$model: an unkeyed node answers 503")
      ->json_is('/error/type' => 'upstream_key_unavailable');
    is $USAGE[-1]{ok}, 0, "$model: one failed event";
    is $USAGE[-1]{error_type}, 'upstream_key_unavailable', "$model: naming the cause";
    is $USAGE[-1]{endpoint}, '/v1/rerank', "$model: on the rerank endpoint";
    ok !exists($USAGE[-1]{documents}), "$model: and no documents";
  }
  is scalar(@UPSTREAM), 0, 'no node was called';
  is scalar(@USAGE), 2, 'one event per refused request';
  unlike join(' ', map { $_->{error_message} } @USAGE) . $t2->tx->res->body, qr/\Q$ALICE_KEY\E/,
    'and the client\'s key is in neither the events nor the answer';
  paired($skeid2, $_, 'unkeyed node') for qw( gpu-1 tei-1 );
};

subtest 'an upstream error is one failed event and a free slot' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', max_conns => 1);

  $MODE = 'fail';
  rerank($t, $R, request());
  $t->status_is(500)
    ->json_is('/error/type' => 'upstream_error', 'the error is in the OpenAI shape')
    ->json_like('/error/message' => qr/CUDA out of memory/, 'with the node\'s own message');
  is scalar(@USAGE), 1, 'one usage event';
  is $USAGE[0]{ok}, 0, 'failed';
  is $USAGE[0]{status_code}, 500, 'with the upstream status';
  is $USAGE[0]{error_type}, 'upstream_error', 'and the cause';
  is $USAGE[0]{endpoint}, '/v1/rerank', 'on the rerank endpoint';
  ok !exists($USAGE[0]{documents}), 'and no documents: the node did not answer them';
  is $USAGE[0]{input_tokens}, 0, 'nor tokens';
  paired($skeid, 'gpu-1', 'upstream 500');

  # A node that is gone: connection refused.
  $MODE = '';
  my ($t2, $skeid2) = proxy();
  my $dead = Mojo::IOLoop::Server->generate_port;
  $skeid2->add_node(id => 'dead', url => "http://127.0.0.1:$dead/v1", model => 'bge-reranker', max_conns => 1);
  rerank($t2, $R, request());
  $t2->status_is(502)->json_is('/error/type' => 'upstream_error');
  is scalar(@USAGE), 1, 'one usage event for the unreachable node';
  is $USAGE[0]{ok}, 0, 'failed';
  ok !exists($USAGE[0]{documents}), 'without documents';
  paired($skeid2, 'dead', 'unreachable node');
};

subtest 'a client that hangs up frees the slot and leaves one failed event' => sub {
  my ($t, $skeid) = proxy();
  add_node($skeid, 'gpu-1', 'vllm', max_conns => 1);
  $MODE = 'hold';

  for my $path ($R, $RA) {
    my $events = scalar @USAGE;
    my $calls  = scalar @UPSTREAM;
    my $client = raw_client($t, raw_request($path, request()));
    ok run_until(sub { @UPSTREAM == $calls + 1 }), "$path: the request reached the node";
    my $seen = $UPSTREAM[-1];
    is inflight($skeid, 'gpu-1'), 1, "$path: the slot is taken";

    $client->{stream}->close;
    ok run_until(sub { $seen->{hung_up} }), "$path: the node saw its connection close";
    ok run_until(sub { !inflight($skeid, 'gpu-1') }), "$path: the slot is free";
    settle();
    is scalar(@USAGE) - $events, 1, "$path: one usage event";
    my $ev = $USAGE[-1];
    is $ev->{ok}, 0, "$path: failed";
    is $ev->{error_type}, 'client_abort', "$path: client_abort";
    is $ev->{status_code}, 499, "$path: 499";
    is $ev->{endpoint}, '/v1/rerank', "$path: on the rerank endpoint";
    ok !exists($ev->{documents}), "$path: and no documents";
    paired($skeid, 'gpu-1', "$path abort");
  }
  is $skeid->node_metrics('gpu-1')->{aborted}, 2, 'both requests counted as aborted';
};

subtest 'Protocol::Rerank: where an answer reports its tokens' => sub {
  my $rerank = 'Langertha::Skeid::Protocol::Rerank';
  my $block = sub { my ($n) = @_; return { prompt_tokens => $n, completion_tokens => 0, total_tokens => $n } };
  my $headers = sub { return Mojo::Headers->new->from_hash({@_}) };

  is_deeply [ $rerank->routes ], [ '/rerank', '/v1/rerank' ], 'the two spellings';
  is $rerank->endpoint, '/v1/rerank', 'one endpoint for the event';
  is_deeply [ $rerank->formats ], ['tei'], 'one upstream format beside the default';
  is $rerank->normalize_format(undef), '', 'no format';
  is $rerank->normalize_format('Tei'), 'tei', 'any case';
  ok $rerank->at_server_root('tei'), 'a TEI route sits at the server root';
  ok !$rerank->at_server_root(''), 'the default one below /v1';

  is_deeply $rerank->usage({ usage => { prompt_tokens => 17, total_tokens => 17 } }, undef, ''), $block->(17),
    'usage.prompt_tokens';
  is_deeply $rerank->usage({ usage => { total_tokens => 29 } }, undef, ''), $block->(29), 'usage.total_tokens alone';
  is_deeply $rerank->usage({ usage => { prompt_tokens => undef, total_tokens => 29 } }, undef, ''), $block->(29),
    'a null prompt_tokens falls back to the total';
  is_deeply $rerank->usage({ usage => { prompt_tokens => 12, total_tokens => 30 } }, undef, ''), $block->(12),
    'prompt_tokens wins over a total';
  is_deeply $rerank->usage({ meta => { tokens => { input_tokens => 23, output_tokens => 0 } } }, undef, ''), $block->(23),
    'meta.tokens.input_tokens';
  is_deeply $rerank->usage({ usage => { total_tokens => 0 } }, undef, ''), $block->(0), 'a reported zero is a count';
  is $rerank->usage({ meta => { billed_units => { search_units => 1 } } }, undef, ''), undef,
    'search units are not tokens';
  is $rerank->usage({ results => [] }, undef, ''), undef, 'no usage: nothing';
  is $rerank->usage([ { index => 0, score => 1 } ], $headers->('x-compute-tokens' => 41), ''), undef,
    'the header is not read for a node without a format';
  is $rerank->usage(undef, undef, ''), undef, 'no answer: nothing';
  for my $junk ('many', -1, 1.5, '', [7], { n => 7 }, 9**9**9, -9**9**9) {
    is $rerank->usage({ usage => { total_tokens => $junk } }, undef, ''), undef,
      'not a count: ' . (ref($junk) || $junk);
  }

  is_deeply $rerank->usage([], $headers->('X-Compute-Tokens' => '41'), 'tei'), $block->(41), 'TEI: the header';
  is $rerank->usage([], $headers->(), 'tei'), undef, 'TEI: no header, nothing';
  is $rerank->usage([], $headers->('x-compute-tokens' => 'lots'), 'tei'), undef, 'TEI: a header that is no count';
  is $rerank->usage({ usage => { total_tokens => 5 } }, $headers->(), 'tei'), undef,
    'TEI: a body usage is not read for it';

  # A TEI answer that is not what TEI answers.
  my $body = { documents => [ 'a', 'b' ], return_documents => 1 };
  my $translate = sub { return eval { $rerank->response_from_upstream($_[0], $headers->(), $body, 'm', 'tei') } };
  is_deeply $translate->([ { index => 1, score => 0.5, text => 'b' }, { index => 0, score => 0.5, text => 'a' } ]),
    { model => 'm', results => [
      { index => 0, relevance_score => 0.5, document => { text => 'a' } },
      { index => 1, relevance_score => 0.5, document => { text => 'b' } },
    ] }, 'equal scores stay in document order';
  is_deeply $translate->([]), { model => 'm', results => [] }, 'an empty array is an empty result';
  is $translate->($_->[1]), undef, "refused: $_->[0]" for (
    [ 'an object'               => { results => [] } ],
    [ 'nothing'                 => undef ],
    [ 'a row that is no object' => [ 'x' ] ],
    [ 'a row without a score'   => [ { index => 0 } ] ],
    [ 'a row without an index'  => [ { score => 0.5 } ] ],
    [ 'an index out of range'   => [ { index => 2, score => 0.5 } ] ],
    [ 'a score that is no number' => [ { index => 0, score => 'high' } ] ],
  );
};

# --- the usage event field through the stores -------------------------------------------------

my @EVENTS = (
  { api_key_id => 'k_alice', model => 'bge', endpoint => $R, documents => 3,
    metrics => { usage => { input => 17, total => 17 } } },
  { api_key_id => 'k_alice', model => 'bge', endpoint => $R, documents => 40 },
  { api_key_id => 'k_bob',   model => 'bge', endpoint => $R, status_code => 500, ok => 0 },
  { api_key_id => 'k_bob',   model => 'chat', endpoint => '/v1/chat/completions',
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
  is $report->{totals}{documents}, 43, "$label: totals sum documents";
  is $report->{totals}{total_tokens}, 32, "$label: tokens are counted beside it";
  is $report->{totals}{input_tokens}, 27, "$label: the rerank tokens among the input tokens";
  is $report->{totals}{audio_seconds}, 0, "$label: and no audio";
  my %by_key = map { $_->{api_key_id} => $_ } @{ $report->{by_key} };
  is $by_key{k_alice}{documents}, 43, "$label: by key, the key that reranked";
  is $by_key{k_bob}{documents}, 0, "$label: by key, events that carry none add nothing";
  my %by_model = map { $_->{model} => $_ } @{ $report->{by_model} };
  is $by_model{bge}{documents}, 43, "$label: by model";
  is $by_model{chat}{documents}, 0, "$label: by model, a chat model has none";
}

subtest 'record_usage carries documents only when given' => sub {
  my @events;
  my $skeid = Langertha::Skeid->new(store_usage_event => sub { push @events, $_[1]; return { ok => 1 } });
  record_events($skeid, @EVENTS[ 0, 2 ]);
  is $events[0]{documents}, 3, 'a count is kept';
  is $events[0]{input_tokens}, 17, 'beside its tokens';
  ok !exists($events[1]{documents}), 'an event without one has no such key';
};

subtest 'jsonlog writes documents and reports them' => sub {
  my $dir = "$TMP/jsonlog";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  record_events($skeid, @EVENTS);
  my @lines = map { decode_json($_) } map { path($_)->lines_utf8 } grep { -f } path($dir)->children;
  is scalar(@lines), 4, 'four events on disk';
  is_deeply [ sort { $a <=> $b } map { $_->{documents} } grep { exists $_->{documents} } @lines ],
    [ 3, 40 ], 'the two answered rerank events carry their count';
  is scalar(grep { !exists $_->{documents} } @lines), 2, 'the other two have no such key';
  check_report('jsonlog', $skeid->call_function('usage.report', {}));
};

subtest 'the DBI store keeps documents in a nullable column' => sub {
  eval { require DBI; require DBD::SQLite; 1 } or plan skip_all => 'DBI/DBD::SQLite not available';

  my $db = "$TMP/usage.sqlite";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  record_events($skeid, @EVENTS);
  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  is_deeply $dbh->selectcol_arrayref('SELECT documents FROM usage_events ORDER BY id'),
    [ 3, 40, undef, undef ], 'a count is stored, an event without one is NULL, not zero';
  $dbh->disconnect;
  check_report('sqlite', $skeid->call_function('usage.report', {}));

  # A table from before the column existed -- and before audio_seconds did -- gains it on
  # prepare, once, and its old rows read as not counted.
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
  record_events($upgraded, $EVENTS[0]);
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  my @cols = grep { $_->{name} eq 'documents' }
    @{ $odbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} }) };
  is scalar(@cols), 1, 'the column is added to a table that predates it, and only once';
  ok !$cols[0]{notnull}, 'and it is nullable';
  is_deeply $odbh->selectcol_arrayref('SELECT documents FROM usage_events ORDER BY id'),
    [ undef, 3 ], 'the old row reads NULL, the new one its count';
  $odbh->disconnect;
  my $report = $upgraded->call_function('usage.report', {});
  is $report->{totals}{documents}, 3, 'a report over old and new rows sums what there is';
  is $report->{totals}{requests}, 2, 'and counts both';
};

subtest 'a rerank request reaches the configured store with its documents' => sub {
  my $dir = "$TMP/proxy-jsonlog";
  my ($t, $skeid) = proxy(usage_store => { backend => 'jsonlog', path => $dir, mode => 'dir' });
  add_node($skeid, 'gpu-1', 'vllm');
  add_tei($skeid, 'tei-1', model => 'tei-reranker');
  rerank($t, $R, request(), { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(200);
  rerank($t, $RA, request(model => 'tei-reranker', documents => [ @DOCS, 'one more' ]),
    { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(200);
  $MODE = 'fail';
  rerank($t, $R, request(), { Authorization => "Bearer $ALICE_KEY" });
  $t->status_is(500);
  my $report = $skeid->call_function('usage.report', {});
  is $report->{totals}{requests}, 3, 'three events in the store';
  is $report->{totals}{documents}, 7, 'the two answered ones counted: 3 + 4';
  is $report->{totals}{input_tokens}, $TOKENS{vllm} + $TOKENS{tei}, 'with their tokens as input';
  is $report->{by_key}[0]{api_key_id}, $ALICE_ID, 'under the caller\'s key id';
  my %by_model = map { $_->{model} => $_ } @{ $report->{by_model} };
  is $by_model{'bge-reranker'}{documents}, 3, 'by model: the relayed node\'s';
  is $by_model{'tei-reranker'}{documents}, 4, 'by model: the TEI node\'s';

  if (eval { require DBI; require DBD::SQLite; 1 }) {
    my $db = "$TMP/proxy.sqlite";
    my ($t2, $skeid2) = proxy(usage_store => { backend => 'sqlite', sqlite_path => $db });
    add_node($skeid2, 'gpu-1', 'vllm');
    rerank($t2, $R, request());
    $t2->status_is(200);
    $MODE = 'fail';
    rerank($t2, $R, request());
    $t2->status_is(500);
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
    is_deeply $dbh->selectall_arrayref('SELECT endpoint, documents, input_tokens, ok FROM usage_events ORDER BY id'),
      [ [ '/v1/rerank', 3, $TOKENS{vllm}, 1 ], [ '/v1/rerank', undef, 0, 0 ] ],
      'sqlite: the answered request has its documents, the failed one NULL';
    $dbh->disconnect;
  }
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

subtest 'skeid usage prints documents only where there are some' => sub {
  # A store without rerank events: the report is what it was before the field existed.
  my $plain = "$TMP/cli-plain";
  my $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $plain, mode => 'dir' });
  record_events($skeid, $EVENTS[3], $EVENTS[3]);
  my ($code, $output) = run_skeid('usage', '--log-path', $plain);
  is $code, 0, 'exits 0' or diag $output;
  my ($head) = $output =~ /\A(.*?\nRecent:\n)/s;
  is $head, <<"REPORT", 'the report of a store without rerank events is unchanged';
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
  unlike $output, qr/rerank|documents/i, 'and nowhere mentions rerank or documents';

  my $ranked = "$TMP/cli-rerank";
  $skeid = Langertha::Skeid->new(usage_store => { backend => 'jsonlog', path => $ranked, mode => 'dir' });
  record_events($skeid, @EVENTS, { api_key_id => 'k_alice', model => 'whisper', endpoint => '/v1/audio/transcriptions', audio_seconds => 12 });
  ($code, $output) = run_skeid('usage', '--log-path', $ranked);
  is $code, 0, 'exits 0 with rerank events' or diag $output;
  unlike $output, qr/isn't numeric|uninitialized/, 'no warnings';
  like $output, qr/^Totals: requests=5 .*\nAudio:  seconds=12\nRerank: documents=43\n/m,
    'a Rerank line follows the totals, after the audio one';
  like $output, qr/^  k_alice +requests=3 tokens=17 cost=\$0\.00000000 audio_seconds=12 documents=43$/m,
    'the key that reranked ends in its documents';
  like $output, qr/^  k_bob +requests=2 tokens=15 cost=\$0\.00000000$/m, 'a key without is printed as ever';
  like $output, qr/^  bge +requests=3 tokens=17 cost=\$0\.00000000 documents=43$/m, 'by model likewise';
  like $output, qr/^  chat +requests=1 tokens=15 cost=\$0\.00000000$/m, 'a model without is printed as ever';

  ($code, $output) = run_skeid('usage', '--log-path', $ranked, '--json');
  is $code, 0, '--json exits 0';
  is decode_json(Encode::encode_utf8($output))->{totals}{documents}, 43, '--json carries the sum';
};

done_testing;
