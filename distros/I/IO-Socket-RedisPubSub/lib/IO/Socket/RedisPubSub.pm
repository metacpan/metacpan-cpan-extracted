package IO::Socket::RedisPubSub;
use strict;
use IO::Socket;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.02';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw(publish subscribe pull);
    %EXPORT_TAGS = ();
}

1;

# Read from the redis server and package the response into
# a hash ref.
sub _redis_read {
  my $self = shift;
  my $conn = $self->{connection};
  my $start = $conn->getline;
  return { type => 'int', value => $1 } if $start =~ /^:(\d+)/;
  return { type => 'error', value => $1 } if $start =~ /^-(\d+)/;
  return { type => 'line', value => $1 } if $start =~ /^\+(\d+)/;
  if ( $start =~ /^\$(\d+)/ ) {
    return { type => 'bulkerror' } if $1 == -1;
    my $res;
    $conn->read ( $res, $1 );
    my $l = $conn->getline;
    return { type => 'bulk', length => $1, value => $res };
  }
  if ( $start =~ /^\*(\d+)/ ) {
    return { type => 'multibulkerror' } if $1 == -1;
    my @res;
    push @res, $self->_redis_read ( "multibulk $_" ) for 1 ... $1;
    return { type => 'bulkmulti', values => \@res };
  }
  warn "bad read";
  return undef;
}

sub new {
  my ($class, %args ) = @_;
  
  my $self = bless ({}, ref ($class) || $class);
  my $host = $args{host} || 'localhost';
  my $port = $args{port} || 6379;
  $self->connect ( $host, $port );
  return $self;
}

sub publish {
  my ( $self, $channel, $msg ) = @_;
  my $conn = $self->{connection};
  my $cl = length $channel;
  my $ml = length $msg;

  my $cmd = "*3\r\n\$7\r\npublish\r\n\$$cl\r\n$channel\r\n\$$ml\r\n$msg\r\n";
  $conn->print ( $cmd );
  return $self->_redis_read ( 'publish' );
}

sub subscribe {
  my ( $self, $channel ) = @_;
  my $conn = $self->{connection};
  my $cl = length $channel;
  my $cmd = "*2\r\n\$9\r\nsubscribe\r\n\$$cl\r\n$channel\r\n";
  $conn->print ( $cmd );
  return $self->_redis_read ( 'subscribe' );
}

sub pull {
  my ( $self ) = @_;
  my $d = $self->_redis_read ( 'pull' );
  my ( $type, $channel, $message ) = 
    ( $d->{values}->[0]->{value},
      $d->{values}->[1]->{value},
      $d->{values}->[2]->{value} );
  return ( $channel, $message );
}

sub connect {
  my ( $self, $host, $port ) = @_;
  $self->close;
  $self->{connection} = IO::Socket::INET->new ( PeerAddr => "$host:$port" );
  return ( undef, undef ) unless $self->{connection} &&
    $self->{connection}->connected;
  my ( $myport, $myaddr ) = sockaddr_in ( $self->{connection}->sockname );
  return ( inet_ntoa ( $myaddr ), $myport );
}

sub close {
  my $self = shift;
  my $conn = $self->{connection};
  $conn->close if $conn && $conn->connected;
}

=head1 NAME

IO::Socket::RedisPubSub - A simple redis publish/subscribe client.

=head1 SYNOPSIS

# Somewhere
  use IO::Socket::RedisPubSub qw(subscribe pull);

  my $rs = IO::Socket::RedisPubSub->new;

  $rs->subscribe ( 'newsfeed' );

  while ( my ( $channel, $message ) = $rs->pull ) {
    print "Got $message on $channel";
  }

# Elsewhere
  use IO::Socket::RedisPubSub qw(publish);

  IO::Socket::RedisPubSub->new->publish ( 'newsfeed', 'hi there' );

  
=head1 DESCRIPTION

A very simple redis client.  Just uses the publish/subscribe features.

=head1 AUTHOR

    Martin Redmond
    CPAN ID: REDS
    Tinychat.com
    martin@tinychat.com
    http://tinychat.com/about.html

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

