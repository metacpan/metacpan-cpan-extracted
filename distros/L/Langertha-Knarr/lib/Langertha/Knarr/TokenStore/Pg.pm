package Langertha::Knarr::TokenStore::Pg;
# ABSTRACT: PostgreSQL token store for token_auth, asynchronous under IO::Async
our $VERSION = '1.103';
use Moose;
use Carp qw( croak );
use Future;
use IO::Async::Loop;
use IO::Async::Handle;
use IO::Async::Timer::Periodic;
use Log::Any qw( $log );
use Module::Runtime qw( require_module );
use Scalar::Util qw( weaken );


my %DEFAULT_COLUMNS = (
  hash     => 'token_hash',
  model    => 'model',
  provider => 'provider',
  expires  => 'expires_at',
);

my $UNAVAILABLE = "token store unavailable\n";

has dsn => ( is => 'ro', isa => 'Str', required => 1 );

has user => ( is => 'ro', isa => 'Maybe[Str]' );

has password_env => ( is => 'ro', isa => 'Maybe[Str]' );

has relation => ( is => 'ro', isa => 'Str', required => 1 );

has listen => ( is => 'ro', isa => 'Str', required => 1 );

has columns => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

has loop => (
  is => 'ro',
  lazy => 1,
  default => sub { IO::Async::Loop->new },
);

has connect_timeout => ( is => 'ro', isa => 'Num', default => 3 );

has query_timeout => ( is => 'ro', isa => 'Num', default => 10 );

# connection state, all of it owned by the process in _pid
has _dbh      => ( is => 'rw', clearer => '_clear_dbh' );
has _pid      => ( is => 'rw', isa => 'Int', default => 0 );
has _watch    => ( is => 'rw', clearer => '_clear_watch' );
has _ticker   => ( is => 'rw', clearer => '_clear_ticker' );
has _inflight => ( is => 'rw', clearer => '_clear_inflight' );
has _queue    => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has _sql      => ( is => 'rw', isa => 'Str' );

# reconnect state
has _use_loop     => ( is => 'rw', isa => 'Bool', default => 0 );
has _backoff      => ( is => 'rw', isa => 'Num', default => 0 );
has _next_attempt => ( is => 'rw', isa => 'Num', default => 0 );
has _reconnect_f  => ( is => 'rw', clearer => '_clear_reconnect_f' );
has _connecting_f => ( is => 'rw', clearer => '_clear_connecting_f' );

with 'Langertha::Knarr::TokenStore';

sub BUILD {
  my ($self) = @_;
  my $ok = eval { require_module('DBI'); require_module('DBD::Pg'); 1 };
  croak "token_auth backend postgresql needs DBD::Pg" unless $ok;
  my @unknown = grep { !exists $DEFAULT_COLUMNS{$_} } sort keys %{ $self->columns };
  croak __PACKAGE__.": unknown column key(s) ".join(', ', @unknown) if @unknown;
  return;
}

sub DEMOLISH {
  my ($self, $in_global_destruction) = @_;
  return if $in_global_destruction;
  $self->_teardown;
  return;
}

sub _column {
  my ($self, $key) = @_;
  my $name = $self->columns->{$key};
  return defined $name && length $name ? $name : $DEFAULT_COLUMNS{$key};
}

sub available {
  my ($self) = @_;
  my $dbh = $self->_dbh or return 0;
  return 0 unless $self->_pid == $$;
  return $dbh->{pg_socket} >= 0 ? 1 : 0;
}

sub start {
  my ($self) = @_;
  $self->_use_loop(1);
  $self->_loop_state;
  return;
}

sub lookup_f {
  my ($self, $hash) = @_;
  $hash = lc $hash;
  $self->_use_loop(1);
  my $state = $self->_loop_state;
  return $self->_unavailable_f if $state eq 'down';
  for my $q ( grep { defined } $self->_inflight, @{ $self->_queue } ) {
    next unless $q->{hash} eq $hash;
    my $f = $self->loop->new_future;
    push @{ $q->{futures} }, $f;
    return $f;
  }
  my $f = $self->loop->new_future;
  push @{ $self->_queue }, { hash => $hash, futures => [ $f ] };
  $self->_send_next if $state eq 'up';
  return $f;
}

sub lookup {
  my ($self, $hash) = @_;
  $self->poll;
  my $dbh = $self->_ensure_connected or croak $UNAVAILABLE;
  my $r;
  my $ok = eval { $r = $dbh->selectrow_arrayref( $self->_sql, undef, lc $hash ); 1 };
  unless ($ok) {
    $self->_log_db_error( 'lookup failed', $@ );
    $self->_lost('lookup failed on a closed connection') unless $self->_connection_ok;
    croak $UNAVAILABLE;
  }
  return $self->_row($r);
}

sub poll {
  my ($self) = @_;
  $self->_forget_inherited;
  my $dbh = $self->_dbh or return;
  # At the connection's end the first read may still succeed; the socket
  # then stays readable and the next one fails.
  for ( 1 .. 16 ) {
    my @notes;
    my $ok = eval {
      while ( my $n = $dbh->pg_notifies ) { push @notes, $n }
      1;
    };
    $self->_notified($_) for @notes;
    return $self->_lost('connection closed') unless $ok && $self->_connection_ok;
    last unless @notes || $self->_readable_now;
  }
  return;
}

sub _unavailable_f { Future->fail( $UNAVAILABLE, 'token_store' ) }

sub _row {
  my ($self, $r) = @_;
  return undef unless $r;
  return {
    model    => $r->[0],
    provider => $r->[1],
    expires  => 0 + ( $r->[2] // 0 ),
  };
}

sub _connection_ok {
  my ($self) = @_;
  my $dbh = $self->_dbh or return 0;
  my $state = $dbh->state // '';
  return 0 if $state =~ /^(08|57P0)/;
  return $dbh->{pg_socket} >= 0 ? 1 : 0;
}

#### Connecting

sub _dsn {
  my ($self) = @_;
  my $dsn = $self->dsn;
  my %has = map { lc($_) => 1 } $dsn =~ /([A-Za-z_]+)\s*=/g;
  my @add;
  push @add, 'connect_timeout='.int( $self->connect_timeout )
    if !$has{connect_timeout} && $self->connect_timeout > 0;
  push @add, 'keepalives_idle=30'    unless $has{keepalives_idle};
  push @add, 'keepalives_interval=10' unless $has{keepalives_interval};
  push @add, 'keepalives_count=3'    unless $has{keepalives_count};
  return $dsn unless @add;
  return $dsn.( $dsn =~ /[:;]\z/ ? '' : ';' ).join(';', @add);
}

sub _password {
  my ($self) = @_;
  my $env = $self->password_env;
  return undef unless defined $env && length $env;
  my $password = $ENV{$env};
  $log->warnf('token store: password_env %s is not set', $env)
    unless defined $password;
  return $password;
}

# Under the loop: up, connecting (lookups wait in the queue) or down
# (lookups fail at once). Starts a connect attempt when one is due.
sub _loop_state {
  my ($self) = @_;
  $self->_forget_inherited;
  if ( $self->_dbh ) {
    return 'up' if $self->_connection_ok;
    $self->_lost('connection closed');
    return 'down';
  }
  return 'connecting' if $self->_connecting_f;
  return 'down' if $self->_reconnect_f || time < $self->_next_attempt;
  $self->_start_connect;
  return $self->_dbh ? 'up' : $self->_connecting_f ? 'connecting' : 'down';
}

# The DBI connect blocks, so under the loop it only runs once a
# non-blocking TCP connect to the server got through: a server that is down
# or unreachable costs the loop nothing, only a failed attempt.
sub _start_connect {
  my ($self) = @_;
  weaken( my $weak = $self );
  my $f = $self->_probe_f->then(
    sub {
      return Future->fail("token store gone\n") unless $weak;
      return $weak->_connect ? Future->done : Future->fail("connect failed\n");
    },
    sub {
      return Future->fail("token store gone\n") unless $weak;
      my ( $host, $port ) = $weak->_tcp_target;
      $log->warnf( 'token store: %s port %s not reachable', $host, $port );
      $weak->_retry_later;
      return Future->fail("not reachable\n");
    },
  );
  $self->_connecting_f($f);
  $f->on_ready( sub {
    my ($done) = @_;
    return unless $weak;
    $weak->_clear_connecting_f;
    $done->is_done ? $weak->_send_next : $weak->_fail_pending;
  });
  return;
}

# host and port the DSN connects to over TCP; empty for a Unix socket, a
# service file or a list of hosts, which are not probed.
sub _tcp_target {
  my ($self) = @_;
  my $dsn = $self->dsn;
  $dsn =~ s/\Adbi:Pg:?//i;
  my %p;
  for my $pair ( split /;/, $dsn ) {
    my ( $k, $v ) = $pair =~ /\A\s*([A-Za-z_]+)\s*=\s*(.*?)\s*\z/ or next;
    $p{ lc $k } = $v;
  }
  return if defined $p{service};
  my $host = defined $p{hostaddr} && length $p{hostaddr} ? $p{hostaddr}
           : defined $p{host}     && length $p{host}     ? $p{host}
           : $ENV{PGHOST};
  return unless defined $host && length $host;
  return if $host =~ m{\A/} || $host =~ /,/;
  my $port = $p{port} // $ENV{PGPORT} // 5432;
  return if $port =~ /,/;
  return ( $host, $port );
}

sub _probe_f {
  my ($self) = @_;
  my ( $host, $port ) = $self->_tcp_target;
  return Future->done unless defined $host;
  my $after = $self->connect_timeout > 0 ? $self->connect_timeout : 3;
  return Future->wait_any(
    $self->loop->connect(
      host     => $host,
      service  => $port,
      socktype => 'stream',
    )->then( sub { my ($sock) = @_; close $sock if $sock; Future->done } ),
    $self->loop->timeout_future( after => $after ),
  );
}

sub _ensure_connected {
  my ($self) = @_;
  $self->_forget_inherited;
  if ( $self->_dbh ) {
    return $self->_dbh if $self->_connection_ok;
    $self->_lost('connection closed');
    return;
  }
  return if $self->_reconnect_f;
  return if time < $self->_next_attempt;
  return $self->_connect;
}

# A handle from before a fork belongs to the parent: leave its connection
# alone, drop it here, and invalidate, since this process missed every
# notification since the fork.
sub _forget_inherited {
  my ($self) = @_;
  return unless $self->_dbh && $self->_pid != $$;
  $self->_dbh->{InactiveDestroy} = 1;
  $self->_teardown;
  # the parent's pending lookups: their callbacks would answer its clients
  $self->_clear_inflight;
  @{ $self->_queue } = ();
  $self->_clear_reconnect_f;
  $self->_clear_connecting_f;
  $self->_backoff(0);
  $self->_next_attempt(0);
  $self->invalidate('disconnect');
  return;
}

sub _connect {
  my ($self) = @_;
  my $password = $self->_password;
  my $dbh;
  my $ok = eval {
    $dbh = DBI->connect( $self->_dsn, $self->user, $password, {
      RaiseError          => 1,
      PrintError          => 0,
      PrintWarn           => 0,
      AutoCommit          => 1,
      AutoInactiveDestroy => 1,
    });
    $dbh->do( 'LISTEN '.$dbh->quote_identifier( $self->listen ) );
    1;
  };
  unless ($ok) {
    $self->_log_db_error( 'connect failed', $@, $password );
    eval { $dbh->disconnect } if $dbh;
    $self->_retry_later;
    return;
  }
  $self->_dbh($dbh);
  $self->_pid($$);
  $self->_backoff(0);
  $self->_next_attempt(0);
  $self->_sql( $self->_build_sql($dbh) );
  $self->_watch_socket if $self->_use_loop;
  $log->infof( 'token store: connected, listening on %s', $self->listen );
  return $dbh;
}

sub _build_sql {
  my ($self, $dbh) = @_;
  my ($schema, $name) = $self->relation =~ /\A([^.]+)\.(.+)\z/
    ? ( $1, $2 ) : ( undef, $self->relation );
  my $relation = defined $schema
    ? $dbh->quote_identifier( undef, $schema, $name )
    : $dbh->quote_identifier($name);
  my %c = map { $_ => $dbh->quote_identifier( $self->_column($_) ) } keys %DEFAULT_COLUMNS;
  return 'SELECT '.$c{model}.', '.$c{provider}.', extract(epoch from '.$c{expires}.')'
    .' FROM '.$relation
    .' WHERE '.$c{hash}.' = ? AND '.$c{expires}.' > now()';
}

sub _watch_socket {
  my ($self) = @_;
  weaken( my $weak = $self );
  # A dup of libpq's socket: the watch closes its own descriptor, never
  # libpq's, and still sees the end of the connection.
  open( my $fh, '<&', $self->_dbh->{pg_socket} )
    or return $self->_lost('cannot watch the connection');
  my $watch = IO::Async::Handle->new(
    read_handle   => $fh,
    on_read_ready => sub { $weak->_pump if $weak },
  );
  my $ticker = IO::Async::Timer::Periodic->new(
    interval => 1,
    on_tick  => sub { $weak->_tick if $weak },
  );
  $self->loop->add($watch);
  $self->loop->add($ticker);
  $self->_watch($watch);
  $self->_ticker($ticker);
  return;
}

sub _teardown {
  my ($self) = @_;
  if ( my $watch = $self->_watch ) {
    eval { $watch->close };
    $self->_clear_watch;
  }
  if ( my $ticker = $self->_ticker ) {
    eval { $ticker->stop if $ticker->is_running; $ticker->loop->remove($ticker) if $ticker->loop };
    $self->_clear_ticker;
  }
  if ( my $dbh = $self->_dbh ) {
    $self->_pid == $$ ? eval { $dbh->disconnect } : ( $dbh->{InactiveDestroy} = 1 );
    $self->_clear_dbh;
  }
  return;
}

sub _retry_later {
  my ($self) = @_;
  my $delay = $self->_backoff ? $self->_backoff * 2 : 1;
  $delay = 30 if $delay > 30;
  $self->_backoff($delay);
  $self->_next_attempt( time + $delay );
  return unless $self->_use_loop;
  weaken( my $weak = $self );
  $self->_reconnect_f( $self->loop->delay_future( after => $delay )->on_done( sub {
    return unless $weak;
    $weak->_clear_reconnect_f;
    $weak->_start_connect unless $weak->_dbh || $weak->_connecting_f;
  }));
  $log->infof( 'token store: connecting again in %ds', $delay );
  return;
}

#### Connection loss

sub _lost {
  my ($self, $why) = @_;
  $self->_teardown;
  $log->warnf( 'token store: %s, refusing tokens until it is back', $why );
  $self->invalidate('disconnect');
  $self->_fail_pending;
  $self->_retry_later unless $self->_reconnect_f;
  return;
}

sub _fail_pending {
  my ($self) = @_;
  my @q = grep { defined } $self->_inflight, @{ $self->_queue };
  $self->_clear_inflight;
  @{ $self->_queue } = ();
  for my $f ( map { @{ $_->{futures} } } @q ) {
    $f->fail( $UNAVAILABLE, 'token_store' ) unless $f->is_ready;
  }
  return;
}

#### Queries

sub _send_next {
  my ($self) = @_;
  return if $self->_inflight || !$self->_dbh;
  my $q = shift @{ $self->_queue } or return;
  my $dbh = $self->_dbh;
  my $ok = eval {
    $q->{sth} = $dbh->prepare( $self->_sql, { pg_async => DBD::Pg::PG_ASYNC() } );
    $q->{sth}->execute( $q->{hash} );
    1;
  };
  unless ($ok) {
    my $error = $@;
    $self->_log_db_error( 'lookup failed', $error );
    return $self->_lost('lookup failed on a closed connection')
      unless $self->_connection_ok;
    $q->{failed} = 1;
    $self->_settle($q);
    return $self->_send_next;
  }
  $q->{sent} = time;
  $self->_inflight($q);
  $self->_ticker->start if $self->_ticker && !$self->_ticker->is_running;
  return;
}

# Collects what the socket brought: notifications, the running query's
# result. Every libpq call here reads from the socket, so a pass may leave
# input behind for the other call; passes repeat while they find something
# or the socket stays readable (at its end it stays readable, and the next
# call fails).
sub _pump {
  my ($self) = @_;
  my $dbh = $self->_dbh or return;
  return $self->_forget_inherited if $self->_pid != $$;
  for ( 1 .. 16 ) {
    my ( @notes, $done );
    my $ok = eval {
      while ( my $n = $dbh->pg_notifies ) { push @notes, $n }
      if ( $self->_inflight && $dbh->pg_ready > 0 ) {
        $done = $self->_inflight;
        $self->_clear_inflight;
        $self->_collect($done);
      }
      1;
    };
    # delivered outside the eval: a listener's failure is not the connection's
    $self->_notified($_) for @notes;
    $self->_settle($done) if $done;
    return $self->_lost('connection closed') unless $ok && $self->_connection_ok;
    last unless @notes || $done || $self->_readable_now;
  }
  $self->_send_next;
  return;
}

sub _readable_now {
  my ($self) = @_;
  my $dbh = $self->_dbh or return 0;
  my $fd = $dbh->{pg_socket};
  return 0 unless defined $fd && $fd >= 0;
  my $rin = '';
  vec( $rin, $fd, 1 ) = 1;
  return select( my $rout = $rin, undef, undef, 0 ) > 0 ? 1 : 0;
}

sub _tick {
  my ($self) = @_;
  my $q = $self->_inflight;
  unless ($q) {
    $self->_ticker->stop if $self->_ticker && $self->_ticker->is_running;
    return;
  }
  return $self->_lost('lookup timed out')
    if $self->query_timeout > 0 && time - $q->{sent} > $self->query_timeout;
  $self->_pump;
  return;
}

sub _collect {
  my ($self, $q) = @_;
  my $r;
  my $ok = eval {
    $q->{sth}->pg_result;
    $r = $q->{sth}->fetchrow_arrayref;
    $r = [ @$r ] if $r;
    $q->{sth}->finish;
    1;
  };
  if ($ok) { $q->{row} = $self->_row($r) }
  else {
    $self->_log_db_error( 'lookup failed', $@ );
    $q->{failed} = 1;
  }
  delete $q->{sth};
  return;
}

sub _settle {
  my ($self, $q) = @_;
  for my $f ( @{ $q->{futures} } ) {
    next if $f->is_ready;
    $q->{failed} ? $f->fail( $UNAVAILABLE, 'token_store' ) : $f->done( $q->{row} );
  }
  return;
}

sub _notified {
  my ($self, $n) = @_;
  return unless defined $n->[0] && $n->[0] eq $self->listen;
  $log->debug('token store: notification, invalidating');
  $self->invalidate('notify');
  return;
}

# DBI errors name host, port and user; the password and token hashes must
# not reach even the log.
sub _log_db_error {
  my ($self, $what, $error, $password) = @_;
  my $text = defined $error ? "$error" : 'unknown error';
  $text = ( split /\n/, $text )[0] // '';
  $text =~ s/ at \S+ line \d+\.?\z//;
  $password = $self->_password_quiet unless defined $password;
  $text =~ s/\Q$password\E/***/g if defined $password && length $password;
  $text =~ s/\b[0-9a-fA-F]{64}\b/<hash>/g;
  $log->errorf( 'token store: %s: %s', $what, $text );
  return;
}

sub _password_quiet {
  my ($self) = @_;
  my $env = $self->password_env;
  return defined $env && length $env ? $ENV{$env} : undef;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::TokenStore::Pg - PostgreSQL token store for token_auth, asynchronous under IO::Async

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::TokenStore::Pg;

    my $store = Langertha::Knarr::TokenStore::Pg->new(
        dsn          => 'dbi:Pg:host=db;dbname=platform',
        user         => 'tester_knarr',
        password_env => 'TESTER_DB_PASSWORD',
        relation     => 'citiai_tester_token_auth',   # or schema.view
        listen       => 'citiai_tester_token',
        columns      => { hash => 'token_hash', model => 'model',
                          provider => 'provider', expires => 'expires_at' },
        loop         => $loop,
    );
    $store->on_invalidate( sub { %cache = () } );

    my $row = await $store->lookup_f($hash_hex);   # in the event loop
    my $row = $store->lookup($hash_hex);           # blocking (PSGI)

=head1 DESCRIPTION

The L<Langertha::Knarr::TokenStore> of C<token_auth> with
C<backend: postgresql>. It looks a token hash up in a table or view the
platform that issues the tokens owns, read-only:

    SELECT <model>, <provider>, extract(epoch from <expires>)
      FROM <relation> WHERE <hash> = $1 AND <expires> > now()

The relation (C<schema.view> or a bare name; a dot separates the schema)
and the column names are quoted as identifiers, so they are taken as they
are written, case included. The hash column holds the lowercase hex SHA-256
of the token; the expiry column should be a C<timestamptz>.

The store C<LISTEN>s on L</listen>. Every notification on that channel --
the platform sends one when it issues or revokes a token -- and every loss
of the connection calls L<Langertha::Knarr::TokenStore/on_invalidate>, so
the caller's cache never outlives a revocation it could not see.

DBD::Pg is an optional dependency of Knarr. Constructing this store without
it croaks C<token_auth backend postgresql needs DBD::Pg>, so C<knarr start>
fails at once instead of on the first request.

=head2 Asynchronous queries

A lookup sits in the path of every request whose token is not cached, so
it must not stop the event loop while the database answers. The store uses
DBD::Pg's own asynchronous mode: the query is sent with
C<< pg_async => PG_ASYNC >> and returns at once, and the connection's
socket (C<pg_socket>) is watched by an L<IO::Async::Handle>. When it turns
readable the store collects the result (C<pg_ready>, C<pg_result>) and the
notifications (C<pg_notifies>) without waiting. The same watch delivers
C<NOTIFY> the moment it arrives -- a revocation reaches the cache without
any polling -- and it sees the connection end the moment the server closes
it.

The alternatives were worse for this job. A forked helper process with a
blocking DBI handle needs its own protocol and process supervision, and it
would sit between the C<LISTEN> and the cache, delaying every
invalidation. A blocking query in the loop stops every request of the
worker, streaming ones included, for as long as the database takes. The
asynchronous mode keeps one connection per serving process, under the loop
the server already runs.

One connection runs one asynchronous query at a time, so lookups wait in a
queue; a lookup for a hash already queued or running joins that query
instead of sending its own. A query that takes longer than
L</query_timeout> counts as a lost connection.

DBD::Pg has no asynchronous connect, and a DBI connect to a server that is
down or unreachable would stop the loop for its whole timeout -- on every
reconnect attempt, with streams running. Under the loop the store
therefore first opens a plain TCP connection to the DSN's C<host>
(C<hostaddr>, else C<PGHOST>) and C<port> (else C<PGPORT>, else C<5432>)
through the loop, without blocking, for at most L</connect_timeout>
seconds. Only when that gets through does it call C<< DBI->connect >>; a
failed probe is a failed attempt and goes to the backoff without any DBI
call. Lookups that arrive while an attempt runs wait for it; lookups during
the backoff fail at once. The probe connection is closed right away (the
server may log it as an incomplete startup packet). A DSN without a TCP
host -- a Unix socket directory, C<service=>, a list of hosts -- is not
probed: its connect blocks the loop for up to L</connect_timeout>.

The DSN gets C<connect_timeout> (L</connect_timeout>) and TCP keepalives
(C<keepalives_idle=30>, C<keepalives_interval=10>, C<keepalives_count=3>)
unless it sets them itself, so neither the connect after a probe nor an
idle connection to a vanished server hangs for longer than that.

=head2 Connection loss and processes

The connection is opened by L</start> -- which L<Langertha::Knarr> calls in
the process that serves -- or else by the first lookup: with C<workers> above 1 every worker opens its own
connection and C<LISTEN>. A connection inherited across a C<fork> is
noticed by the process id, left to its owner untouched (C<InactiveDestroy>)
and replaced; the caller's cache is invalidated then too, since the
notifications since the fork went to the other process.

When the connection is lost (the server closes it, a query fails with a
connection error, L</query_timeout>), the store is not L</available>, calls
the invalidate listener with C<disconnect>, fails every queued lookup and
connects again after 1, 2, 4, ... seconds, at most 30, with a new
C<LISTEN>. Until then every lookup fails at once.

=head2 Secrets

The password is read from the environment variable named by
L</password_env> at every connect and is never stored, logged or put in an
error. A failed lookup fails with the fixed text
C<token store unavailable>; database errors (which name the host and user)
go only to the log, first line only, with the password and any token hash
masked.

=head2 dsn

Required. The DBI data source, C<dbi:Pg:...>.

=head2 user

Optional database user.

=head2 password_env

Optional name of the environment variable that holds the database
password. Without it libpq's own sources (C<.pgpass>, C<PGPASSWORD>) apply.

=head2 relation

Required. The table or view to look tokens up in, C<name> or
C<schema.name>.

=head2 listen

Required. The channel to C<LISTEN> on; every notification on it
invalidates.

=head2 columns

HashRef of the column names, C<hash>, C<model>, C<provider>, C<expires>.
Missing entries default to C<token_hash>, C<model>, C<provider>,
C<expires_at>.

=head2 loop

Optional L<IO::Async::Loop> for L</lookup_f>. Defaults to
C<< IO::Async::Loop->new >>.

=head2 connect_timeout

Seconds a connect may take: the non-blocking TCP probe under the loop,
and libpq's C<connect_timeout> (libpq takes at least 2). Default C<3>. A
C<connect_timeout> in the DSN wins for libpq; the probe still uses this
value.

=head2 query_timeout

Seconds an asynchronous lookup may take before the connection counts as
lost. Default C<10>.

=head2 available

True while the store has a connection of this process with its C<LISTEN>
in place. False before the first connect: L</lookup_f> and L</lookup>
connect then, so a caller must not refuse on this alone before it asked.

=head2 start

    $store->start;

Starts a connect attempt (probe, then connect; see
L</Asynchronous queries>) when there is no connection and no reconnect is
pending, and switches the store to the loop: from then on its socket is
watched and a lost connection is retried by a timer. It returns before the
attempt is done. A second call while connected, connecting or waiting to
reconnect does nothing. L<Langertha::Knarr> calls it (through
L<Langertha::Knarr::Authorizer::Token/start>) in every process that serves,
once its loop is set up; without that the first L</lookup_f> does the same.

=head2 lookup_f

    my $row = await $store->lookup_f($hash_hex);

See L<Langertha::Knarr::TokenStore/lookup_f>. Fails with
C<token store unavailable> while there is no connection, after a database
error and when the connection is lost before the answer.

=head2 lookup

    my $row = $store->lookup($hash_hex);

Blocking, for L<Langertha::Knarr::PSGI>: delivers pending notifications
first (as L</poll>), then queries. It connects without the TCP probe, so a
connect may block for up to L</connect_timeout>. Croaks C<token store unavailable> on any
store error. Without a loop a lost connection is retried by the next lookup
once the backoff has passed. A store serves either the loop (L</lookup_f>)
or blocking callers, not both.

=head2 poll

    $store->poll;

Delivers the notifications that have arrived without waiting, and notices
a closed connection. A blocking caller calls it before it trusts its cache;
under the loop the socket watch does this by itself.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
