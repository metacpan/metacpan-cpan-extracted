#!/usr/bin/perl -w
require 5.005;
use strict;

### configuration:

# IP address of this machine
use constant IP => '192.168.42.2';
# Netmask of tunnel
use constant NETMASK => '255.255.255.0';
# The zone that the tunnel is in. There should be a corresponding NS record
# with this name in the public DNS that ultimately points to a host running
# the server side of the tunnel.
use constant ZONE => 'host.example.com';
# Maximum packet size. If you make this too high, the tunnel will fail.
# Making it too low makes the tunnel too inefficient. Minimum is 68, safe
# value is 128. 168 is the next "round" number. The maximum depends on the
# domain name we're using, but is around 180-200.
use constant MTU => 168;
# The maximum time (in seconds) to delay replying to a query to see if the
# kernel gives us a packet.
use constant MAX_DELAY => 0.25;

### Code follows, here be dragons:

use Net::DNS;
use Net::DNS::Nameserver;
use Data::Dumper;
use MIME::Base64;

use Linux::TunTap;

use common;

my Linux::TunTap $tun=new Linux::TunTap();

my $dev=$tun->{interface};

system "ifconfig", $dev, IP, 'netmask', NETMASK, 'mtu', MTU, 'up';

sub reply_handler {
  my ($name, $class, $type, $arg)=@_;

  return undef unless $type eq 'TXT';

  my $packet=decode_name($name);
  if(length $packet) {
    defined $tun->put_raw($packet)
      or warn "Couldn't send packet: $!";
  }

  # now for (any) return packet
  $packet=$tun->get_raw(MAX_DELAY);
  my $txt=encode_txt($packet);

  return (
	  'NOERROR',		# status
	  [ new Net::DNS::RR("$name 2 IN TXT \'$txt\'") ], # answer
	  [],			# authority
	  [], 			# additional data
	  { aa => 1 }		# it's an authoritative answer
	 );
}

my $ns=new Net::DNS::Nameserver(
				LocalPort => 53,
				ReplyHandler => \&reply_handler,
				#Verbose => 1
			       )
  or die "Can't create nameserver";

$ns->main_loop;
