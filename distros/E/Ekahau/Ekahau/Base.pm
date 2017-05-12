package Ekahau::Base;
our $VERSION = '0.001';

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;
use bytes; # Avoid Unicode crap

use base 'Ekahau::ErrHandler';

our $_global_last_error;

use constant DEFAULT_PORT => 8548;
use constant DEFAULT_HOST => 'localhost';
use constant READ_BLOCKSIZE => 8192;

=head1 NAME

Ekahau::Base - Low-level interface to Ekahau location sensing system

=head1 SYNOPSIS

The C<Ekahau::Base> class provides a low-level interface to the Ekahau
location sensing system's YAX protocol.  In general you don't want to
use this class directly; instead the subclasses L<Ekahau|Ekahau> and
L<Ekahau::Events|Ekahau::Events> provide a nicer interface.

=head1 DESCRIPTION

This class implements methods for querying the Ekahau Positioning
Engine, and processing the responses.  Each object represents a
connection to the Ekahau server.  Some methods send queries to the
server, while others receive responses.  Continuous queries generate
data until they are asked to stop, so the protocol is not strictly
request-response.  To deal with this, queries can have a "tag"
associated with them, which allows the response to that specific
command to be identified.

=cut

use Ekahau::Response;
use Ekahau::License;

use IO::Socket::INET;
use IO::Select;

=head2 Constructor

=head3 new ( [ %params ] )

The C<new> constructor creates a new Ekahau object.  It takes a series
of parameters as arguments, in the C<Name => Value> style.  The
following parameters are recognized:

=over 4

=item Timeout

The maximum length of time to wait for a response or connection.

=item PeerAddr

The name or IP address of the Ekahau server you'd like to communicate
with.  This is passed along to the L<IO::Socket::INET|IO::Socket::INET> module, and you
can use the alias C<PeerHost> if you prefer.  It defaults to C<localhost>.

=item PeerPort

The TCP port where the Ekahau server you'd like to communicate with is
running.  It defaults to C<8548>.

=item Password

The password to talk to the Ekahau server.  The default password is
C<Llama>, which is what the server will use if you haven't configured
a password.

=item LicenseFile

The XML file containing your Ekahau license.  If you don't specify a
C<LicenseFile>, and anonymous connection will be used, which may be
limited by the software.

=back

=cut

sub new
{
    my $class = shift;
    my(%p) = @_;
    
    my $self = {};
    bless $self,$class;
    $self->{_errhandler} = Ekahau::ErrHandler->errhandler_new($class,%p);
    
    $self->{tag} = 0;
    $self->{_readbuf} = "";
    $self->{_timeout}=$p{Timeout}||$p{timeout};

    $self->_connect(%p)
	or return undef;
    $self->_start(%p)
	or return undef;

    $self->errhandler_constructed();
}

sub ERROBJ
{
    my $self = shift;
    $self->{_errhandler};
}

# Connect to the TCP socket
sub _connect
{
    my $self = shift;
    my(%p)=@_;
    my $sock;

    if ($p{Socket})
    {
	$sock = $p{Socket};
    }
    else
    {
	# For IO::Socket::INET
	if ($p{timeout} && !$p{Timeout})
	{
	    $p{Timeout}=$p{timeout};
	}
	elsif ($self->{_timeout})
	{
	    $p{Timeout} = $self->{_timeout};
	}
	
	if (!$p{PeerPort}) { $p{PeerPort} = DEFAULT_PORT };
	if (!$p{PeerAddr} and !$p{PeerHost}) { $p{PeerAddr} = DEFAULT_HOST };
	
	warn "DEBUG Connecting to $p{PeerAddr}:$p{PeerPort}...\n"
	    if ($ENV{VERBOSE});
	$sock = IO::Socket::INET->new(%p,
				      Proto => 'tcp')
	    or return $self->reterr("Couldn't create IO::Socket::INET -  $!");
    }

    $self->{_sock} = $sock;
    binmode $self->{_sock};
    $self->{_sock}->autoflush(1);
    $self->{_socksel} = IO::Select->new($self->{_sock})
	or return $self->reterr("Couldn't create IO::Select - $!");

    warn "DEBUG connected.\n"
	if ($ENV{VERBOSE});

    1;
}

# Start the YAX protocol, and authenticate with our license
# or anonymously
sub _start
{
    my $self = shift;
    my $talkresp;
    my(%p)=@_;

    $p{Password} ||= $p{password};
    if (!defined($p{Password})) { $p{Password}="Llama" };

    my $hello_resp = $self->nextresponse;

    my $talk_str = '';
    my($lic,$randstr);
    if ($p{LicenseFile})
    {
	# Make up a random string real quick.
	# This isn't cryptographically secure, but who cares?
	$randstr = sprintf "%02x"x8, map { int(rand(256)) } 1..8;
	# Read in the license file
	eval {
	    $lic = Ekahau::License->new(LicenseFile => $p{LicenseFile})
		or return $self->reterr("Error processing LicenseFile '$p{LicenseFile}': " . Ekahau::License->lasterr);
	};
	$@ and return $self->reterr("Error creating Ekahau::License object - $@");

	$self->command(['HELLO',1,'"'.$randstr.'"',$lic->hello_str])
	    or return undef;
        $talk_str = $lic->talk_str(Password => $p{Password}, HelloStr => $hello_resp->{args}[1])
	    or return $self->reterr("Error getting talk string from LicenseFile '$p{LicenseFile}': ".$lic->lasterr);
    }
    else
    {
	# No license file, log in anonymously
	$self->command(['HELLO',1,'""',"password=$p{Password}"])
	    or return undef;
    }
    $self->command(['TALK','yax',1,'yax1','MD5','"'.$talk_str.'"'])
	or return undef;
    $talkresp = $self->nextresponse
	or return undef;
    if ($talkresp->error)
    {
	return $self->reterr("Couldn't initiate session with Ekahau: ".$talkresp->error_description)
    }
    elsif ($talkresp->{cmd} ne 'TALK')
    {
	return $self->reterr("Couldn't initiate session with Ekahau: Unexpected response $talkresp->{string}");
    }

    if ($talkresp->{args}[0] !~ /^"?yax"?$/i)
    {
	return $self->reterr("Server is speaking unknown protocol '$talkresp->{args}[0]'");
    }
    if ($talkresp->{args}[3] !~ /^"?MD5"?/i)
    {
	return $self->reterr("Server is using unknown checksum '$talkresp->{args}[3]'");
    }
    
    if ($p{LicenseFile})
    {
	my $server_talk_str = $lic->talk_str(Password => $p{Password}, HelloStr => $randstr)
	    or $self->reterr("Error getting server talk string from LicenseFile: ".$lic->lasterr);
	if ($server_talk_str ne $talkresp->{args}[4])
	{
           return $self->reterr("Server gave invalid checksum");
	}
    }
    1;
}

# Read a response, taking it from the read buffer if a full response
# is available, and otherwise reading from the network.
sub _readresponse
{
    my $self = shift;
    my $r;

    while (1)
    {
	if ($r = $self->readpending) { last };
	if ($self->can_read($self->{_timeout}))
	{
	    $self->readsome();
	}
	else
	{
	    return '';
	}
    }
    $r;
}

sub _set_errhandler
{
    my $self = shift;
    my($eh)=@_;
    if ($eh)
    {
	$self->{_lasterror}=$eh;
    }
    else
    {
	$self->{_lasterror} = \$_global_last_error
    }
    $self->reterr('no error yet');
    1;
}

=head2 Methods

=head3 close ( )

Properly shut down the connection to the Ekahau engine, by sending a
C<CLOSE> command then closing the socket.

=cut

sub close
{
    my $self = shift;
    $self->command('CLOSE')
	or return undef;
    # It's the same as an abort from here on out.
    $self->abort;
}

=head3 abort ( )

Abort the connection to the Ekahau engine, by closing the socket.

=cut

sub abort
{
    my $self = shift;

    my $close_ok = 1;

    $close_ok = CORE::close($self->{_sock});
    undef $self->{_sock};
    undef $self->{_socksel};
    
    $close_ok or return $self->reterr("Error closing socket: $!\n");
    1;
}

=head3 readsome ( )

Read some data from the network into the read buffer.  This is the
buffer where L<readpending|/readpending> gets pending events from.  This call
blocks, so if you don't want to wait for events, you should either
C<select> on the handles returned by the L<select_handles|/select_handles> method, or
call the L<can_read|/can_read> method to determine if data is available to
read.

=cut

sub readsome
{
    my $self = shift;
    my $sock = $self->{_sock};
    
    sysread($sock,$self->{_readbuf},READ_BLOCKSIZE,length($self->{_readbuf}))
	or return $self->reterr("Error reading from socket: $!\n");
}

=head3 getpending ( )

Returns the next pending event, or C<undef> if no events are pending.
The event returned is an L<Ekahau::Response|Ekahau::Response> object.

Pending events come from the buffer filled by L<readsome|/readsome>.

=cut

sub getpending
{
    my $self = shift;
    my $resp_txt = $self->_readpending()
	or return undef;
    return Ekahau::Response->parsenew($resp_txt);
}

sub _readpending
{
    my $self = shift;

    if ($self->{_readbuf} =~ /^(\s*<.*?(?<!>)>\s*)/s)
    {
	my $msg = $1;
	# Is this an object with a size parameter?
	if ($self->{_readbuf} =~ /^\s*<[^>]*\x0asize=(\d+)[^>]*\x0adata=/sg)
	{
	    my $data_len = $1;
	    my $data_start = pos($self->{_readbuf});

	    if ((length($self->{_readbuf})-$data_start) < $data_len)
	    {
		# We don't have the whole thing.
		# This is just a warning.
		return $self->reterr('incomplete data response');
	    }
	    else
	    {
		$msg = substr($self->{_readbuf}, 0,$data_start + $data_len + 3);
	    }
	}
	warn "READ: '$msg'\n"
	    if ($ENV{VERBOSE});
	substr($self->{_readbuf},0,length($msg))='';
	# Preserve taintedness with substr(X,0,0)
	return $msg.substr($self->{_readbuf},0,0);
    }
    return $self->reterr('no complete response so far');
}

sub nextresponse
{
    my $self = shift;

    # Wait until we get something, or the timeout expires.
    my $started = time;
    while(1)
    {
	if (my $resp = $self->getpending)
	{
	    return $resp;
	}
	# See if we timed out.
	$self->can_read($self->{_timeout}? $self->{_timeout} : 0)
	    or return undef;
	
	$self->readsome()
	    or return undef;
    }

}

=head3 can_read ( $timeout )

Returns true if the network socket becomes readable within C<$timeout>
seconds; otherwise returns false.

=cut

sub can_read
{
    my $self = shift;

    $self->{_socksel}->can_read($_[0]||$self->{_timeout})
	or return $self->reterr("socket read timed out (probably)");
}

=head3 select_handles

Returns a list of filehandles suitable for use with C<select>.  If
you're multiplexing I/O from this module and other sources, you can
select these filehandles for readability, then call the L<readsome|/readsome>
method to read the available data, and finally call L<getpending|/getpending> in
a loop to get all of the pending events.  Note that these handles
become selectable for read only when there is data on the network; if
multiple events come in at once (which is common), the handle will
become selectable once, and you'll have to retreive all of the events
with L<getpending|/getpending>; it won't be selectable again until there is more
data to read.

=cut

sub select_handles
{
    my $self = shift;

    ($self->{_sock});
}

=head3 request_device_list ( [ $props ] )

Requests a list of all devices connected to the system.  Returns the
command tag that was sent (which can be used to identify the
response).

An optional hash reference can be supplied with a list of properties.
The special property C<Tag> will be used to set the command tag if
given (otherwise a tag will be generated).  Other properties will be
sent along in the Ekahau request.  Properties currently recognized
are:

=over 4

=item NETWORK.MAC

The MAC address of the device you'd like to look for, in
colon-seperated format.  For example:

  'NETWORK.MAC' => '00:E0:63:82:65:76'

=item NETWORK.IP-ADDRESS


The IP address of the device you'd like to look for, in dotted-quad
format.  For example:

  'NETWORK.IP-ADDRESS' => '10.0.0.1'

=back


=cut

sub request_device_list
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    
    $self->command('GET_DEVICE_LIST',\%p,$tag)
	or return undef;
    $tag;
}

=head3 request_device_properties ( [ $props ], $device_id )

Request the property list for device C<$device_id>.

The first parameter can be a hash reference containing additional
request properties to be sent, but none are documented by Ekahau for
this command.  The one exception is the special property C<Tag>, which
will be used to set the command tag if given (otherwise a tag will be
generated).

=cut

sub request_device_properties
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($dev)=@_;

    $self->command(['GET_DEVICE_PROPERTIES', $dev],\%p,$tag)
	or return undef;
    $tag;
}

=head3 request_location_context ( [ $props ], $area_id )

Request information about logical area C<$location_id>.  

The first parameter can be a hash reference containing additional
request properties to be sent, but none are documented by Ekahau for
this command.  The one exception is the special property C<Tag>, which
will be used to set the command tag if given (otherwise a tag will be
generated).

=cut

sub request_location_context
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($c)=@_;

    $self->command(['GET_CONTEXT', $c],{},$tag)
	or return undef;
    $tag;
}

=head3 request_map_image ( [ $props ], $area_id )

Request a map of logical area C<$area_id>.  Returns an
L<Ekahau::Response::MapImage|Ekahau::Response::MapImage> object.

=cut

sub request_map_image
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($c)=@_;

    $self->command(['GET_MAP', $c],{},$tag)
	or return undef;
    $tag;
}

=head3 request_all_areas ( )

Request information about all logical areas known to the Ekahau
engine.

=cut

sub request_all_areas
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};

    $self->command(['GET_LOGICAL_AREAS'],{},$tag)
	or return undef;
    $tag;
}

=head3 start_location_track ( [ $properties ], $device_id )

Ask the Ekahau engine to start sending location information about
device C<$device_id>.  You can get responses with L<getpending|/getpending>.

An optional hash reference can be supplied with a list of properties.
The special property C<Tag> will be used to set the command tag if
given (otherwise a tag will be generated).  Other properties will be
sent along in the Ekahau request.  Properties currently recognized
are:

=over 4

=item EPE.WLAN_SCAN_INTERVAL

Interval at which wireless LAN devices should scan.  See documentation
for more information.

=item EPE.WLAN_SCAN_MODE

Wireless LAN scan mode.  See documentation for more information.

=item EPE.SNAP_TO_RAIL

Set to the string C<true> to have all locations correspond to
positions on tracking rails, or C<false> to allow any location.

=item EPE.EXPECTED_ERROR

Set to the string C<true> if you would like an expected error
estimate, or C<false> to avoid this calculation.

=item EPE.POSITIONING_MODE

Set to 1 for realtime positioning, or 2 for more accurate
positioining.

=item EPE.LOCATION_UPDATE_INTERVAL

How often you'd like an update on the device's position.

=back

=cut

sub start_location_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($dev) = @_;

    $self->command(['START_LOCATION_TRACK',$dev],\%p,$tag)
	or return undef;
    $tag;
}

=head3 request_stop_location_track ( $device_id )

Ask the Ekahau engine to stop sending location information about
device C<$device_id>.

=cut

sub request_stop_location_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($dev) = @_;

    $self->command(['STOP_LOCATION_TRACK',$dev],\%p,$tag)
	or return undef;
    $tag;
}

=head3 stop_location_track ( $device_id )

Alias for C<request_stop_location_track>.

=cut

sub stop_location_track
{
    my $self = shift;
    $self->request_stop_location_track(@_);
}

=head3 start_area_track ( [ $properties ], $device_id )

Ask the Ekahau engine to start sending area information about
device C<$device_id>.  You can get responses with L<getpending|/getpending>.

An optional hash reference can be supplied with a list of properties.
The special property C<Tag> will be used to set the command tag if
given (otherwise a tag will be generated).  Other properties will be
sent along in the Ekahau request.  This command recognizes all of the parameters used by L<start_location_track|/start_location_track>, and also these:

=over 4

=item EPE.NUMBER_OF_AREAS

How many areas you'd like returned with each area response.  Each will
come with a probability that the user is in that area.

=back

=cut

sub start_area_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $dev = shift;
    my $tag = delete $p{Tag} || ++$self->{tag};

    $self->command(['START_AREA_TRACK',$dev], \%p, $tag)
	or return undef;
}

=head3 request_stop_area_track ( $device_id )

Ask the Ekahau engine to stop sending area information about
device C<$device_id>.

=cut

sub request_stop_area_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    my $tag = delete $p{Tag} || ++$self->{tag};
    my($dev) = @_;

    $self->command(['STOP_AREA_TRACK',$dev],\%p,$tag)
	or return undef;
    $tag;
}

=head3 stop_area_track ( $device_id )

Alias for C<request_stop_area_track>.

=cut

sub stop_area_track
{
    my $self = shift;
    $self->request_stop_area_track(@_);
}


=head3 command ( $cmd, $props, $tag )

This is a fairly low-level routine, and shouldn't be needed in normal
use.  It is the only way to send an arbitrary command to the YAX
engine, however, so it is available and documented.

YAX commands look like this:

  <#$tag command arguments
  property1=value1
  property2=value2
  ...
  >

For clarity, we'll call the string sent at the very beginning of first
line command the I<tag>, the next whitespace-seperated word the
I<command>, and the remainder of the first line a space-seperated list
called I<arguments>.  Additional information on other lines we'll call
I<properties>.

C<$cmd> is a list reference containing the command and arguments to
send.  It can also be a string, which is the same as specifying a list
with just that string.

C<$props> is a hash reference containing the properties to be sent
with the command.  If it is empty or C<undef>, no properties are sent.

C<$tag> is the command's tag, which allows the response to be picked
out of the data coming back from the server.

Here are some examples:

  $self->command(['GET_DEVICE_PROPERTIES',1], {}, 'A1');
  $self->command('GET_DEVICE_LIST',{'NETWORK.IP-ADDRESS' => '10.1.1.1'}, 'B2');

=cut

sub command
{
    my $self = shift;
    my($cmd,$props,$tag)=@_;
    my $data;

    my @args;

    if ($cmd and ref($cmd) eq 'ARRAY')
    {
	$cmd=join(' ',map { (!defined($_) or $_ eq '') ? '""' : $_ } @$cmd);
    }
    if ($props and ref($props) eq 'HASH')
    {
	$cmd .= "\x0d\x0a";
	while (my($key,$val)=each(%$props))
	{
	    if ($key eq 'data')
	    {
		# Data blob
		$data = $val;
		$cmd .= "size=".length($$data)."\x0d\x0a";
	    }
	    elsif (ref($val) and ref($val) eq 'ARRAY')
	    {
		foreach my $prop2 (@$val)
		{
		    $cmd .= $key ."\x0d\x0a";
		    $cmd .= "$_=$prop2->{$_}\x0d\x0a"
			foreach keys %$prop2;
		}
	    }
	    else
	    {
		$cmd .= "$key=$val\x0d\x0a";
	    }
	}
    }
    if ($data)
    {
	$cmd .= 'data='.$$data."\x0d\x0a";
    }
    $self->_sendcmd($cmd, $tag);
}

sub _sendcmd
{
    my $self = shift;
    my($params,$tag) = @_;

    if (defined($tag))
    {
	$tag = "#$tag ";
    }
    else
    {
	$tag = '';
    }
    my $cmd = "<$tag$params>\x0d\x0a";
    $self->_write($cmd);
}

sub _write
{
    my $self = shift;
    my $sock = $self->{_sock};

    warn "SENT: ",join("",@_),"\n"
	if ($ENV{VERBOSE});
    print $sock @_
	or return $self->reterr("socket write error: $!\n");
}

=head2 lasterr ( )

Returns the last error generated by this object, or when called as a
class method the last constructor error that prevented an object from
being created.  The return value is a string describing the error,
suitable for display to the ser.

=head2 Destructors

=head3 DESTROY ( )

When an C<Ekahau::Base> object is destroyed, its connection is closed
using the L<close|/close> method.

=cut

sub DESTROY
{
    my $self = shift;
    $self->close
	if ($self->{_sock});
}

1;

=head2 Error Handling

Constructors and most methods return I<undef> on error.  To find out
details about the error, you can call the L<lasterr|/lasterr> method, which
will return a string.  If the error happened in the constructor and so
you don't have an object to call a method on, call it as a class
method:

    my $errstr = Ekahau::Base->lasterr;

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<http://www.ekahau.com/>, I<Ekahau Positioning
Engine User Guide>, L<Ekahau|Ekahau>, L<Ekahau::Events|Ekahau::Events>, L<Ekahau::Response|Ekahau::Response>,
L<Ekahau::License|Ekahau::License>, L<IO::Socket::INET|IO::Socket::INET>, L<IO::Select|IO::Select>.

=cut

1;
