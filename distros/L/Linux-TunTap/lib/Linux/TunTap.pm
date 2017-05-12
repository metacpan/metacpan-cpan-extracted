# Copyright (C) 2004 Peter Corlett. All Rights Reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc., 59
# Temple Place, Suite 330, Boston, MA 02111-1307 USA

package Linux::TunTap;
require 5.005;
use fields qw( interface _fh );
use strict;
use vars qw( $VERSION );
# $Id: TunTap.pm,v 1.1 2004/07/15 11:20:11 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Carp;
use IO::File;

# Magic Linux kernel constants:

# These came from /usr/include/linux/if_tun.h on a Debian system
# Package containing that is linux-kernel-headers 2.5.999-test7-bk-15

# Number of devices
use constant TUN_MAX_DEV => 255;
# TX queue size
use constant TUN_TXQ_SIZE => 10;
# Max frame size
use constant TUN_MAX_FRAME => 4096;
# TUN device flags
use constant TUN_TUN_DEV    => 0x0001;
use constant TUN_TAP_DEV    => 0x0002;
use constant TUN_TYPE_MASK  => 0x000f;
use constant TUN_FASYNC     => 0x0010;
use constant TUN_NOCHECKSUM => 0x0020;
use constant TUN_NO_PI      => 0x0040;
use constant TUN_ONE_QUEUE  => 0x0080;
use constant TUN_PERSIST    => 0x0100;
# Ioctl defines
use constant TUNSETNOCSUM => 0x400454c8;
use constant TUNSETDEBUG => 0x400454c9;
use constant TUNSETIFF => 0x400454ca;
use constant TUNSETPERSIST => 0x400454cb;
use constant TUNSETOWNER => 0x400454cc;
# TUNSETIFF ifr flags
use constant IFF_TUN   => 0x0001;
use constant IFF_TAP   => 0x0002;
use constant IFF_NO_PI => 0x1000;
use constant IFF_ONE_QUEUE => 0x2000;
use constant TUN_PKT_STRIP => 0x0001;

# The kernel headers are a horror of #defines and nested structs and unions,
# but this is the edited highlight:
# struct ifreq { char ifrn_name[16]; short ifru_flags; };
use constant STRUCT_IFREQ => 'Z16 s';

# Where the tunnel device appears in Linux 2.4.
use constant TUNNEL_DEVICE => '/dev/net/tun';

=head1 NAME

Linux::TunTap - Userspace network device

=head1 SYNOPSIS

 use Linux::TunTap;

 my $tap=new Linux::TunTap;

 while(my $packet=get_raw()) {
   # do something with the data, e.g. send it down a tunnel
 }

=head1 DESCRIPTION

This is an object-oriented Perl module that interfaces with the Linux tuntap
driver. tuntap is a virtual network device that sends and receives packets
to and from userspace rather than a physical interface.

The normal use of the tuntap device is to write tunnels and bridges between
networks. This would tend to imply that you have two hosts on separate
networks as the endpoints, and some means of passing data between the tunnel
endpoints, e.g. by wrapping the unsupported or firewalled data in a protocol
that may pass.

Configuration of a tunnel and the security implications of doing so are out
of the scope of this document.

If your problem is more one of wanting to inspect passing packets, rather
than receiving packets and sending replies, you may find that
L<IPTables::IPv4::IPQueue> suits your needs better.

=head1 ATTRIBUTES

=over 2

=item interface

 my $if=$tun->{interface};

Retrieves the name of the tuntap interface, e.g. "tun0".

=back

=head1 METHODS

=over 2

=item new( I<< [ PARAM => value, ... ] >> )

This creates a new tuntap interface and returns a handle to it.

Parameters: NAME.

  my $tap=new Linux::TunTap;
  my $tap2=new Linux::TunTap(NAME => 'tap%d');

If you specify NAME, it will attempt to create a tuntap device with that
name. You may put a C<%d> format specifier into the name, to ensure
uniqueness.

It will throw an exception if the tuntap interface could not be created.
Your attention is drawn to L</"SYSTEM REQUIREMENTS"> which discusses what is
required for successful creation of an interface.

=cut

sub new {
  my($class, %args)=@_;

  # create new object
  my Linux::TunTap $self;
  $self=fields::new($class);

  # FIXME BUG: Only tries Linux 2.4 style device
  my $fh=new IO::File(TUNNEL_DEVICE, 'r+')
    or croak "Can't open ".TUNNEL_DEVICE.": $!";

  # FIXME: we've hardwired IFF_TUN - we get packet type (i.e. IPv4, IPv6,
  # possibly ARP, etc) and payload, but not the Ethernet header
  my $ifr=pack(STRUCT_IFREQ, $args{NAME}||'', IFF_TUN);
  ioctl $fh, TUNSETIFF, $ifr
    or croak "Can't ioctl() tunnel: $!";
  $self->{interface}=unpack STRUCT_IFREQ, $ifr;
  $self->{_fh}=$fh;

  return $self;
}

sub DESTROY {
  my Linux::TunTap $self=shift;

  $self->{_fh}->close
    if $self->{_fh};
}

=item get_raw( I<< [ timeout ] >> )

 my $packet=$tun->get_raw();

This reads a raw packet from the tunnel, with an optional timeout. If the
timeout is omitted, this will block until data is available. Otherwise, the
timeout value is the maximum time in seconds to wait. If there is a timeout,
an empty string is returned.

The raw packet is returned if it could be read, otherwise undef will be
returned to indicate an I/O error (use $! to find out what that error was.)

In this context, raw means the raw output of tuntap, which includes a four
byte header prepended to the IP (or whatever) packet. The output of
get_raw() is suitable for using as an argument for put_raw() to reinject the
packet.

=cut

sub get_raw {
  my Linux::TunTap $self=shift;
  my($timeout)=@_;

  my($rin, $win, $ein);
  my($rout, $wout, $eout);
  $rin = $win = $ein = '';
  vec($rin,fileno($self->{_fh}),1) = 1;
  #vec($win,fileno(STDOUT),1) = 1;
  $ein = $rin | $win;

  my($nfound,$timeleft) =
    select($rout=$rin, $wout=$win, $eout=$ein, $timeout);

  if($nfound==0) {
    return '';
  }
  my $iobuf;
  my $ret=sysread $self->{_fh}, $iobuf, TUN_MAX_FRAME;
  # a failed read() returns undef.
  return undef unless defined $ret;
  # EOF will return an empty string (although I'm not quite sure when we'd
  # see that)
  return $iobuf;
}

=item put_raw( I<< packet >> )

 $tun->get_raw($packet)
   or die "Failed to send to network: $!";

This write a raw packet to the tunnel. A false value will be returned if the
write failed, if it was undef, $! will say what the error was.

=cut

# returns undef on error
sub put_raw {
  my Linux::TunTap $self=shift;
  my($iobuf)=@_;

  my $ret=syswrite $self->{_fh}, $iobuf;
  return $ret;
}

=back

=head1 SYSTEM REQUIREMENTS

You need a kernel with tuntap, either compiled in, or as a module. The
module's name is F<tun.o>. Currently, only Linux 2.4 is supported. Linux 2.2
tuntap has a different API and is currently I<not> supported by this module.
Linux 2.6 is untested.

You also need the tuntap device node, a character special file with the name
F</dev/net/tun> with major number 10 and minor number 200. You can create it
like this:

 # mkdir /dev/net
 # mknod /dev/net/tun c 10 200
 # chmod 0700 /dev/net/tun

Your script needs to have appropriate permissions to access F</dev/net/tun>.
If created as described, you will need to run as root.

=head1 WARNINGS

Because Linux will not generally allow you to run commands such as
L<ifconfig(8)> as a non-root user, you will usually find that your script
will need to run as root unless you make special arrangements.

You are playing with raw network packets in the kernel. This means that you
have somewhat more low-level access to the network than is normally allowed
by mere mortals. It might be possible (although unlikely) to cause a kernel
panic through careless use.

Creating tunnels to bypass firewalls may be a violation of your terms of
service and/or a criminal offence.

As you are running as root, taking arbitrary unchecked data from the public
Internet, and creating a weak spot in the security infrastructure, now is an
excellent time to read up on taint mode.

=head1 SEE ALSO

The Linux documentation on tuntap in the kernel source:
F<.../Documentation/networking/tuntap.txt>.

The many RFCs on IP networking: L<http://www.rfc-editor.org/rfc.html>.

Hall, Eric A. I<Internet Core Protocols.> Sebastopol, CA: O'Reilly &
Associates Inc., 2000. ISBN 1-56592-572-6.

=head1 BUGS

Only Linux 2.4 style tuntap devices are supported.

No means to inspect Ethernet frames is provided.

=head1 COPYRIGHT

Copyright (c) 2004 Peter Corlett <abuse@cabal.org.uk>. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.

=cut

1;
