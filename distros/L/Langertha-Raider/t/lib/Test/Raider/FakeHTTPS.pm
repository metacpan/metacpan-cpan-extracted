package Test::Raider::FakeHTTPS;
# ABSTRACT: A local HTTPS server with its own CA, for tests that must not reach the network

use strict;
use warnings;
use Carp qw( croak );
use IO::Socket::SSL;
use IO::Socket::SSL::Utils qw( CERT_create PEM_cert2file PEM_key2file );
use JSON::MaybeXS ();
use Path::Tiny;
use POSIX ();

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::Raider::FakeHTTPS;

    my $pki = Test::Raider::FakeHTTPS->pki( names => [ 'provider.example', 'localhost' ] );
    my $srv = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {
      '/.well-known/langertha.json' => sub { Test::Raider::FakeHTTPS->json(200, $doc) },
    } );
    my $port = $srv->port;          # on 127.0.0.1
    my @requests = $srv->requests;  # { method, path, headers => { lc name => value } }

=head1 DESCRIPTION

A forked, blocking TLS server on C<127.0.0.1>. L</pki> makes a throw-away
CA and a server certificate for the given names (plus C<IP:127.0.0.1>);
clients trust it through C<SSL_ca_file> or C<SSL_CERT_FILE>. Every request
is logged, headers included, so a test can prove what was (not) sent. A
route returns the raw response octets, or C<< { sleep => N } >> to stall.
Unknown paths answer 404. The server dies with the object.

=cut

sub pki {
  my ( $class, %arg ) = @_;
  # The tempdir object is kept in the result: dropping it removes the dir.
  my $dir = $arg{dir} ? path( $arg{dir} ) : Path::Tiny->tempdir;
  my ( $ca_cert, $ca_key ) = CERT_create( CA => 1, subject => { commonName => 'raider test CA' } );
  my ( $cert, $key ) = CERT_create(
    subject => { commonName => $arg{names}[0] },
    subjectAltNames => [ ( map { [ DNS => $_ ] } @{ $arg{names} } ), [ IP => '127.0.0.1' ] ],
    issuer_cert => $ca_cert,
    issuer_key  => $ca_key,
    purpose     => 'server',
  );
  PEM_cert2file( $ca_cert, $dir->child('ca.pem')->stringify );
  PEM_cert2file( $cert, $dir->child('cert.pem')->stringify );
  PEM_key2file( $key, $dir->child('key.pem')->stringify );
  return {
    dir  => $dir,
    ca   => $dir->child('ca.pem')->stringify,
    cert => $dir->child('cert.pem')->stringify,
    key  => $dir->child('key.pem')->stringify,
  };
}

sub new {
  my ( $class, %arg ) = @_;
  my $pki = $arg{pki} or croak 'pki required';
  my $log = Path::Tiny->tempfile;
  my $srv = IO::Socket::SSL->new(
    LocalAddr     => '127.0.0.1',
    LocalPort     => 0,
    Listen        => 10,
    ReuseAddr     => 1,
    SSL_server    => 1,
    SSL_cert_file => $pki->{cert},
    SSL_key_file  => $pki->{key},
  ) or croak "listen: $! $SSL_ERROR";
  my $port = $srv->sockport;
  my $pid = fork // croak "fork: $!";
  if ( !$pid ) {
    $class->_serve( $srv, $arg{routes} // {}, $log );
    POSIX::_exit(0);
  }
  close $srv;
  return bless { pid => $pid, port => $port, log => $log }, $class;
}

sub port { $_[0]{port} }

sub requests {
  my ( $self ) = @_;
  my $json = JSON::MaybeXS->new;
  return map { $json->decode($_) } grep { length } $self->{log}->lines_utf8( { chomp => 1 } );
}

sub json {
  my ( $class, $code, $data, %headers ) = @_;
  my $body = ref $data ? JSON::MaybeXS->new( canonical => 1 )->encode($data) : $data;
  return $class->response( $code, $body, 'Content-Type' => 'application/json', %headers );
}

sub response {
  my ( $class, $code, $body, %headers ) = @_;
  $body //= '';
  my $head = 'HTTP/1.1 '.$code." X\r\n";
  $headers{'Content-Length'} //= length $body unless exists $headers{'Content-Length'};
  delete $headers{'Content-Length'} unless defined $headers{'Content-Length'};
  $head .= $_.': '.$headers{$_}."\r\n" for sort keys %headers;
  return $head."Connection: close\r\n\r\n".$body;
}

sub _serve {
  my ( $class, $srv, $routes, $log ) = @_;
  my $json = JSON::MaybeXS->new( canonical => 1 );
  while (1) {
    my $c = $srv->accept or next;
    local $/ = "\r\n";
    my $line = <$c>;
    unless ( defined $line ) { close $c; next }
    my %h;
    while ( my $l = <$c> ) {
      last if $l eq "\r\n";
      $h{ lc $1 } = $2 if $l =~ /^([^:]+):\s*(.*?)\r\n/;
    }
    my ( $method, $path ) = split / /, $line;
    $log->append_utf8( $json->encode( { method => $method, path => $path, headers => \%h } )."\n" );
    my $route = $routes->{$path};
    my $res = $route ? $route->( { method => $method, path => $path, headers => \%h } )
      : $class->response( 404, 'not found' );
    if ( ref $res eq 'HASH' ) {
      sleep $res->{sleep} if $res->{sleep};
      $res = $res->{then} // '';
    }
    if ( ref $res eq 'CODE' ) {
      $res->($c);
    }
    else {
      print $c $res;
    }
    close $c;
  }
}

sub DESTROY {
  my ( $self ) = @_;
  return unless $self->{pid};
  # waitpid sets $?; at global destruction that would become the test's
  # exit status.
  local $?;
  kill 'KILL', $self->{pid};
  waitpid $self->{pid}, 0;
  return;
}

1;
