use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
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
use Langertha::Skeid::UsageStore::DBI;

# A usage event is the billing unit (ADR 0004). When the store cannot write it, the request has
# already been served and must still complete -- but the lost event has to leave a trace an
# operator sees at a production log level, naming the request and the store, never the key
# (skeid k70). Before, a DBI statement failure was logged at debug only, and a store that
# reported failure in its answer ({ ok => 0 }, the JsonLog contract) was not logged at all.

my $customer_key = 'sk-k70-customer-secret-do-not-log';

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $req = $c->req->json || {};
  unless ($req->{stream}) {
    return $c->render(json => {
      id => 'c1', model => 'm1', object => 'chat.completion',
      choices => [{ index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'hello' } }],
      usage => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
    });
  }
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => { role => 'assistant', content => 'hello' } }] }) . "\n\n");
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => 'stop' }],
    usage => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 } }) . "\n\n");
  $c->write_chunk("data: [DONE]\n\n");
  $c->write_chunk('' => sub { $c->finish });
});
my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up->start;
my $up_port = $up->ports->[0];

my $ua = Mojo::UserAgent->new;

# Serves one request through a fresh proxy in front of $skeid and returns the transaction plus
# every log line at warn or above -- the level a production deployment keeps.
sub serve_one {
  my ($skeid, $request_id, $payload) = @_;
  $skeid->add_node(id => 'n1', url => "http://127.0.0.1:$up_port/v1", model => 'm1', max_conns => 4)
    unless grep { $_->{id} eq 'n1' } @{ $skeid->nodes };

  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  my @logged;
  $proxy->log->level('warn');
  $proxy->log->unsubscribe('message');
  $proxy->log->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @logged, { level => $level, text => join(' ', @lines) };
  });
  my $pd = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $pd->start;
  my $port = $pd->ports->[0];

  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port/v1/chat/completions" => {
    Authorization  => "Bearer $customer_key",
    'x-request-id' => $request_id,
  } => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  $pd->stop;
  return ($tx, \@logged);
}

sub check_lost_event {
  my ($label, $tx, $logged, $request_id, $backend, $body_check) = @_;
  is $tx->res->code, 200, "$label: the client still gets its answer";
  $body_check->($tx);
  my @lost = grep { $_->{text} =~ /usage event/ } @$logged;
  is scalar(@lost), 1, "$label: exactly one visible log line for the lost event"
    or diag explain $logged;
  my $line = $lost[0] || { level => '', text => '' };
  like $line->{level}, qr/\A(?:error|warn)\z/, "$label: logged at warn or error, not debug";
  like $line->{text}, qr/\Q$request_id\E/, "$label: the line names the request id";
  like $line->{text}, qr/\b\Q$backend\E\b/, "$label: the line names the store backend";
  ok !(grep { $_->{text} =~ /\Q$customer_key\E/ } @$logged), "$label: no log line carries the customer key";
}

my $plain  = { model => 'm1', messages => [{ role => 'user', content => 'hi' }] };
my $stream = { %$plain, stream => JSON::MaybeXS::true };

# --- SQLite: a statement that fails once connected ------------------------------------------
SKIP: {
  eval { require DBI; require DBD::SQLite; 1 } or skip 'DBI/DBD::SQLite not available', 9;

  my $dir = tempdir(CLEANUP => 1);
  my $skeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    usage_store => { backend => 'sqlite', sqlite_path => "$dir/usage.sqlite" },
  );
  # The table disappears under a connected store: every INSERT now fails.
  $skeid->_usage_store_obj->dbh->do('DROP TABLE usage_events');

  my ($tx, $logged) = serve_one($skeid, 'req-k70-sqlite', $plain);
  check_lost_event('sqlite, non-streamed', $tx, $logged, 'req-k70-sqlite', 'sqlite', sub {
    is $_[0]->res->json->{choices}[0]{message}{content}, 'hello', 'sqlite, non-streamed: body relayed';
  });

  my $res = $skeid->call_function('usage.record', { model => 'm1', ok => 1, status_code => 200 });
  ok !$res->{ok}, 'the DBI store reports a failed statement in its answer';
  like $res->{error} // '', qr/usage_events/, 'with the database error as the reason';
}

# --- JsonLog: a write that fails (the store answers { ok => 0 }) ------------------------------
{
  my $dir = tempdir(CLEANUP => 1);
  my $events = "$dir/events";
  my $skeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    usage_store => { backend => 'jsonlog', path => $events, mode => 'dir' },
  );
  # The event directory is replaced by a plain file: creating an event file there fails with
  # ENOTDIR, also for root, which ignores permission bits.
  path($events)->remove_tree;
  path($events)->spew('not a directory');

  my ($tx, $logged) = serve_one($skeid, 'req-k70-jsonlog', $stream);
  check_lost_event('jsonlog, streamed', $tx, $logged, 'req-k70-jsonlog', 'jsonlog', sub {
    like $_[0]->res->body, qr/data: \[DONE\]/, 'jsonlog, streamed: the stream ran to its end';
  });
}

# --- A DSN that carries a password never reaches an error text ------------------------------
{
  my $store = Langertha::Skeid::UsageStore::DBI->new(backend => 'postgresql', dsn => 'dbi:Pg:dbname=x');
  my $text = $store->_error_text(
    "DBI connect('dbname=skeid;host=db;password=hunter2','skeid',...) failed: timeout\n");
  unlike $text, qr/hunter2/, 'a password in a DSN is masked in the reported error';
  like $text, qr/password=\*\*\*/, 'and the error still says where it was';
}

# --- No store at all is not a failure: nothing to lose, nothing to log ------------------------
{
  my $skeid = Langertha::Skeid->new(route_wait_poll_ms => 5);
  my ($tx, $logged) = serve_one($skeid, 'req-k70-none', $plain);
  is $tx->res->code, 200, 'no store: served';
  is scalar(grep { $_->{text} =~ /usage event/ } @$logged), 0, 'no store: no lost-event line';
}

$up->stop;
done_testing;
