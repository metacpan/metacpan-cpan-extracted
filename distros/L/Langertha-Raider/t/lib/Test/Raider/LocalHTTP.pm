package Test::Raider::LocalHTTP;
# ABSTRACT: A plain HTTP server on 127.0.0.1, run by an IO::Async loop, for tests that must not reach the network

use strict;
use warnings;
use IO::Async::Listener;

=head1 SYNOPSIS

    use Test::Raider::LocalHTTP;

    my $srv = Test::Raider::LocalHTTP->new( loop => $loop, routes => {
      '/page' => { status => 200, type => 'text/html', body => '<p>hi</p>' },
      '/old'  => { status => 301, location => '/page' },
    } );
    my $base  = $srv->base;        # http://127.0.0.1:PORT
    my $other = $srv->other_base;  # http://localhost:PORT -- the same server, another host
    my @paths = $srv->paths;       # the paths asked for, in order

=head1 DESCRIPTION

Answers on the loop it is added to, so the code under test -- which waits
on the same loop -- is served while it waits. A route is a hash: C<status>
(default 200), C<type> (default C<text/plain>), C<body>, C<location>; a
C<location> may hold C<{{HTTP}}> / C<{{HTTP_OTHER}}> for L</base> /
L</other_base>. Unknown paths answer 404. Every response closes the
connection.

=cut

my %REASON = ( 200 => 'OK', 301 => 'Moved Permanently', 302 => 'Found', 307 => 'Temporary Redirect',
  308 => 'Permanent Redirect', 403 => 'Forbidden', 404 => 'Not Found', 500 => 'Internal Server Error' );

sub new {
  my ( $class, %arg ) = @_;
  my $self = bless { loop => $arg{loop}, routes => $arg{routes} // {}, paths => [] }, $class;
  my $listener = IO::Async::Listener->new(
    on_stream => sub {
      my ( undef, $stream ) = @_;
      $stream->configure(
        on_read => sub {
          my ( $s, $buffref ) = @_;
          return 0 unless $$buffref =~ /\r\n\r\n/;
          my ( $path ) = $$buffref =~ m{\A[A-Z]+ (\S+) HTTP/};
          $$buffref = '';
          $s->write( $self->_response( $path // '/' ) );
          $s->close_when_empty;
          return 0;
        },
      );
      $self->{loop}->add($stream);
    },
  );
  $self->{loop}->add($listener);
  my $port = $listener->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )
    ->get->read_handle->sockport;
  @{$self}{qw( listener port )} = ( $listener, $port );
  return $self;
}

sub base       { 'http://127.0.0.1:'.$_[0]{port} }
sub other_base { 'http://localhost:'.$_[0]{port} }
sub paths      { @{ $_[0]{paths} } }

sub fill {
  my ( $self, $text ) = @_;
  return $text unless defined $text;
  my ( $base, $other ) = ( $self->base, $self->other_base );
  $text =~ s/\{\{HTTP_OTHER\}\}/$other/g;
  $text =~ s/\{\{HTTP\}\}/$base/g;
  return $text;
}

sub _response {
  my ( $self, $path ) = @_;
  push @{ $self->{paths} }, $path;
  my $route  = $self->{routes}{$path} // { status => 404, body => 'not found' };
  my $status = $route->{status} // 200;
  my $body   = $route->{body} // '';
  utf8::encode($body) if utf8::is_utf8($body);
  return 'HTTP/1.1 '.$status.' '.( $REASON{$status} // 'Status' )."\r\n"
    .'Content-Type: '.( $route->{type} // 'text/plain' )."\r\n"
    .( defined $route->{location} ? 'Location: '.$self->fill( $route->{location} )."\r\n" : '' )
    .'Content-Length: '.length($body)."\r\n"
    ."Connection: close\r\n\r\n".$body;
}

sub DESTROY {
  my ( $self ) = @_;
  my $listener = $self->{listener} or return;
  $listener->loop->remove($listener) if $listener->loop;
}

1;
