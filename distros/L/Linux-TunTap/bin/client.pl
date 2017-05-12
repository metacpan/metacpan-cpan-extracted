#!/usr/bin/perl -w
require 5.005;
use strict;

### configuration:

# IP address of this machine
use constant IP => '192.168.42.1';
# Netmask of tunnel
use constant NETMASK => '255.255.255.0';
# IP of default route, or undef if you don't want to set one.
use constant DEFAULTROUTE => undef;
# The zone that the tunnel is in. There should be a corresponding NS record
# with this name in the public DNS that ultimately points to a host running
# the server side of the tunnel.
use constant ZONE => 'host.example.com';
# The IP address of the DNS resolver we are tunneling through. Set to undef
# if you want the system default (e.g. the one picked up by DHCP) to be
# used.
use constant RESOLVER => '123.456.789.012';
# Maximum packet size. If you make this too high, the tunnel will fail.
# Making it too low makes the tunnel too inefficient. Minimum is 68, safe
# value is 128. 168 is the next "round" number. The maximum depends on the
# domain name we're using, but is around 180-200.
use constant MTU => 168;

# Net::DNS::Resolver doesn't expose a file descriptor for us to select() on,
# so we have to poll instead when (and only when) we're expecting server
# replies. This is how often polls are made (in seconds). Too low will
# increase CPU load, too high will increase latency and network throughput.
use constant POLL_RATE => 0.01;
# The minimum time (in seconds) to wait before sending a null packet.
# kernel gives us a packet.
use constant MIN_DELAY => 0.01;
# This is the maximum time (in seconds) to wait before sending a null packet.
use constant MAX_DELAY => 3;

# How long we should wait until we've decided we're not going to get a
# response to a query.
use constant RESPONSE_TIMEOUT => 10;

### Code follows, here be dragons:

use Net::DNS;
use Data::Dumper;
use MIME::Base64;

use Linux::TunTap;

use common;

my Linux::TunTap $tun=new Linux::TunTap();

my $dev=$tun->{interface};

system "ifconfig", $dev, IP, 'netmask', NETMASK, 'mtu', MTU, 'up';

if(defined DEFAULTROUTE) {
  system "route", "add", "default", "gw", DEFAULTROUTE;
}

# A sequence number is encoded into the packet to guarantee uniqueness so it
# isn't cached. It could start at zero, but it doesn't hurt to add some
# randomness from the clock.
my $seq=time<<8;

# the resolver object
my $res=new Net::DNS::Resolver(
			       # spot the cruft
			       (defined RESOLVER)?(nameservers => [ RESOLVER ]):(),
			      );

# handles on DNS queries we've sent but not yet dealt with replies
my @sent;

my $delay=MIN_DELAY;
while(1) {
  if(@sent) {
    print "Queue size: ", scalar(@sent), " - in fast mode\n";
    while(@sent) {
      # cause a handy delay at the poll rate as a side-effect
      my $data=$tun->get_raw(POLL_RATE);
      # The oldest a response can possibly be
      my $oldest=time-RESPONSE_TIMEOUT;
      # now check all the pending replies
      foreach my $sent (@sent) {
	my $handle=$sent->[0];
	if($res->bgisready($handle)) {
	  # we have a reply
	  my $packet=tunnel_handle_reply($res->bgread($handle));
	  $delay=MIN_DELAY
	    if length $packet;
	  undef $sent;	# marks for deletion from list and closes socket too
	} elsif($sent->[1]<$oldest) {
	  undef $sent;
	}
      }
      @sent=grep { defined } @sent; # delete any undeffed elements
      tunnel_send($data)
	if $data;
    }
  } else {
    print "Empty queue - in slow mode, will wait $delay secs\n";
    # No inbound traffic expected, it's a lazy time.
    #print "going to wait $delay seconds\n";
    my $data=$tun->get_raw($delay);
    # whether or not we got a packet, we send something over the link anyway.
    tunnel_send($data);
    $delay*=1.5;
    $delay=MAX_DELAY if $delay>MAX_DELAY;
  }
}

# sends the packet through the tunnel
sub tunnel_send {
  my($packet)=@_;

  my $name=encode_name($packet, $seq++);

  $name.=".".ZONE;
  decode_name($name);
  #print "Name size: ", length($name), "\n";
  my $handle=$res->bgsend($name, "TXT");
  push @sent, [$handle, time];
}

sub tunnel_handle_reply {
  my($dnspacket)=@_;
  die "undefined packet response"
    unless defined $dnspacket;
  my @answer = $dnspacket->answer;
  # there should be exactly one TXT record, but we'll process all replies anyway
  foreach my $rr (@answer) {
    next unless $rr->type eq 'TXT';
    my $packet=decode_txt($rr->txtdata);
    $tun->put_raw($packet);
    return $packet;
  }
}
