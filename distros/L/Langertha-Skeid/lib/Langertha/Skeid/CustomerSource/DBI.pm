package Langertha::Skeid::CustomerSource::DBI;
our $VERSION = '0.004';
# ABSTRACT: Customer source fetcher on DBI - connect and query in a child process, LISTEN in another
use Moo;
use strict;
use warnings;
use IO::Select;
use POSIX qw(ceil);
use Scalar::Util qw(weaken);
use Mojo::IOLoop;
use Langertha::Skeid::CustomerSource;


has config => (is => 'ro', required => 1);

has _fetch_sub    => (is => 'rw');
has _fetch_timer  => (is => 'rw');
has _listener     => (is => 'rw');
has _listen_timer => (is => 'rw');
has _notify       => (is => 'rw');
has _pid          => (is => 'rw', default => sub { 0 });

# What a child may overrun its connect timeout by before the parent kills it.
our $KILL_MARGIN_S = 2;


sub statement {
  my ($self) = @_;
  return Langertha::Skeid::CustomerSource->statement($self->config->{relation});
}


sub dsn {
  my ($self) = @_;
  my $dsn = $self->config->{dsn};
  return $dsn unless $dsn =~ /\Adbi:Pg:/i;
  return $dsn if $dsn =~ /\bconnect_timeout=/i;
  my $seconds = ceil($self->config->{connect_timeout_s} // 5);
  $seconds = 2 if $seconds < 2;
  return $dsn . ($dsn =~ /[:;]\z/ ? '' : ';') . "connect_timeout=$seconds";
}


sub fetch {
  my ($self, $cb) = @_;
  $self->_drop_foreign;
  $self->_kill_fetch;
  $self->_listen unless $self->_listener;

  my $sql = $self->statement;
  my $cfg = $self->config;
  my $dsn = $self->dsn;
  my $ms  = int(1000 * ($cfg->{connect_timeout_s} // 5));
  my %conn = (dsn => $dsn, user => $cfg->{user}, password => $cfg->{password});

  my $sub = Mojo::IOLoop->subprocess;
  $self->_fetch_sub($sub);
  my $done = 0;
  weaken(my $weak = $self);

  my $limit = ($cfg->{connect_timeout_s} // 5) + $KILL_MARGIN_S;
  $self->_fetch_timer(Mojo::IOLoop->timer($limit => sub {
    return unless $weak && !$done;
    $done = 1;
    $weak->_fetch_timer(undef);
    $weak->_kill($sub);
    $weak->_fetch_sub(undef);
    $cb->('fetch child overran its deadline and was killed');
  }));

  $sub->run(
    sub { return _query(\%conn, $sql, $ms) },
    sub {
      my ($sp, $err, $rows) = @_;
      return if $done;
      $done = 1;
      if ($weak) {
        my $t = $weak->_fetch_timer;
        Mojo::IOLoop->remove($t) if defined $t;
        $weak->_fetch_timer(undef);
        $weak->_fetch_sub(undef);
      }
      # Mojo passes '' for no error.
      return $cb->(_scrub($err, $conn{password})) if defined($err) && length("$err");
      return $cb->('the fetch returned no rows list') unless ref($rows) eq 'ARRAY';
      return $cb->(undef, $rows);
    },
  );
  return;
}


sub on_notify {
  my ($self, $cb) = @_;
  $self->_notify($cb);
  return;
}


sub release {
  my ($self) = @_;
  $self->_kill_fetch;
  my $timer = $self->_listen_timer;
  Mojo::IOLoop->remove($timer) if defined $timer;
  $self->_listen_timer(undef);
  if (my $l = $self->_listener) {
    $self->_listener(undef);   # first: its finish callback sees it was released on purpose
    $self->_kill($l);
  }
  return;
}

sub _kill_fetch {
  my ($self) = @_;
  my $timer = $self->_fetch_timer;
  Mojo::IOLoop->remove($timer) if defined $timer;
  $self->_fetch_timer(undef);
  if (my $sub = $self->_fetch_sub) {
    $self->_fetch_sub(undef);
    $self->_kill($sub);
  }
  return;
}

sub _kill {
  my ($self, $sub) = @_;
  my $pid = eval { $sub->pid };
  kill 'KILL', $pid if $pid && $self->_pid == $$;
  return;
}

# Children belong to the process that started them: after a fork the parent's are not ours to
# kill or wait on, and the objects are forgotten.
sub _drop_foreign {
  my ($self) = @_;
  if ($self->_pid != $$) {
    $self->_fetch_sub(undef);
    $self->_fetch_timer(undef);
    $self->_listener(undef);
    $self->_listen_timer(undef);
    $self->_pid($$);
  }
  return;
}

sub _scrub {
  my ($text, $password) = @_;
  $text = "$text";
  $text =~ s/\Q$password\E/***/g if defined($password) && length($password);
  $text =~ s/\b(password|pwd)=[^;'"\s)]*/$1=***/gi;
  $text =~ s/\s+/ /g;
  $text =~ s/\s+\z//;
  return length($text) ? $text : 'fetch failed';
}

# --- the child: blocking, never on the loop's process ----------------------------------------

sub _connect {
  my ($conn) = @_;
  require DBI;
  return DBI->connect($conn->{dsn}, $conn->{user} // '', $conn->{password} // '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
}

sub _query {
  my ($conn, $sql, $ms) = @_;
  my $dbh = _connect($conn);
  my $rows = eval {
    $dbh->do("SET statement_timeout = $ms") if $conn->{dsn} =~ /\Adbi:Pg:/i;
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @out;
    while (my $row = $sth->fetchrow_hashref) {
      push @out, { map { $_ => (ref($row->{$_}) eq 'ARRAY' ? [ @{ $row->{$_} } ] : $row->{$_}) }
        keys %$row };
    }
    \@out;
  };
  my $err = $@;
  eval { $dbh->disconnect };
  die $err unless $rows;
  return $rows;
}

# --- the listener -----------------------------------------------------------------------------

sub _listen {
  my ($self) = @_;
  my $channel = $self->config->{listen};
  return unless defined($channel) && length($channel);

  my %conn = (dsn => $self->dsn, user => $self->config->{user}, password => $self->config->{password});
  my $sub = Mojo::IOLoop->subprocess;
  $self->_listener($sub);
  weaken(my $weak = $self);
  my $parent = $$;
  my $ready  = 0;

  $sub->on(progress => sub {
    my ($sp, $msg) = @_;
    return unless $weak && ($weak->_listener // 0) == $sub;
    if (($msg // '') eq 'ready') {
      $ready = 1;
    } elsif (($msg // '') eq 'notify') {
      my $cb = $weak->_notify;
      $cb->() if $cb;
    }
  });

  # A listener that never got as far as LISTEN is a blocked connect: killed like a fetch.
  my $limit = ($self->config->{connect_timeout_s} // 5) + $KILL_MARGIN_S;
  my $kill = Mojo::IOLoop->timer($limit => sub {
    return unless $weak && !$ready && ($weak->_listener // 0) == $sub;
    $weak->_kill($sub);
  });

  $sub->run(
    sub {
      my ($sp) = @_;
      my $dbh = _connect(\%conn);
      $dbh->do('LISTEN ' . $channel);
      $sp->progress('ready');
      my $select = IO::Select->new;
      open(my $sock, '<&=', $dbh->{pg_socket}) or die "no socket to wait on\n";
      $select->add($sock);
      while (getppid() == $parent) {
        $select->can_read(2);
        my $n = 0;
        $n++ while $dbh->pg_notifies;
        $sp->progress('notify') if $n;
      }
      eval { $dbh->disconnect };
      return 1;
    },
    sub {
      my ($sp, $err) = @_;
      Mojo::IOLoop->remove($kill);
      return unless $weak;
      # Released on purpose: _listener was cleared first. Otherwise it ended by itself, and the
      # next fetch starts it again; the poll carries on meanwhile.
      $weak->_listener(undef) if ($weak->_listener // 0) == $sub;
    },
  );
  return;
}

sub DEMOLISH {
  my ($self, $global) = @_;
  return if $global;
  $self->release;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::CustomerSource::DBI - Customer source fetcher on DBI - connect and query in a child process, LISTEN in another

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  my $fetcher = Langertha::Skeid::CustomerSource::DBI->new(config => $normalized_section);
  $fetcher->on_notify(sub { ... });          # with config listen: a NOTIFY arrived
  $fetcher->fetch(sub {
    my ($err, $rows) = @_;                   # rows: [ { key_id, name, policy, models }, ... ]
  });
  $fetcher->release;                         # kill the children; the next fetch starts new ones

=head1 DESCRIPTION

The fetcher L<Langertha::Skeid> uses for a C<customer_source> section unless it was given
another (L<Langertha::Skeid/customer_source_fetcher>). It runs
L<Langertha::Skeid::CustomerSource/statement> through plain, blocking L<DBI> and
L<DBD::Pg> -- B<in a child process> (L<Mojo::IOLoop/subprocess>), never on the event loop:
DBD::Pg has no non-blocking connect, and a connect that blocks the loop stalls every stream in
flight in the worker for up to C<connect_timeout_s> (ADR 0026, k109). The parent sees only the
finished rows, or an error.

Each fetch forks a child that connects, runs the statement, disconnects and returns the rows.
The connection is the child's alone: no handle is shared with the parent, with the usage store
or with another fetch, so a fork of the prefork manager cannot inherit one. libpq's
C<connect_timeout> (whole seconds, at least 2) and a C<statement_timeout> of
C<connect_timeout_s> bound the child itself, and the parent kills a child that overran its
deadline -- the loop's own timeout (L<Langertha::Skeid::CustomerSource/fetch_now>) already
answered the caller by then.

With C<listen> in the config, a second, long-lived child connects, C<LISTEN>s on that channel
and reports every notification to the parent; the payload is ignored. It is started with the
first fetch in the process, and again with each fetch until it ran. A notification lost while
it is down costs nothing: the poll is the floor.

DBI and the driver are loaded in the child, when a fetch runs: building the object loads
neither.

=head2 config

The normalized C<customer_source> section (L<Langertha::Skeid::CustomerSource/normalize_config>).
Required.

=head2 statement

The statement every fetch runs, from L<Langertha::Skeid::CustomerSource/statement>.

=head2 dsn

The DSN the connection uses: the configured one, with C<connect_timeout> added to a PostgreSQL
DSN unless it names one.

=head2 fetch

  $fetcher->fetch(sub { my ($err, $rows) = @_; ... });

Forks a child that runs the statement and calls back with the rows as hashes, C<models> as an
array reference, or with the error. A connection that cannot be opened is an error too. The
error carries no password.

=head2 on_notify

  $fetcher->on_notify(sub { ... });

The callback for a notification on the configured C<listen> channel. Without C<listen> it is
never called.

=head2 release

Kills the fetch child and the listener, if any. The next fetch starts new ones. C<skeid serve>
calls it before the prefork manager forks.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid::CustomerSource> -- the fetcher contract, the row contract, the loop

=item * L<Langertha::Skeid/customer_source>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

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
