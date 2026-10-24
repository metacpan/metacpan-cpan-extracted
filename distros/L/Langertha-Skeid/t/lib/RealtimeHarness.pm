package RealtimeHarness;
# Shared by the t/90-realtime-*.t tests (skeid k95): a Skeid proxy over a config the test can
# change live, a fake node whose realtime endpoint is a WebSocket mounted on the same app, and a
# raw WebSocket client that records what it saw. Offline by construction -- everything is a
# loopback socket of this process.
use strict;
use warnings;
use Exporter 'import';
use JSON::MaybeXS ();
use Mojo::IOLoop;
use Test::Mojo;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

our @EXPORT_OK = qw( settle run_until frame );

my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1);
sub frame { return $JSON->encode($_[0]) }

sub settle {
  my ($seconds) = @_;
  my $id = Mojo::IOLoop->timer(($seconds // 0.05) => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($id);
  return;
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

# The fake node's behaviour for the next handshake, in $h->mode: '' accepts and records;
# 'refuse' answers the handshake with a 401; 'stall' accepts and then stops reading;
# 'slow' leaves the handshake pending until $h->release.
sub new {
  my ($class, %opts) = @_;
  my $self = bless {
    cfg      => delete($opts{config}) || {},
    usage    => [],
    log      => [],
    upstream => [],
    mode     => '',
    pending  => [],
    on_message => undef,
  }, $class;

  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms  => 60,
    route_wait_poll_ms     => 5,
    config_reload_interval => 0,
    config_loader          => sub { $self->{cfg} },
    ($opts{usage_store} ? () : (store_usage_event => sub { push @{ $self->{usage} }, $_[1]; return { ok => 1 } })),
    %opts,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('trace');
  $app->log->unsubscribe('message')->on(message => sub {
    my ($log, $level, @lines) = @_;
    push @{ $self->{log} }, [ $level, join(' ', @lines) ];
  });
  $app->routes->websocket('/__up/:tag/v1/realtime' => sub { $self->_fake_node(@_) });
  $self->{skeid} = $skeid;
  $self->{app}   = $app;
  $self->{t}     = Test::Mojo->new($app);
  $self->{up}    = $self->{t}->ua->server->nb_url->clone;
  return $self;
}

sub t        { $_[0]{t} }
sub skeid    { $_[0]{skeid} }
sub app      { $_[0]{app} }
sub usage    { $_[0]{usage} }
sub log      { $_[0]{log} }
sub upstream { $_[0]{upstream} }
sub mode     { my $s = shift; $s->{mode} = shift if @_; $s->{mode} }
sub config   { my $s = shift; $s->{cfg} = shift if @_; $s->{cfg} }
sub on_message { my $s = shift; $s->{on_message} = shift if @_; $s->{on_message} }

sub node_url { my ($self, $tag) = @_; return $self->{up}->clone->path("/__up/$tag/v1")->to_string }

sub add_node {
  my ($self, $id, %extra) = @_;
  return $self->{skeid}->add_node(
    id => $id, url => $self->node_url($id), model => 'whisper-rt', engine => 'openai',
    max_conns => 4, %extra,
  );
}

# The node's side of the handshake and the session after it.
sub _fake_node {
  my ($self, $c) = @_;
  my $seen = {
    tag      => $c->stash('tag'),
    query    => { map { $_ => $c->req->url->query->every_param($_) } @{ $c->req->url->query->names } },
    headers  => { map { lc($_) => $c->req->headers->header($_) } @{ $c->req->headers->names } },
    received => [],
    binary   => [],
    closed   => undef,
    c        => $c,
  };
  push @{ $self->{upstream} }, $seen;

  if ($self->{mode} eq 'refuse') {
    return $c->render(status => 401, json => { error => { message => 'bad node key' } });
  }
  if ($self->{mode} eq 'slow') {
    $c->render_later;
    push @{ $self->{pending} }, sub { $self->_accept($c, $seen) };
    return;
  }
  $self->_accept($c, $seen);
  return;
}

sub _accept {
  my ($self, $c, $seen) = @_;
  # A client that left while the handshake was held has no transaction any more.
  return unless $c->tx;
  $c->on(text => sub {
    my (undef, $bytes) = @_;
    push @{ $seen->{received} }, $bytes;
    $self->{on_message}->($seen, $bytes) if $self->{on_message};
  });
  $c->on(binary => sub { push @{ $seen->{binary} }, $_[1] });
  $c->on(finish => sub { $seen->{closed} = [ $_[1], $_[2] ] });
  if ($self->{mode} eq 'stall') {
    my $stream = Mojo::IOLoop->stream($c->tx->connection);
    $stream->stop if $stream;
  }
  # Make sure the 101 goes out even when nothing is sent first.
  $c->rendered(101) unless $c->tx->established;
  return;
}

sub release { my ($self) = @_; (shift @{ $self->{pending} })->() while @{ $self->{pending} } }

# A text frame from the node to Skeid (and so to the client).
sub node_send {
  my ($self, $seen, $data) = @_;
  $seen->{c}->send({ text => ref($data) ? frame($data) : $data });
  return;
}

# ---- the client ------------------------------------------------------------------------------

sub ws_url {
  my ($self, $path_query) = @_;
  my $u = $self->{up}->clone;
  $u->path_query($path_query);
  $u->scheme('ws');
  return $u->to_string;
}

# Opens a WebSocket to the proxy. Returns once the handshake was answered: a hashref with
# `code` (the handshake's HTTP status), `protocol`, `tx`, and, as the session goes, `messages`
# (text frames), `closed` ([code, reason]) once the connection ended, `error_body`.
sub connect {
  my ($self, $path_query, %o) = @_;
  my $client = { messages => [], binary => [], closed => undef, done => 0, code => undef };
  my $headers = $o{headers} || {};
  my $protocols = $o{protocols} || [];
  $self->{t}->ua->websocket($self->ws_url($path_query) => $headers => $protocols => sub {
    my ($ua, $tx) = @_;
    $client->{tx}   = $tx;
    $client->{code} = $tx->res->code;
    $client->{done} = 1;
    if ($tx->is_websocket) {
      $client->{protocol} = $tx->protocol;
      $client->{headers}  = $tx->res->headers->to_hash;
      $tx->max_websocket_size($o{max_size}) if $o{max_size};
      $tx->on(text   => sub { push @{ $client->{messages} }, $_[1] });
      $tx->on(binary => sub { push @{ $client->{binary} }, $_[1] });
      $tx->on(finish => sub { $client->{closed} = [ $_[1], $_[2] ] });
    }
    else {
      $client->{error_body}    = $tx->res->body;
      $client->{error_headers} = $tx->res->headers->to_hash;
    }
  });
  run_until(sub { $client->{done} }, $o{wait} // 3);
  return $client;
}

sub send_text {
  my ($self, $client, $data) = @_;
  $client->{tx}->send({ text => ref($data) ? frame($data) : $data });
  return;
}

# Everything recorded for the session of a client, decoded.
sub messages { my ($self, $client) = @_; return [ map { $JSON->decode($_) } @{ $client->{messages} } ] }

sub inflight { my ($self, $id) = @_; return $self->{skeid}->node_metrics($id)->{inflight} }

sub metrics { my ($self, $id) = @_; return $self->{skeid}->node_metrics($id) }

1;
