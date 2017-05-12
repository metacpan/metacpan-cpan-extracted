#
# $Id: Device.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# network::device Brik
#
package Metabrik::Network::Device;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable interface) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         enable_warnings => [ qw(0|1) ],
      },
      attributes_default => {
         enable_warnings => 0,
      },
      commands => {
         install => [ ], # Inherited
         list => [ ],
         get => [ qw(device|OPTIONAL) ],
         default => [ qw(destination_ip|OPTIONAL) ],
         show => [ qw(device_array|OPTIONAL) ],
         internet_address => [ ],
         my_ipv4 => [ qw(device|OPTIONAL) ],
         my_ipv6 => [ qw(device|OPTIONAL) ],
      },
      require_modules => {
         'Net::Libdnet::Intf' => [ ],
         'Net::Pcap' => [ ],
         'Net::Routing' => [ ],
         'Net::IPv4Addr' => [ ],
         'Metabrik::Client::Www' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libpcap-dev libnet-libdnet-perl) ],
         debian => [ qw(libpcap-dev libnet-libdnet-perl) ],
         freebsd => [ qw(p5-Net-Pcap libdnet) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub list {
   my $self = shift;

   my $dev = {};
   my $err = '';
   my @devs = Net::Pcap::findalldevs($dev, \$err);
   if (length($err)) {
      return $self->log->error("list: findalldevs failed with error [$err]");
   }
   elsif (@devs == 0) {
      return $self->log->error("list: findalldevs found no device");
   }

   return \@devs;
}

sub get {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   $self->brik_help_run_undef_arg('get', $device) or return;

   my $intf = Net::Libdnet::Intf->new;
   if (! defined($intf)) {
      $self->enable_warnings
         && $self->log->warning("get: Net::Libdnet::Intf new failed for device [$device]");
      return {};
   }

   my $get = $intf->get($device);
   if (! defined($get)) {
      $self->enable_warnings
         && $self->log->error("get: Net::Libdnet::Intf get failed for device [$device]");
      return {};
   }

   # Populate HASH from Net::Libdnet::Entry::Intf object
   my $dev = {
      device => $device,
   };

   if (my $ip = $get->ip) {
      $dev->{ipv4} = $ip;
   }
   if (my $broadcast = $get->broadcast) {
      $dev->{broadcast} = $get->broadcast;
   }
   if (my $netmask = $get->cidr2mask) {
      $dev->{netmask} = $get->cidr2mask;
   }
   if (my $cidr = $get->cidr) {
      $dev->{cidr} = $cidr;
   }
   if (my $mac = $get->linkAddr) {
      $dev->{mac} = $mac;
   }
   my $cidr;
   my $subnet;
   if ($subnet = $get->subnet and $cidr = $get->cidr) {
      $dev->{subnet4} = "$subnet/$cidr";
   }
   my @aliases = $get->aliasAddrs;
   if (@aliases > 0) {
      # IPv6 are within aliases. First one if the main IPv6 address.
      if (defined($aliases[0])) {
         my $subnet6 = $aliases[0];
         (my $ipv6 = $subnet6) =~ s/\/\d+$//;
         $dev->{ipv6} = $ipv6;
         $dev->{subnet6} = $subnet6;
      }
   }

   return $dev;
}

sub default {
   my $self = shift;
   my ($destination) = @_;

   # Default route to Internet using Google DNS nameserver
   $destination ||= '8.8.8.8';

   my $family = Net::Routing::NR_FAMILY_INET4();

   my $nr = Net::Routing->new(
      target => $destination,
      family => $family,
   );
   if (! defined($nr)) {
      return $self->log->error("default: new failed: $Net::Routing::Error");
   }

   my $list = $nr->get
      or return $self->log->error("default: get failed: $Net::Routing::Error");
   # Only one possibility, that's great
   if (@$list == 1) {
      return $list->[0]->{interface};
   }
   # Or we return every possible interface
   else {
      my %interfaces = ();
      for my $i (@$list) {
         $interfaces{$i->{interface}}++;
      }
      return [ keys %interfaces ];
   }

   # Error
   return;
}

sub show {
   my $self = shift;
   my ($devices) = @_;

   $devices ||= $self->list or return;

   for my $this (@$devices) {
      $self->debug && $self->log->debug("show: found device [$this]");
      my $device = $self->get($this);
      if (! defined($device) || ! exists($device->{device})) {
         $self->enable_warnings
            && $self->log->warning("show: get failed for device [$this]");
         next;
      }

      printf("device: %s\nipv4: %s  subnet4: %s\nipv6: %s  subnet6: %s\n\n",
         $device->{device} || 'undef',
         $device->{ipv4} || 'undef',
         $device->{subnet4} || 'undef',
         $device->{ipv6} || 'undef',
         $device->{subnet6} || 'undef'
      );
   }

   return 1;
}

sub internet_address {
   my $self = shift;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   #my $url = 'http://ip.nu';
   my $url = 'http://www.whatsmyip.net/';
   my $get = $cw->get($url) or return;

   my $html = $get->{content};

   my ($ip) = $html =~ /(\d+\.\d+\.\d+\.\d+)/;

   return $ip || 'undef';
}

sub my_ipv4 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   $self->brik_help_run_undef_arg('my_ipv4', $device) or return;

   my $get = $self->get($device) or return;

   my $ip = $get->{ipv4};
   if (! defined($ip)) {
      return $self->log->error("my_ipv4: IPv4 address not found for device [$device]");
   }

   return $ip;
}

sub my_ipv6 {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   $self->brik_help_run_undef_arg('my_ipv6', $device) or return;

   my $get = $self->get($device) or return;

   my $ip = $get->{ipv6};
   if (! defined($ip)) {
      return $self->log->error("my_ipv6: IPv6 address not found for device [$device]");
   }

   return $ip;
}

1;

__END__

=head1 NAME

Metabrik::Network::Device - network::device Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
