use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();
use File::Temp qw(tempdir);
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(encode_json);
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A streamed request's usage event carries content_bytes: the UTF-8 bytes of the content Skeid
# relayed (OpenAI face) or translated (Anthropic, Ollama faces) (skeid #36). It is an additive,
# optional field of the ADR 0004 usage event -- an observation recorded on every stream, also
# when the upstream reported token counts, and never turned into a token estimate. Non-ASCII is
# the case that matters: the count is bytes, not characters (skeid #35), on every face alike, or
# the same answer would read differently depending on the client's dialect.

my @deltas = ('Köln ', '東京 ', "\x{1F363}");
my $bytes  = 0;
$bytes += length(Encode::encode_utf8($_)) for @deltas;
is $bytes, 17, 'the fixture is 17 UTF-8 bytes (and 9 characters)';

my $with_usage = 1;

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $req = $c->req->json || {};
  unless ($req->{stream}) {
    return $c->render(json => {
      id => 'c1', model => 'm1', object => 'chat.completion',
      choices => [{ index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => join('', @deltas) } }],
      usage => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
    });
  }
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => { role => 'assistant' } }] }) . "\n\n");
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => { content => $_ } }] }) . "\n\n")
    for @deltas;
  my $final = { id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => 'stop' }] };
  $final->{usage} = { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 } if $with_usage;
  $c->write_chunk('data: ' . encode_json($final) . "\n\n");
  $c->write_chunk("data: [DONE]\n\n");
  $c->write_chunk('' => sub { $c->finish });
});
my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up->start;
my $up_port = $up->ports->[0];

my @events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$up_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$pd->start;
my $proxy_port = $pd->ports->[0];

my $ua = Mojo::UserAgent->new;

sub post {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port$path" => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx;
}

my %faces = (
  openai => ['/v1/chat/completions',
    { model => 'm1', stream => JSON::MaybeXS::true, messages => [{ role => 'user', content => 'hi' }] }],
  anthropic => ['/v1/messages',
    { model => 'm1', max_tokens => 64, stream => JSON::MaybeXS::true, messages => [{ role => 'user', content => 'hi' }] }],
  ollama => ['/api/chat',
    { model => 'm1', stream => JSON::MaybeXS::true, messages => [{ role => 'user', content => 'hi' }] }],
);

for my $face (qw(openai anthropic ollama)) {
  for my $reported (1, 0) {
    $with_usage = $reported;
    @events = ();
    my ($path, $payload) = @{$faces{$face}};
    my $tx = post($path, $payload);
    my $label = "$face face, upstream " . ($reported ? 'reported' : 'did not report') . ' tokens';

    is $tx->res->code, 200, "$label: served";
    is scalar(@events), 1, "$label: one usage event";
    is $events[0]{content_bytes}, $bytes,
      "$label: content_bytes is the UTF-8 byte count of the streamed content, not its 9 characters";
    if ($reported) {
      is $events[0]{output_tokens}, 3, "$label: the reported token count is kept as reported";
    } else {
      is $events[0]{output_tokens}, 0,
        "$label: no token estimate is invented from content_bytes";
    }
  }
}

# --- Non-streamed: the field is absent, meaning "not measured", not a measured zero -----------
{
  @events = ();
  my $tx = post('/v1/chat/completions', { model => 'm1', messages => [{ role => 'user', content => 'hi' }] });
  is $tx->res->code, 200, 'non-streamed request served';
  is scalar(@events), 1, 'one usage event';
  ok !exists($events[0]{content_bytes}), 'a non-streamed event carries no content_bytes key';
  is $events[0]{output_tokens}, 3, 'and its token counts are unchanged';
}

# --- SQLite: the column is nullable, holds the stream's count, and migrates additively ---------
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 4;

  my $dir = tempdir(CLEANUP => 1);
  my $db  = "$dir/usage.sqlite";
  my $store_skeid = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $db });
  $store_skeid->call_function('usage.record', {
    api_key_id => 'k_stream', model => 'm', ok => 1, status_code => 200, content_bytes => 17,
    metrics => { usage => { input => 7, output => 3, total => 10 } },
  });
  $store_skeid->call_function('usage.record', {
    api_key_id => 'k_json', model => 'm', ok => 1, status_code => 200,
    metrics => { usage => { input => 7, output => 3, total => 10 } },
  });

  my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
  my ($streamed) = $dbh->selectrow_array(q{SELECT content_bytes FROM usage_events WHERE api_key_id = 'k_stream'});
  is $streamed, 17, 'a streamed event round-trips its content_bytes';
  my ($plain) = $dbh->selectrow_array(q{SELECT content_bytes FROM usage_events WHERE api_key_id = 'k_json'});
  ok !defined($plain), 'a non-streamed event stores NULL, not zero';
  $dbh->disconnect;

  # A table from before the column existed gains it on prepare, once.
  my $old = "$dir/old.sqlite";
  my $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  $odbh->do(q{
    CREATE TABLE usage_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TEXT NOT NULL, request_id TEXT, api_format TEXT, endpoint TEXT,
      api_key_id TEXT, provider TEXT, engine TEXT, model TEXT, requested_model TEXT,
      node_id TEXT, route_url TEXT, status_code INTEGER, ok INTEGER NOT NULL DEFAULT 0,
      duration_ms INTEGER, input_tokens INTEGER NOT NULL DEFAULT 0,
      output_tokens INTEGER NOT NULL DEFAULT 0, total_tokens INTEGER NOT NULL DEFAULT 0,
      cached_tokens INTEGER, tool_calls INTEGER NOT NULL DEFAULT 0, cost_input_usd REAL NOT NULL DEFAULT 0,
      cost_output_usd REAL NOT NULL DEFAULT 0, cost_total_usd REAL NOT NULL DEFAULT 0,
      error_type TEXT, error_message TEXT
    )
  });
  $odbh->disconnect;
  my $upgraded = Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  my $written = $upgraded->call_function('usage.record', {
    api_key_id => 'k_new', model => 'm', ok => 1, status_code => 200, content_bytes => 5,
  });
  ok $written->{ok}, 'an event still writes against a table that predates content_bytes';
  Langertha::Skeid->new(usage_store => { backend => 'sqlite', sqlite_path => $old });
  $odbh = DBI->connect("dbi:SQLite:dbname=$old", '', '', { RaiseError => 1, PrintError => 0 });
  my @cols = grep { $_->{name} eq 'content_bytes' }
    @{ $odbh->selectall_arrayref('PRAGMA table_info(usage_events)', { Slice => {} }) };
  is scalar(@cols), 1, 'the column is added once, not again on a second prepare';
  $odbh->disconnect;
}

done_testing;
