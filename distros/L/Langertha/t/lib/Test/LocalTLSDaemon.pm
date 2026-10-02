package Test::LocalTLSDaemon;
# Forked HTTPS server on 127.0.0.1 with a throwaway CA, for exercising TLS
# name checks of a real LWP::UserAgent / Net::Async::HTTP — no live calls.
#
#   my $server = Test::LocalTLSDaemon->start(
#     names   => [ 'pinned.invalid' ],          # the certificate's DNS names
#     handler => sub { my ($request) = @_; return $http_response },
#   );
#   $server->port;      # the listening port on 127.0.0.1
#   $server->ca_file;   # PEM of the CA that signed the certificate
#
# Connections are kept alive (HTTP/1.1, Content-Length framing) unless the
# client asks for Connection: close, and each connection is served by its own
# forked child, so a pooled client connection can carry several requests. The
# handler gets an HTTP::Request (with the request's Host header) and returns an
# HTTP::Response. A failed handshake (a client that rejects the certificate)
# just ends that connection. Destroying the object kills the server.

use strict;
use warnings;

use File::Temp ();
use HTTP::Request;
use HTTP::Response;
use IO::Socket::IP;
use IO::Socket::SSL;
use IO::Socket::SSL::Utils qw( CERT_create PEM_cert2string PEM_key2string );
use POSIX ();

sub start {
  my ( $class, %opts ) = @_;
  my @names = @{ $opts{names} || ['localhost'] };
  my ( $ca_cert, $ca_key ) = CERT_create( CA => 1, subject => { commonName => 'Langertha Test CA' } );
  my ( $cert, $key ) = CERT_create(
    subject        => { commonName => $names[0] },
    subjectAltNames => [ map { [ DNS => $_ ] } @names ],
    issuer         => [ $ca_cert, $ca_key ],
    purpose        => 'server',
  );
  my %file = map { $_ => File::Temp->new( SUFFIX => '.pem' ) } qw( ca cert key );
  print { $file{ca} } PEM_cert2string($ca_cert);
  print { $file{cert} } PEM_cert2string($cert);
  print { $file{key} } PEM_key2string($key);
  close $file{$_} for keys %file;

  my $listen = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 10, ReuseAddr => 1 )
    or die "cannot listen: $!";
  my $port = $listen->sockport;

  my $pid = fork;
  die "fork failed: $!" unless defined $pid;
  if ( !$pid ) {
    my $ok = eval { _serve( $listen, $opts{handler}, $file{cert}->filename, $file{key}->filename ); 1 };
    warn "Test::LocalTLSDaemon: $@" unless $ok;
    POSIX::_exit( $ok ? 0 : 1 );
  }
  close $listen;
  return bless { pid => $pid, port => $port, file => \%file }, $class;
}

sub _serve {
  my ( $listen, $handler, $cert_file, $key_file ) = @_;
  $SIG{PIPE} = 'IGNORE';
  my %children;
  $SIG{TERM} = sub { kill 'TERM', keys %children; waitpid $_, 0 for keys %children; POSIX::_exit(0) };
  while (1) {
    my $conn = $listen->accept or next;
    while ( ( my $done = waitpid( -1, POSIX::WNOHANG() ) ) > 0 ) { delete $children{$done} }
    my $child = fork;
    die "fork failed: $!" unless defined $child;
    if ($child) { $children{$child} = 1; close $conn; next }
    $SIG{TERM} = 'DEFAULT';
    close $listen;
    my $tls = IO::Socket::SSL->start_SSL( $conn, SSL_server => 1,
      SSL_cert_file => $cert_file, SSL_key_file => $key_file );
    POSIX::_exit(0) unless $tls;   # the client refused the certificate
    my $served = eval { _serve_connection( $tls, $handler ); 1 };
    warn "Test::LocalTLSDaemon: $@" unless $served;
    POSIX::_exit( $served ? 0 : 1 );
  }
}

sub _serve_connection {
  my ( $tls, $handler ) = @_;
  while (1) {
    my $head = '';
    while ( defined( my $line = <$tls> ) ) {
      $head .= $line;
      last if $line =~ /\A\r?\n\z/;
    }
    return unless length $head && $head =~ /\r?\n\r?\n\z/;
    my ( $start, @lines ) = split /\r?\n/, $head;
    my ( $method, $path ) = split / /, $start;
    my $request = HTTP::Request->new( $method => $path );
    for (@lines) { $request->push_header( $1 => $2 ) if /\A([^:]+):\s*(.*)\z/ }
    my $length = $request->header('Content-Length') // 0;
    if ($length) { read( $tls, my $body, $length ); $request->content($body) }
    my $response = $handler->($request);
    my $close = ( $request->header('Connection') // '' ) =~ /close/i;
    my $content = $response->content // '';
    $response->header( 'Content-Length' => length $content );
    $response->header( Connection => 'close' ) if $close;
    print {$tls} 'HTTP/1.1 ' . $response->code . ' ' . ( $response->message // '' ) . "\r\n"
      . $response->headers->as_string("\r\n") . "\r\n" . $content;
    return if $close;
  }
}

sub port    { $_[0]->{port} }
sub ca_file { $_[0]->{file}{ca}->filename }

sub DESTROY {
  my ($self) = @_;
  return unless $self->{pid};
  kill 'TERM', $self->{pid};
  waitpid $self->{pid}, 0;
}

1;
