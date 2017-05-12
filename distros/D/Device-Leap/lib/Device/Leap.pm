package Device::Leap;

use 5.000001;
use strict;
use warnings;
use Socket;	# Leap communicates over WebSockets
use JSON;	# ... in JSON

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::Leap ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	Leap
);


our $VERSION = '0.01';

my($LEAP_HANDLE);	#	After connection, this contains our websocket handle
my($SEND);		#	Data to send, when other end is ready for it
my($BUFF)='';		#	Buffer in case calling script misses a few events

sub Leap {
  my $ret;

  if($BUFF eq '') {	# Nothing in the buffer - try to get some more
    unless($LEAP_HANDLE) {	# Establish a new connection

      # Make the socket
      socket($LEAP_HANDLE, PF_INET, SOCK_STREAM, getprotobyname('tcp'))     || return (\{'error' => "socket: $!"});

      # Don't let stuff like UTF-style characters get screwed up
      binmode($LEAP_HANDLE)                                                 || return (\{'error' =>,"binmode(socket handle): $!"});

      # Allow more than one connection
      setsockopt($LEAP_HANDLE, SOL_SOCKET, SO_REUSEADDR, 1)                 || return (\{'error' =>,"SO_REUSEADDR: $!"});

      # Don't block on close (Remember not to close it until we've sent everything we want):-
      if($^O =~/Win32/i) {
        setsockopt($LEAP_HANDLE, SOL_SOCKET, SO_DONTLINGER, 1)              || return (\{'error' =>,"SO_DONTLINGER: $!"});
      }

      my $temp = 1; ioctl($LEAP_HANDLE, 0x8004667E, \$temp); # Don't let it block us.

      # connect to the remote smtp server address with our socket. # Could use INADDR_LOOPBACK instead of inet_aton("127.0.0.1")
      my $rc=connect($LEAP_HANDLE,sockaddr_in(6437,inet_aton('127.0.0.1')));

      my $mask='XhKY' . unpack('H*',pack('d',rand())) . 'eA==';

      $SEND="GET / HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nHost: localhost:6437\r\nOrigin: null\r\nPragma: no-cache\r\nCache-Control: no-cache\r\nSec-WebSocket-Key: $mask\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Extensions: x-webkit-deflate-frame\r\n\r\n";

    } # Establish

    # See if the non-blocking socket is ready for a read or a write...
    my($bitsr,$bitsw,$null,$rcr,$rcw,$rce,$rc)=('','','');
    vec($bitsr,fileno($LEAP_HANDLE),1)=1;	# This tells select() which socket we want to query
    vec($null,fileno($LEAP_HANDLE),1)=0;
    if(defined $SEND) {$bitsw=$bitsr} else {$bitsw=$null}	# We only care about write-status if we've got data to write
    $rc=select($rcr=$bitsr, $rcw=$bitsw, $rce=$bitsr, 0);	# See if our socket has any data to read (or write, or errors)


    if($rc) {
      if($rce ne $null) {     # Ugh - what to do with errors?
        return (\{'error' =>,"Socket read error: $!"});
      }

      if($rcr ne $null) {     # Is there stuff to "read"?
        my $stuff=sysread($LEAP_HANDLE, $BUFF, 16384); # Read upto 16K

        if(length($BUFF)==0) {
	  close($LEAP_HANDLE); undef $LEAP_HANDLE;
	  return (\{'error' =>,"Socket closed"});
        } else {
	  # We read some new data!
	  $BUFF='' unless(substr($BUFF,0,1) eq "\x81");	# discard non-ws return data
        }
      }

      if(($rcw ne $null)&&(defined $SEND)) {     # Am I able to write?
	syswrite($LEAP_HANDLE, $SEND);
	undef $SEND;
      }

    } else {
      # Socket reports no activity...
    }

  } # BUFF

  if($BUFF ne '') {	# Decode some WS data
    my $offset=2;
    my $len=unpack('C',substr($BUFF,1,1));
    if($len==126) {	# Extended 16bit len
      $len=unpack('n',substr($BUFF,2,2));
      $offset+=2;
    } elsif($len==127) {
      $len=unpack('N',substr($BUFF,2,6));
      $offset+=6;
    }
    $ret=substr($BUFF,$offset,$len);
    $BUFF=substr($BUFF,$offset+$len);
    if(length($ret)!=$len) {
      $ret='';	# too much data came in to process all at once - some got truncated...
    } else {
      $ret=from_json($ret);
    }
  }

  return $ret;
} # Leap




1;
__END__

=head1 NAME

Device::Leap - Perl interface to the Leap Motion Controller

=head1 SYNOPSIS

  use Device::Leap;
  while(1) {
    $d=&Leap();
    next unless(ref $d);				# no new data
    print $d->{hands}->[0]->{sphereRadius} . "\n";	# print some
  }

=head1 DESCRIPTION

This module provides an interface to query a Leap Motion 
controller.  The controller exposes rapid and accurate hand
motion data over a localhost websocket.  This script uses
native non-blocking sockets to return that data, thus should
be compatible on Windows, Mac, and Linux machines without 
needing compilers or related SDK overhead.

=HEAD2 ABOUT

The Leap Motion controller senses your individual hand and
finger movements so you can interact directly with your
computer.

=begin html

<img src="http://www.chrisdrake.com/LeapMotion.png" width="256" height="147" alt="The Leap Motion controller" align="right" />

=end html

=head2 EXPORT

Leap	# one sub which returns you your data

=head2 DEPENDENCIES

This module requires these other modules and libraries:

  Socket (already part of perl itself)
  JSON

=head1 SEE ALSO

See the Leap Motion web site: https://leapmotion.com/ for links to
the developer forums etc.

=head1 AUTHOR

Chris Drake, E<lt>cdrake@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Chris Drake

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=head1 BUGS

This code impliments WebSockets inline, because existing CPAN ws
modules all have heavy overhead requirments needing compilers and
development build infrastruture delployed at the client.  This was
considered both unnecessary and overly limiting.  
If the Leap Motion websocket spec changes in future and breaks this
module, a new CPAN release (update) will be made available.

=cut
