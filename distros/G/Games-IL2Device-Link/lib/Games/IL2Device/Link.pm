package Games::IL2Device::Link;

use strict;
use warnings;
use IO::Socket qw(:DEFAULT :crlf);
use Carp;

use vars qw($VERSION);
our $VERSION = '0.02';

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);



# Methods

sub new {
  my $devlink = shift;
  my $class =  ref($devlink) || $devlink;
  my $self = {
	      ADDR => undef,
	      PORT => undef,
	      TIMEOUT => 30,
	      DEBUG => 0
	     };
  bless ($self, $class);
  $self->_init(@_);
  $self->il2connect if (defined($self->addr) && defined($self->port));
  return $self;
}



sub _init {
  my $self = shift;
  $self->{ADDR} = shift;
  $self->{PORT} = shift;
  if ( @_ ) {
    my %extra = @_;
    @$self{keys %extra} = values %extra;
  }
}



sub addr {
  my $self = shift;
  if (@_) {
    $self->{ADDR} = shift;
  }
  return $self->{ADDR};

}



sub port {
  my $self = shift;
  if (@_) {
    $self->{PORT} = shift;
  }
  return $self->{PORT};

}



sub reply {
  my $self = shift;
  return  $self->{'REPLY'};
}



sub il2connect {
  my $self = shift;
  
  if ( defined($self->addr) && defined($self->port) ) {
    
    $self->{SOCK} = IO::Socket::INET->new(PeerAddr => $self->addr,
					  PeerPort => $self->port,
					  Type => SOCK_DGRAM,
					  Proto => 'udp') or 
					    warn "il2connect() socket creation failed: $!";
    return 1;
  } else {
    carp "il2connect(): Nowhere to connect!";
    return 0;
  }
}


sub il2disconnect {
  my $self = shift;
  $self->{SOCK} = undef;
}


sub _send {
  my $self = shift;
  local $, = $CRLF;
  my $bs = 0;
  
  if ( defined( $self->{SOCK} ) ) {
    $bs = $self->{SOCK}->print("$self->{PACKET}$CRLF");
    warn "_send() failed to send data: $!" if $bs <= 0;
    print "_send(): sent; $self->{PACKET}\n" if $self->{DEBUG} && $bs;
  } else {
    carp "_send(): No socket defined, are you connected?";
  }
  return $bs;
}
  
  
  
sub _receive {
  my $self = shift;
  local $/ = $LF;
  my $recv_size = ( length(scalar "$self->{PACKET}$CRLF") * 4);
  my $buffer = undef;
  $self->{DATA} = undef;
  
  if ( defined($self->{SOCK}) ) {
    if ( $recv_size > 0 ) {
      $SIG{ALRM} = sub { die "timeout" };
      
      eval {
	alarm($self->{TIMEOUT});
	$self->{SOCK}->recv($buffer, $recv_size);
	$self->{DATA} = $buffer;
	alarm(0);
      };
      if ($@) {
	if ($@ =~ /timeout/) {
	  warn "_receive(): timeout while reading $!";
	} else {
	  alarm(0);
	  die;
	}
      }
      
    }
  } else {
    carp "_receive(): No socket defined, are you connected?";
    return undef;
  }
  print "_receive(): got: $self->{DATA}\n" if $self->{DEBUG};

  return $self->{DATA};
}


sub creategetpacket {
  my $self = shift;
  $self->{PACKET} = "R";
  foreach ( @_ ) {
    $self->{PACKET} .= "/$_";
  }
  $self->{PACKET} .= "/";
  print "creategetpacket(): created; $self->{PACKET}\n" if $self->{DEBUG};
  return $self->{PACKET};
}



sub createsetpacket {
  my $self = shift;
  my ($key, $value) = @_;
  if ( defined ($value) ) {
    $self->{PACKET} = "R/" . $key . "\\" . $value;
  } else {
    $self->{PACKET} = "R/" . $key . "\\";
  }
  print "createsetpacket(): created; $self->{PACKET}\n" if $self->{DEBUG};
  return $self->{PACKET};
}



sub set {
  my $self = shift;
  my $packet = $self->createsetpacket(@_);
  my $result = $self->_send($packet);
  return $result;
}



sub get {
  my $self = shift;
  my $data = undef;
  my $packet = $self->creategetpacket(@_);
  my $result = $self->_send($packet);
  if ( defined($result) ) {
    $data = $self->_receive();
    if ( defined( $data ) ) {
      $self->parsedata();
    } else {
      return 0;
    }
  } else {
    return 0;
  }
  return 1;
}



sub parsedata {
  my $self = shift;
  my %pdata;
  my $key = undef; 
  my $value = undef;
  foreach (split /\//, $self->{DATA}) {
    chomp;
    next if /^A/;
    if ( /^(\d+)\\/ ) { 
      $key = $1; 
    }
    if ( /[\\\d]*\\(.+)$/ ) {
      $value = $1 
    }
    $pdata{$key} = $value if defined $key;
    print "parsedata(): key; $key value; $value\n" if $self->{DEBUG};
  }
  $self->{REPLY} = \%pdata;
}



sub DESTROY {
  my $self = shift;
  carp "Closing connection" if $self->{DEBUG};
  $self->{SOCK} = undef;
}


1;
__END__



=head1 NAME

Games::IL2Device::Link - A simple class for talking to IL2 clients.

=head1 SYNOPSIS

    use Games::IL2Device::Link;

    # Create a new connection to a IL2 client
    $mydl = Games::IL2Device::Link->new('127.0.0.1', 10001, ( TIMEOUT => 5)); 

    # Get value of key 52 (overload)
    $mydl->get(52);
    # reply method returns the result from last query
    print "G-load: ". $mydl->reply->{52} ."\n";

    # Toggle navigation lights.
    $mydl->set(411) or warn "411 failed!";
    
    # You can ask for several values at once with get
    $mydl->get(60,62,64,70,72,80,74);
    $reply = $mydl->reply;
    foreach (keys %$reply) { print "got: $reply->{$_}\n"; }
    


=head1 DESCRIPTION

This class provides an interface to connect to a I<devicelink> on a
IL2 Forgotten Battles client (=> 2.01). The interface hosts a set of
key values which can be set or get - reference to these values can be
found in 'DeviceLink.txt' located in the IL2 Forgotten Battles install
folder. To activate the I<devicelink> feature in IL2 Forgotten Battles
you need to add a section in the 'conf.ini' file:

=over 4
           [DeviceLink]
           port=10001
           host=127.0.0.1
           IPS=127.0.0.1
=back

=head1 BUGS

The set() method currently only works with one key/pair value per
call. Set values only works if you send them last to the server. Get
values with parameters can only be sent one at each call. Get values
with indexed replies are not parsed, you will have to remember in what
order you called each object.

=head1 AUTHOR

Mathias Jansson <matja[at]cpan.org>

=head1 COPYRIGHT

This software is free software, you may redistribute it and/or modify
it under the same license as perl itself. IL2 Forgotten battles is the
property of Ubisoft Entertainment and 1C:Maddox games.

Copyright (C) 2004 Mathias Jansson

=head1 SEE ALSO

L<Games::IL2Device::Constants> L<perl>(1).

=cut
