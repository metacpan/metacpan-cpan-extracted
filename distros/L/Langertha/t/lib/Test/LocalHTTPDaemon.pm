package Test::LocalHTTPDaemon;
# Forked HTTP::Daemon on 127.0.0.1 for exercising a real LWP::UserAgent /
# Net::Async::HTTP against canned responses — no live provider calls.
#
#   my $server = Test::LocalHTTPDaemon->start(sub { my ($request) = @_; return $http_response });
#   my $base   = $server->url;   # http://127.0.0.1:PORT (no trailing slash)
#
# Every response is sent with "Connection: close" (a raw response has to carry
# that header itself), so a keep-alive client (Net::Async::HTTP) never pins the
# single-threaded daemon between tests, nor reuses a connection the daemon has
# already hung up on. A response whose content is a CODE ref is sent chunked (HTTP::Daemon), one
# chunk per call until it returns an empty string/undef. A handler that returns
# a plain string instead of an HTTP::Response has it written verbatim, in one
# write, as the complete raw response (status line, headers and framed body):
# the way to control exactly which bytes reach the client in a single read.
#
#   my $server = Test::LocalHTTPDaemon->start($handler, keep_alive => 1);
#   $server->connection_count;   # TCP connections accepted so far
#
# keep_alive => 1 leaves connections open instead: no "Connection: close" is
# added (a raw response must not carry one either) and every connection is
# served by its own forked child, so a client holding a connection open does
# not pin the daemon. This is the mode for connection reuse and HTTP/1.1
# pipelining (Net::Async::HTTP only pipelines on a keep-alive connection).
#
# A handler that dies ends the process that ran it (the daemon in the default
# mode, the connection child in keep-alive mode) with a warning; the client
# sees the connection close. Destroying the server object kills and reaps the
# daemon and every connection child.

use strict;
use warnings;

use HTTP::Daemon;
use File::Temp ();
use POSIX ();

sub start {
  my ( $class, $handler, %opts ) = @_;
  my $keep_alive = $opts{keep_alive};
  my $conn_log   = File::Temp->new;   # one line per accepted connection
  my $daemon = Test::LocalHTTPDaemon::Listener->new( LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1 )
    or die "cannot start HTTP::Daemon: $!";
  my $url = $daemon->url;
  $url =~ s{/\z}{};

  my $pid = fork;
  die "fork failed: $!" unless defined $pid;
  if ( !$pid ) {
    # Nothing may unwind out of start() in a forked process: it would run the
    # rest of the test script as a clone. A handler that dies ends the process.
    my $ok = eval { _serve( $daemon, $handler, $keep_alive, $conn_log->filename ); 1 };
    warn "Test::LocalHTTPDaemon: $@" unless $ok;
    POSIX::_exit( $ok ? 0 : 1 );   # skip END blocks (Test2) in the child
  }

  close $daemon;
  return bless { pid => $pid, url => $url, conn_log => $conn_log }, $class;
}

# Runs in the daemon process. In keep-alive mode each connection gets its own
# forked child. Children are reaped in the accept loop, not in a SIGCHLD
# handler, so %children only changes synchronously and never names a pid that
# is already reaped (and so free for reuse). SIGTERM is blocked from that reap
# through the fork until the child is recorded, so teardown kills and reaps
# every child.
sub _serve {
  my ( $daemon, $handler, $keep_alive, $conn_log ) = @_;
  $SIG{PIPE} = 'IGNORE';
  my %children;
  my $term = POSIX::SigSet->new( POSIX::SIGTERM() );
  my $reap = sub { kill 'TERM', keys %children; waitpid $_, 0 for keys %children };
  $SIG{TERM} = sub { $reap->(); POSIX::_exit(0) } if $keep_alive;
  my $ok = eval {
    while ( my $conn = $daemon->accept ) {
      if ( open my $log, '>>', $conn_log ) { print {$log} "conn\n"; close $log }
      if ($keep_alive) {
        POSIX::sigprocmask( POSIX::SIG_BLOCK(), $term );
        while ( ( my $done = waitpid( -1, POSIX::WNOHANG() ) ) > 0 ) { delete $children{$done} }
        my $child = fork;
        die "fork failed: $!" unless defined $child;
        if ( !$child ) {
          $SIG{TERM} = 'DEFAULT';
          POSIX::sigprocmask( POSIX::SIG_UNBLOCK(), $term );
          close $daemon;   # only the daemon listens
          my $served = eval {
            while ( my $request = $conn->get_request ) {
              my $response = $handler->($request);
              if ( ref $response ) { $conn->send_response($response) }
              else                 { print {$conn} $response }
            }
            1;
          };
          warn "Test::LocalHTTPDaemon: $@" unless $served;
          POSIX::_exit( $served ? 0 : 1 );
        }
        $children{$child} = 1;
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK(), $term );
        close $conn;
        next;
      }
      while ( my $request = $conn->get_request ) {
        $conn->force_last_request;
        my $response = $handler->($request);
        # force_last_request only makes the daemon hang up; the header is what
        # tells the client not to reuse the connection.
        if ( ref $response ) { $response->header( Connection => 'close' ); $conn->send_response($response) }
        else                 { print {$conn} $response }
      }
      $conn->close;
    }
    1;
  };
  my $err = $@;
  POSIX::sigprocmask( POSIX::SIG_BLOCK(), $term );
  $reap->();
  die $err unless $ok;
  return;
}

sub url { $_[0]->{url} }

sub connection_count {
  my ($self) = @_;
  open my $fh, '<', $self->{conn_log}->filename or return 0;
  my @lines = <$fh>;
  return scalar @lines;
}

sub DESTROY {
  my ($self) = @_;
  return unless $self->{pid};
  kill 'TERM', $self->{pid};
  waitpid $self->{pid}, 0;
}

# HTTP::Daemon builds every request URI from $daemon->url, which reads the
# socket. A keep-alive connection child closes its copy of the listening
# socket, so the URL is cached while the socket is still open (start() reads
# it before forking).
package Test::LocalHTTPDaemon::Listener;
use parent -norequire, 'HTTP::Daemon';

sub url { my ($self) = @_; return ${*$self}{test_local_url} //= $self->SUPER::url }

1;
