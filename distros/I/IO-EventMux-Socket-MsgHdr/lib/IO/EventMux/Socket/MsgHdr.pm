package IO::EventMux::Socket::MsgHdr;
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

IO::EventMux::Socket::MsgHdr - sendmsg, recvmsg and ancillary data operations

=head1 SYNOPSIS

  use IO::EventMux::Socket::MsgHdr;
  use Socket;

  # sendto() behavior
  my $echo = sockaddr_in(7, inet_aton("10.20.30.40"));
  my $outMsg = new IO::EventMux::Socket::MsgHdr(buf  => "Testing echo service",
                                  name => $echo);
  sendmsg(OUT, $outMsg, 0) or die "sendmsg: $!\n";

  # recvfrom() behavior, OO-style
  my $msgHdr = new IO::EventMux::Socket::MsgHdr(buflen => 512)

  $msgHdr->buflen(8192);    # maybe 512 wasn't enough!
  $msgHdr->namelen(256);    # only 16 bytes needed for IPv4
  
  die "recvmsg: $!\n" unless defined recvmsg(IN, $msgHdr, 0);

  my ($port, $iaddr) = sockaddr_in($msgHdr->name());
  my $dotted = inet_ntoa($iaddr);
  print "$dotted:$port said: " . $msgHdr->buf() . "\n";

  # Pack ancillary data for sending
  $outHdr->cmsghdr(SOL_SOCKET,                # cmsg_level
                   SCM_RIGHTS,                # cmsg_type
                   pack("i", fileno(STDIN))); # cmsg_data
  sendmsg(OUT, $msgHdr);

  # Unpack the same
  my $inHdr = IO::EventMux::Socket::MsgHdr->new(buflen => 8192, controllen => 256);
  recvmsg(IN, $inHdr, $flags);
  my ($level, $type, $data) = $inHdr->cmsghdr();
  my $new_fileno = unpack('i', $data);
  open(NewFH, '<&=' . $new_fileno);     # voila!

=head1 DESCRIPTION

IO::EventMux::Socket::MsgHdr is a fork of L<Socket::MsgHdr> as the old author 
did not respond in regards to a cleanup patch to get rid of warnings in both
modules and tests. This fork has since restructured the module so it's simpler
to understand and maintain. 

IO::EventMux::Socket::MsgHdr provides advanced socket messaging operations via 
L<sendmsg> and L<recvmsg>.  Like their C counterparts, these functions accept 
few parameters, instead stuffing a lot of information into a complex structure.

This structure describes the message sent or received (C<buf>), the peer on
the other end of the socket (L<name>), and ancillary or so-called control
information (L<cmsghdr>).  This ancillary data may be used for file descriptor
passing, IPv6 operations, and a host of implementation-specific extensions.

=cut

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT    = qw(sendmsg recvmsg);
our @EXPORT_OK = qw(pack_cmsghdr unpack_cmsghdr socket_errors);

use Errno qw(EPROTO ECONNREFUSED ETIMEDOUT EMSGSIZE ECONNREFUSED EHOSTUNREACH 
             ENETUNREACH EACCES EAGAIN ENOTCONN ECONNRESET EWOULDBLOCK);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use POSIX qw(strerror);

use Socket;
use constant {
    SOL_IP             => 0,
    IP_RECVERR         => 11,
    SO_EE_ORIGIN_NONE  => 0,
    SO_EE_ORIGIN_LOCAL => 1,
    SO_EE_ORIGIN_ICMP  => 2,
    SO_EE_ORIGIN_ICMP6 => 3,
};


=item new()

Return a new IO::EventMux::Socket::MsgHdr object.  Optional PARAMETERS may specify method
names (C<buf>, C<name>, C<control>, C<flags> or their corresponding I<...len>
methods where applicable) and values, sparing an explicit call to those
methods.

=cut

sub new {
    my $class = shift;
    my $self = { name => undef, 
                 control => undef,
                 flags => 0 };
    
    bless $self, $class;

    my %args = @_;
    foreach my $m (keys %args) {
      $self->$m($args{$m});
    }

    return $self;
}


=item name [SCALAR]

Get or set the socket name (address) buffer, an attribute analogous to the
optional TO and FROM parameters of L<perlfunc/send> and L<perlfunc/recv>.
Note that socket names are packed structures.

=cut

sub name {
    my ($self, $var) = @_;
    $self->{name} = $var if defined $var;
    $self->{name};
}

=item namelen LENGTH

=cut

sub namelen {
    my ($self, $nlen) = @_;
    $self->_set_length("name", $nlen);
}

=item buf [SCALAR]

=cut

sub buf {
    my ($self, $var) = @_;
    $self->{buf} = $var if defined $var;
    $self->{buf};
}


=item buflen LENGTH

C<buf> gets the current message buffer or sets it to SCALAR.  C<buflen>
allocates LENGTH bytes for use in L<recvmsg>.

=cut

sub buflen {
    my ($self, $nlen) = @_;
    $self->_set_length("buf",$nlen);
}

=item control()

=cut

sub control {
    my ($self, $var) = @_;
    $self->{control} = $var if defined $var;
    $self->{control};
}


=item controllen LENGTH

Prepare the ancillary data buffer to receive LENGTH bytes.  There is a
corresponding C<control> method, but its use is discouraged -- you have to
L<perlfunc/pack> the C<struct cmsghdr> yourself.  Instead see L<cmsghdr> below
for convenient access to the control member.

=cut

sub controllen {
    my ($self, $nlen) = @_;
    $self->_set_length("control",$nlen);
}

=item flags [FLAGS]

Get or set the IO::EventMux::Socket::MsgHdr flags, distinct from the L<sendmsg> or
L<recvmsg> flags.  Example:

  $hdr = new IO::EventMux::Socket::MsgHdr (buflen => 512, controllen => 3);
  recvmsg(IN, $hdr);
  if ($hdr->flags & MSG_CTRUNC) {   # &Socket::MSG_CTRUNC
    warn "Yikes!  Ancillary data was truncated\n";
  }

=cut

sub flags {
    my ($self, $var) = @_;
    $self->{flags} = $var if defined $var;
    $self->{flags};
}

=item cmsghdr LEVEL, TYPE, DATA [ LEVEL, TYPE, DATA ... ]

Without arguments, this method returns a list of "LEVEL, TYPE, DATA, ...", or
an empty list if there is no ancillary data.  With arguments, this method
copies and flattens its parameters into the internal control buffer.

In any case, DATA is in a message-specific format which likely requires
special treatment (packing or unpacking).

Examples:

   my @cmsg = $hdr->cmsghdr();
   while (my ($level, $type, $data) = splice(@cmsg, 0, 3)) {
     warn "unknown cmsg LEVEL\n", next unless $level == IPPROTO_IPV6;
     warn "unknown cmsg TYPE\n", next unless $type == IPV6_PKTINFO;
     ...
   }

   my $data = pack("i" x @filehandles, map {fileno $_} @filehandles);
   my $hdr->cmsghdr(SOL_SOCKET, SCM_RIGHTS, $data);
   sendmsg(S, $hdr);

=cut

sub cmsghdr {
  my $self = shift;
  unless (@_) { return &unpack_cmsghdr($self->{control}); }
  $self->{control} = &pack_cmsghdr(@_);
}

=item sendmsg SOCKET, MSGHDR

=item sendmsg SOCKET, MSGHDR, FLAGS

Send a message as described by C<IO::EventMux::Socket::MsgHdr> MSGHDR over SOCKET,
optionally as specified by FLAGS (default 0).  MSGHDR should supply
at least a I<buf> member, and connectionless socket senders might
also supply a I<name> member.  Ancillary data may be sent via
I<control>.

Returns number of bytes sent, or undef on failure.

=item recvmsg SOCKET, MSGHDR

=item recvmsg SOCKET, MSGHDR, FLAGS

Receive a message as requested by C<IO::EventMux::Socket::MsgHdr> MSGHDR from
SOCKET, optionally as specified by FLAGS (default 0).  The caller
requests I<buflen> bytes in MSGHDR, possibly also recording up to
I<namelen> bytes of the sender's (packed) address and perhaps
I<controllen> bytes of ancillary data.

Returns number of bytes received, or undef on failure.  I<buflen>
et. al. are updated to reflect the actual lengths of received data.

=item pack_cmsghdr

=item unpack_cmsghdr

=cut

require XSLoader;
XSLoader::load('IO::EventMux::Socket::MsgHdr', $VERSION);


# Module import
# =============
#
sub import {
  require Exporter;
  goto &Exporter::import;
}

sub _set_length {
    my ($self, $attr, $nlen) = @_;
    my $olen = length($self->{$attr} or '');
    return $olen unless defined $nlen;
    
    if ($nlen != $olen) {
        $self->{$attr} = $olen > $nlen
        ? substr($self->{$attr}, 0, $nlen) 
        : "\x00" x $nlen;
    }
    return $nlen;
}

=item B<socket_errors($socket)> 

Read "MSG_ERRQUEUE" errors on socket and decode ICMP error msg 

=cut

sub socket_errors {
    my ($sock) = @_;
    
    my @results;
    my $msgHdr = new IO::EventMux::Socket::MsgHdr(
        buflen => 512,
        controllen => 256,
        namelen => 16,
    );
    
    # Copy errors to msgHdr
    my $old_errno = $!;
    my $rv = recvmsg($sock, $msgHdr, MSG_ERRQUEUE);
    if(not defined $rv) {
        if($old_errno != $! and $! != EAGAIN) {
            print "error(socket_errors):$!\n";
        }
        return;
    }
    
    # Unpack errors
    my @cmsg = $msgHdr->cmsghdr();
    while (my ($level, $type, $data) = splice(@cmsg, 0, 3)) {
        if($level == SOL_IP and $type == IP_RECVERR) {
            my ($from, $dst_ip, $dst_port, $pkt);

            # struct sock_extended_err from man recvmsg
            my ($ee_errno, $ee_origin, $ee_type, $ee_code, $ee_pad, 
                $ee_info, $ee_data, $ee_other) = unpack("ICCCCIIa*", $data);
            
            if($ee_origin == SO_EE_ORIGIN_NONE) {
                print "error(socket_errors): origin is none??\n";
                next;
            
            } elsif($ee_origin == SO_EE_ORIGIN_LOCAL) {
                $from = 'localhost';

            } elsif($ee_origin == SO_EE_ORIGIN_ICMP) {
                # Get offender ip($from)(the one who sent the ICMP message)
                # and $dst_ip and $dst_port from packet in ICMP packet.
                ($from, $dst_ip, $dst_port) = (
                    inet_ntoa((unpack_sockaddr_in($ee_other))[1]),
                    inet_ntoa((unpack_sockaddr_in($msgHdr->name))[1]),
                    (unpack_sockaddr_in($msgHdr->name))[0]
                );
                
                # Get what's left of the packet
                $pkt = $msgHdr->buf; 
           
            } elsif($ee_origin == SO_EE_ORIGIN_ICMP6) {
                die "IPv6 not supported, patches welcome"; 
            }

            if($ee_errno == ECONNREFUSED) {
                push(@results, {
                    type => 'error',
                    errno => $ee_errno,
                    error => strerror($ee_errno),
                    from => $from, 
                    dst_ip => $dst_ip,
                    dst_port => $dst_port, 
                    data => $pkt,
                    fh => $sock,
                });
	        } elsif($ee_errno == EMSGSIZE) {
                push(@results, {
                    type => 'error',
                    errno => $ee_errno, 
                    error => strerror($ee_errno),
                    mtu => $ee_info, 
                    fh => $sock,
                });
            } elsif($ee_errno == ETIMEDOUT or $ee_errno == EPROTO 
                    or $ee_errno == EHOSTUNREACH or $ee_errno == ENETUNREACH
                    or $ee_errno == EACCES) {
                push(@results, {
                    type => 'error',
                    fh => $sock,
                    errno => $ee_errno, 
                    error => strerror($ee_errno),
                });
            } else {
                push(@results, {
                    type => 'error',
                    fh => $sock,
                    errno => $ee_errno, 
                    error => strerror($ee_errno),
                });
            }
      
        } else {
            print "error(socket_errors): unknown type: $type and/or $level\n";
        }
    }
    return @results;
}

=back

=head1 EXPORT

C<IO::EventMux::Socket::MsgHdr> exports L<sendmsg> and L<recvmsg> by default into the
caller's namespace, and in any case these methods into the IO::Socket
namespace.

=head2 BUGS

The underlying XS presently makes use of RFC 2292 CMSG_* manipulation macros,
which may not be available on all systems supporting sendmsg/recvmsg as known
to 4.3BSD Reno/POSIX.1g.  Older C<struct msghdr> definitions with
C<msg_accrights> members (instead of C<msg_control>) are not supported at all.

There is no Socket::CMsgHdr, which may be a good thing.  Examples are meager,
see the t/ directory for send(to) and recv(from) emulations in terms of this
module.

=head1 SEE ALSO

L<sendmsg(2)>, L<recvmsg(2)>, L<"RFC 2292">

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk>

=head1 COPYRIGHT AND LICENSE

Copyright(C) 2007-2008 by Troels Liebe Bentsen
Copyright(C) 2003 by Michael J. Pomraning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
