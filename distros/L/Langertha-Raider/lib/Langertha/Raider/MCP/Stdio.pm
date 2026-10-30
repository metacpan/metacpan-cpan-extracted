package Langertha::Raider::MCP::Stdio;
# ABSTRACT: Internal JSON-RPC over the stdin and stdout of an MCP server process
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Encode qw( decode );
use Future;
use IO::Async::Process;
use JSON::MaybeXS ();
use POSIX ();
use Scalar::Util qw( weaken );


has loop    => ( is => 'ro', required => 1 );
has command => ( is => 'ro', isa => 'Str', required => 1 );
has args    => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has env     => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has cwd     => ( is => 'ro', isa => 'Str', required => 1 );

has stderr_lines => ( is => 'ro', isa => 'Int', default => 20 );
has kill_grace   => ( is => 'ro', isa => 'Num', default => 2 );
has on_request   => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has on_exit      => ( is => 'ro', isa => 'Maybe[CodeRef]' );
has on_notification => ( is => 'ro', isa => 'Maybe[CodeRef]' );

has _process  => ( is => 'rw', init_arg => undef );
has _pending  => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _next_id  => ( is => 'rw', init_arg => undef, default => 0 );
has _stdout   => ( is => 'rw', init_arg => undef, default => '' );
has _errbuf   => ( is => 'rw', init_arg => undef, default => '' );
has _stderr   => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _exit_f   => ( is => 'rw', init_arg => undef );
has _closing  => ( is => 'rw', init_arg => undef, default => 0 );
has _kill_timer => ( is => 'rw', init_arg => undef );


has exited => ( is => 'ro', init_arg => undef, writer => '_set_exited' );

sub _json { JSON::MaybeXS->new( utf8 => 1, canonical => 1, convert_blessed => 1 ) }


sub start {
  my ( $self ) = @_;
  croak __PACKAGE__.'->start: already started' if $self->_exit_f;
  my $loop = $self->loop;
  $self->_exit_f($loop->new_future);
  my %env  = %{ $self->env };
  my $cwd  = $self->cwd;
  my @argv = ( $self->command, @{ $self->args } );
  weaken( my $weak = $self );
  my $process = eval {
    IO::Async::Process->new(
      code => sub {
        POSIX::setsid();
        chdir $cwd or do { print STDERR "cannot chdir to $cwd: $!\n"; return 127 };
        %ENV = %env;
        { no warnings 'exec'; exec { $argv[0] } @argv; }
        print STDERR 'cannot run '.$argv[0].': '.$!."\n";
        return 127;
      },
      stdin  => { via => 'pipe_write' },
      stdout => { on_read => sub { my ( undef, $buf, $eof ) = @_; $weak->_read_stdout($buf) if $weak; return 0 } },
      stderr => { on_read => sub { my ( undef, $buf, $eof ) = @_; $weak->_read_stderr($buf, $eof) if $weak; return 0 } },
      on_finish    => sub { $weak->_finished($_[1]) if $weak },
      on_exception => sub { my ( undef, $e, undef, $status ) = @_; $weak->_finished($status // 127 << 8, $e) if $weak },
    );
  };
  unless ($process) {
    $self->_finished(127 << 8, 'cannot start: '.( split /\n/, $@ )[0]);
    return;
  }
  $loop->add($process);
  $self->_process($process);
  return;
}


sub pid {
  my ( $self ) = @_;
  my $p = $self->_process or return;
  return $p->pid;
}


sub is_running { $_[0]->_exit_f && !$_[0]->exited ? 1 : 0 }


sub request_f {
  my ( $self, $method, $params ) = @_;
  return Future->fail($self->_gone_text) unless $self->is_running;
  my $id = $self->_next_id + 1;
  $self->_next_id($id);
  my $f = $self->loop->new_future;
  $self->_pending->{$id} = $f;
  weaken( my $weak = $self );
  $f->on_cancel(sub {
    my $self = $weak or return;
    delete $self->_pending->{$id};
    $self->notify('notifications/cancelled', { requestId => $id, reason => 'cancelled by raider' }) if $self->is_running;
  });
  $self->_write({ jsonrpc => '2.0', id => $id, method => $method, ( defined $params ? ( params => $params ) : () ) });
  return $f;
}


sub notify {
  my ( $self, $method, $params ) = @_;
  return unless $self->is_running;
  $self->_write({ jsonrpc => '2.0', method => $method, ( defined $params ? ( params => $params ) : () ) });
  return;
}

sub _write {
  my ( $self, $message ) = @_;
  my $stdin = $self->_process ? $self->_process->stdin : undef;
  return unless $stdin;
  $stdin->write($self->_json->encode($message)."\n");
  return;
}

sub _read_stdout {
  my ( $self, $buf ) = @_;
  my $data = $self->_stdout.$$buf;
  $$buf = '';
  while ($data =~ s/\A([^\n]*)\n//) {
    my $line = $1;
    next unless $line =~ /\S/;
    my $msg = eval { $self->_json->decode($line) };
    next unless ref $msg eq 'HASH';
    $self->_message($msg);
  }
  $self->_stdout($data);
  return;
}

sub _message {
  my ( $self, $msg ) = @_;
  if (defined $msg->{method}) {
    if (defined $msg->{id}) { $self->_answer($msg) }
    elsif (my $cb = $self->on_notification) { eval { $cb->($msg->{method}, $msg->{params} // {}) } }
    return;
  }
  my $id = $msg->{id};
  return unless defined $id && !ref $id;
  my $f = delete $self->_pending->{$id} or return;
  return if $f->is_ready;
  if (ref $msg->{error} eq 'HASH') {
    my $e = $msg->{error};
    $f->fail('MCP error '.( $e->{code} // '?' ).': '.( $e->{message} // 'unknown error' ), mcp => $e);
  }
  else {
    $f->done($msg->{result});
  }
  return;
}

# A request from the server: on_request decides, else ping -> {} and every
# other method is not found.
sub _answer {
  my ( $self, $msg ) = @_;
  my ( $method, $id ) = @{$msg}{qw( method id )};
  my %reply = ( jsonrpc => '2.0', id => $id );
  if (my $cb = $self->on_request) {
    my $result = eval { $cb->($method, $msg->{params} // {}) };
    if (my $err = $@) { $reply{error} = { code => -32603, message => ''.( split /\n/, $err )[0] } }
    else              { $reply{result} = $result // {} }
  }
  elsif ($method eq 'ping') {
    $reply{result} = {};
  }
  else {
    $reply{error} = { code => -32601, message => 'Method not found: '.$method };
  }
  $self->_write(\%reply);
  return;
}

sub _read_stderr {
  my ( $self, $buf, $eof ) = @_;
  my $data = $self->_errbuf.$$buf;
  $$buf = '';
  my @lines = split /\n/, $data, -1;
  $data = $eof ? '' : pop @lines;
  $self->_errbuf($data);
  my $keep = $self->_stderr;
  for my $line (@lines) {
    $line = decode('UTF-8', $line);
    $line =~ s/\s+\z//;
    next unless length $line;
    $line = substr($line, 0, 500).'...' if length $line > 500;
    push @$keep, $line;
    shift @$keep while @$keep > $self->stderr_lines;
  }
  return;
}


sub stderr_tail {
  my ( $self ) = @_;
  my @lines = @{ $self->_stderr };
  my $rest = $self->_errbuf;
  push @lines, decode('UTF-8', $rest) =~ s/\s+\z//r if length $rest && $rest =~ /\S/;
  return @lines;
}

sub _finished {
  my ( $self, $status, $error ) = @_;
  return if $self->exited;
  $self->_set_exited({ code => $status >> 8, signal => $status & 127, error => $error });
  for my $id (sort keys %{ $self->_pending }) {
    my $f = delete $self->_pending->{$id};
    $f->fail($self->_gone_text) unless $f->is_ready;
  }
  $self->_exit_f->done($self->exited) if $self->_exit_f && !$self->_exit_f->is_ready;
  $self->on_exit->($self->exited) if $self->on_exit;
  return;
}


sub exit_text {
  my ( $self ) = @_;
  my $x = $self->exited or return;
  return $x->{error} if defined $x->{error} && !$self->_closing;
  return 'killed by signal '.$x->{signal} if $x->{signal};
  return 'exited with code '.$x->{code};
}

sub _gone_text {
  my ( $self ) = @_;
  return 'MCP server process has not been started' unless $self->_exit_f;
  return 'MCP server process '.( $self->exit_text // 'has exited' );
}


sub stop_f {
  my ( $self ) = @_;
  return Future->done unless $self->_exit_f;
  return $self->_exit_f->without_cancel if $self->exited || $self->_closing;
  $self->_closing(1);
  my $process = $self->_process;
  eval { $process->stdin->close_when_empty } if $process && $process->stdin;
  my $loop = $self->loop;
  my $grace = $self->kill_grace;
  my $pid = $self->pid;
  my $exit = $self->_exit_f;
  $self->_kill_timer($loop->delay_future( after => $grace )->then(sub {
    return Future->done if $exit->is_ready;
    kill 'TERM', -$pid if $pid;
    return $loop->delay_future( after => $grace );
  })->then(sub {
    kill 'KILL', -$pid if $pid && !$exit->is_ready;
    return Future->done;
  }));
  return $exit->without_cancel;
}


sub kill_now {
  my ( $self ) = @_;
  return unless $self->is_running;
  my $pid = $self->pid or return;
  kill 'KILL', -$pid;
  return;
}

sub DEMOLISH {
  my ( $self, $global ) = @_;
  $self->kill_now;
  if (my $t = $self->_kill_timer) { $t->cancel unless $t->is_ready }
  my $p = $self->_process;
  eval { $p->loop->remove($p) } if !$global && $p && $p->loop;
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::Stdio - Internal JSON-RPC over the stdin and stdout of an MCP server process

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $wire = Langertha::Raider::MCP::Stdio->new(
      loop    => $loop,
      command => 'npx',
      args    => [ '-y', '@bytebase/dbhub' ],
      env     => \%child_env,          # the whole environment of the process
      cwd     => $root,
    );
    $wire->start;
    my $result = await $wire->request_f( 'initialize', { ... } );
    $wire->notify( 'notifications/initialized' );
    my @last = $wire->stderr_tail;
    await $wire->stop_f;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The stdio transport of a configured MCP server (ADR 0029 E<sect>10): the
process runs in its own session (C<setsid>, no terminal, so a Ctrl-C of
the REPL does not reach it), in L</cwd>, with exactly L</env> as its
environment; JSON-RPC messages are lines on its stdin and stdout. Its
stderr never reaches raider's terminal: the last L</stderr_lines> lines are
kept for the status report (L</stderr_tail>). Lines on stdout that are not
JSON are ignored.

A request the server sends (C<ping>, C<roots/list>, ...) is answered by
L</on_request>; without one, C<ping> gets an empty result and every other
method "Method not found". Notifications from the server are ignored.

Written for raider because the installed
L<Net::Async::MCP::Transport::Stdio> takes only a C<command>: no
environment, no working directory, and it throws stderr away.

=head2 loop

The L<IO::Async::Loop> the process runs on. Required.

=head2 command

The program, looked up on C<PATH> by C<exec>. Required.

=head2 args

Its arguments. Default none.

=head2 env

The whole environment of the process. Default empty.

=head2 cwd

Its working directory. Required.

=head2 stderr_lines

How many lines of stderr L</stderr_tail> keeps. Default 20.

=head2 kill_grace

Seconds L</stop_f> waits after closing stdin before C<TERM>, and again
before C<KILL>. Default 2.

=head2 on_request

C<< sub { my ( $method, $params ) = @_; return $result } >> for requests
the server sends; dying answers with an error. Optional.

=head2 on_notification

C<< sub { my ( $method, $params ) = @_; ... } >>, called for every
notification the server sends (C<notifications/tools/list_changed>, ...).
Optional.

=head2 on_exit

C<< sub { my ( $exit_info ) = @_; ... } >>, called once when the process
has ended (see L</exited>). Optional.

=head2 exited

C<undef> while the process runs (or before L</start>), then
C<< { code => N, signal => N, error => '...' | undef } >>.

=head2 start

Starts the process. A program that cannot be run ends right away with exit
code 127 and the reason on stderr, as a shell would.

=head2 pid

The process id (also its process group), or C<undef>.

=head2 is_running

True between L</start> and the end of the process.

=head2 request_f

    my $result = await $wire->request_f( 'tools/call', { name => 'x', arguments => {} } );

Sends a request; the future is done with its C<result>, or fails with
C<MCP error CODE: MESSAGE> (category C<mcp>, the error object as detail),
or with C<MCP server exited ...> when the process ends first. Cancelling
the future sends C<notifications/cancelled>.

=head2 notify

    $wire->notify( 'notifications/initialized' );

Sends a notification; nothing when the process is gone.

=head2 stderr_tail

The last lines the process wrote to stderr (at most L</stderr_lines>,
each cut at 500 characters).

=head2 exit_text

How the process ended, as a phrase: C<exited with code 1>, C<killed by
signal 9>, C<cannot start: ...>; C<undef> while it runs.

=head2 stop_f

    await $wire->stop_f;

Ends the process the way the MCP specification asks: closes its stdin,
sends C<TERM> to its process group after L</kill_grace> seconds, C<KILL>
after as many again. Done when it has exited.

=head2 kill_now

Sends C<KILL> to the process group at once (when the object goes away, or
the program ends, before L</stop_f> could finish).

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP::Server>

=item * L<Langertha::Raider::MCP::HTTP>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

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

L<https://raudssus.de/>

=cut
