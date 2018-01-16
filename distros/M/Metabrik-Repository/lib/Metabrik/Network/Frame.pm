#
# $Id: Frame.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::frame Brik
#
package Metabrik::Network::Frame;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable packet ip tcp udp icmp eth ethernet arp) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         device_info => [ qw(device_info_hash) ],
      },
      commands => {
         get_device_info => [ qw(device|OPTIONAL) ],
         update_device_info => [ qw(device|OPTIONAL) ],
         from_read => [ qw(frame|$frame_list) ],
         to_read => [ qw(simple|$simple_list) ],
         from_hexa => [ qw(hexa first_layer|OPTIONAL) ],
         from_raw => [ qw(raw first_layer|OPTIONAL) ],
         show => [ ],
         mac2eui64 => [ qw(mac_address) ],
         frame => [ qw(layers_array) ],
         arp => [ qw(destination_ipv4_address|OPTIONAL destination_mac|OPTIONAL) ],
         eth => [ qw(destination_mac|OPTIONAL type|OPTIONAL) ],
         ipv4 => [ qw(destination_ipv4_address protocol|OPTIONAL source_ipv4_address|OPTIONAL) ],
         tcp => [ qw(destination_port source_port|OPTIONAL flags|OPTIONAL) ],
         udp => [ qw(destination_port source_port|OPTIONAL payload|OPTIONAL) ],
         icmpv4 => [ ],
         echo_icmpv4 => [ ],
         is_read => [ qw(data) ],
         is_simple => [ qw(data) ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
         'Net::Frame::Layer::ARP' => [ ],
         'Net::Frame::Layer::ETH' => [ ],
         'Net::Frame::Layer::IPv4' => [ ],
         'Net::Frame::Layer::IPv6' => [ ],
         'Net::Frame::Layer::TCP' => [ ],
         'Net::Frame::Layer::UDP' => [ ],
         'Net::Frame::Layer::ICMPv4' => [ ],
         'Net::Frame::Layer::ICMPv6' => [ ],
         'Metabrik::String::Hexa' => [ ],
         'Metabrik::Network::Device' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => defined($self->global) && $self->global->device || 'eth0',
      },
   };
}

sub brik_init {
   my $self = shift;

   $self->update_device_info
      or return $self->log->error("brik_init: update_device_info failed, you may not have a global device set");

   return $self->SUPER::brik_init(@_);
}

sub get_device_info {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;

   my $nd = Metabrik::Network::Device->new_from_brik_init($self) or return;

   my $device_info = $nd->get($device) or return;

   $self->log->debug("get_device_info: got info from device [$device]");

   return $device_info;
}

sub update_device_info {
   my $self = shift;
   my ($device) = @_;

   return $self->device_info($self->get_device_info($device));
}

sub from_read {
   my $self = shift;
   my ($frames) = @_;

   $self->brik_help_run_undef_arg('from_read', $frames) or return;
   my $ref = $self->brik_help_run_invalid_arg('from_read', $frames, 'HASH', 'ARRAY')
      or return;

   # We accept a one frame Argument...
   if ($ref eq 'HASH') {
      if (! exists($frames->{raw})
      ||  ! exists($frames->{firstLayer})
      ||  ! exists($frames->{timestamp})) {
         return $self->log->error("from_read: frames Argument is not an array of valid next HASHREFs");
      }
      else {
         return Net::Frame::Simple->newFromDump($frames);
      }
   }

   # Or an ARRAY or frames
   if ($ref ne 'ARRAY') {
      return $self->log->error("from_read: frames Argument must be an ARRAYREF");
   }
   if (@$frames <= 0) {
      return $self->log->error("from_read: frames Argument is empty");
   }
   my $first = $frames->[0];
   if (ref($first) ne 'HASH') {
      return $self->log->error("from_read: frames Argument is not an array of next HASHREFs");
   }
   if (! exists($first->{raw})
   ||  ! exists($first->{firstLayer})
   ||  ! exists($first->{timestamp})) {
      return $self->log->error("from_read: frames Argument is not an array of valid next HASHREFs");
   }

   my @simple = ();
   for my $h (@$frames) {
      my $simple = Net::Frame::Simple->newFromDump($h) or next;
      push @simple, $simple;
   }

   return \@simple;
}

sub to_read {
   my $self = shift;
   my ($frame) = @_;

   $self->brik_help_run_undef_arg('to_read', $frame) or return;
   my $ref = $self->brik_help_run_invalid_arg('to_read', $frame, 'ARRAY', 'Net::Frame::Simple')
      or return;

   my $first = $ref eq 'ARRAY' ? $frame->[0] : $frame;
   if ($ref eq 'ARRAY') {
      # We just check the first item in the list.
      if (ref($first) eq 'Net::Frame::Simple') {
         my @read = ();
         for my $simple (@$frame) {
            push @read, {
               timestamp => $simple->timestamp,
               firstLayer => $simple->firstLayer,
               raw => $simple->raw,
            };
         }
         return \@read;
      }
      else {
         return $self->log->error("to_read: frame ARRAYREF must contain Net::Frame::Simple objects");
      }
   }
   elsif ($ref eq 'Net::Frame::Simple') {
      my $h = {
         timestamp => $frame->timestamp,
         firstLayer => $frame->firstLayer,
         raw => $frame->raw,
      };
      return $h;
   }

   return $self->log->error("to_read: unknown error occured");
}

sub from_hexa {
   my $self = shift;
   my ($data, $first_layer) = @_;

   $first_layer ||= 'IPv4';
   $self->brik_help_run_undef_arg('from_hexa', $data) or return;

   my $sh = Metabrik::String::Hexa->new_from_brik_init($self) or return;

   if (! $sh->is_hexa($data)) {
      return $self->log->error('from_hexa: data is not hexa');
   }

   my $raw = $sh->decode($data) or return;

   my $frame;
   eval {
      $frame = Net::Frame::Simple->new(raw => $raw, firstLayer => $first_layer);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("from_hexa: cannot parse frame, not a $first_layer first layer? [$@]");
   }

   return $frame;
}

sub from_raw {
   my $self = shift;
   my ($raw, $first_layer) = @_;

   $self->brik_help_run_undef_arg('from_raw', $raw) or return;

   return $self->from_hexa(unpack('H*', $raw), $first_layer);
}

sub show {
   my $self = shift;
   my ($frame) = @_;

   $self->brik_help_run_undef_arg('show', $frame) or return;
   $self->brik_help_run_invalid_arg('show', $frame, 'Net::Frame::Simple') or return;

   my $str = $frame->print;

   print $str."\n";

   return 1;
}

# http://tools.ietf.org/html/rfc2373
sub mac2eui64 {
   my $self = shift;
   my ($mac) = @_;

   $self->brik_help_run_undef_arg('mac2eui64', $mac) or return;

   my @b  = split(':', $mac);
   my $b0 = hex($b[0]) ^ 2;

   return sprintf("fe80::%x%x:%xff:fe%x:%x%x", $b0, hex($b[1]), hex($b[2]),
      hex($b[3]), hex($b[4]), hex($b[5]));
}

# Returns an ARP header with a set of default values
sub arp {
   my $self = shift;
   my ($dst_ip, $dst_mac) = @_;

   my $device_info = $self->device_info;

   $dst_ip ||= '127.0.0.1';
   $dst_mac ||= '00:00:00:00:00:00';

   my $hdr = Net::Frame::Layer::ARP->new(
      #opCode => NF_ARP_OPCODE_REQUEST,  # Default
      srcIp => $device_info->{ipv4},
      dstIp => $dst_ip,
      src => $device_info->{mac},
      dst => $dst_mac,
   );

   return $hdr;
}

# Returns an Ethernet header with a set of default values
sub eth {
   my $self = shift;
   my ($dst, $type) = @_;

   my $device_info = $self->device_info;

   $dst ||= 'ff:ff:ff:ff:ff:ff'; # Broadcast
   $type ||= 0x0800; # IPv4

   my $hdr = Net::Frame::Layer::ETH->new(
      src => $device_info->{mac},
      dst => $dst,
      type => $type,
   );

   return $hdr;
}

sub ipv4 {
   my $self = shift;
   my ($dst, $protocol, $src) = @_;

   $protocol ||= 6;  # TCP
   $self->brik_help_run_undef_arg('ipv4', $dst) or return;

   my $device_info = $self->device_info;
   $src ||= $device_info->{ipv4};

   my $hdr = Net::Frame::Layer::IPv4->new(
      src => $src,
      dst => $dst,
      protocol => $protocol,
   );

   return $hdr;
}

sub tcp {
   my $self = shift;
   my ($dst, $src, $flags) = @_;

   $src ||= 1025;
   $flags ||= 0x02;   # SYN
   $self->brik_help_run_undef_arg('tcp', $dst) or return;

   return Net::Frame::Layer::TCP->new(
      dst => $dst,
      src => $src,
      flags => $flags,
   );
}

sub udp {
   my $self = shift;
   my ($dst, $src, $payload) = @_;

   $src ||= 1025;
   $payload ||= '';
   $self->brik_help_run_undef_arg('udp', $dst) or return;

   return Net::Frame::Layer::UDP->new(
      dst => $dst,
      src => $src,
      length => length($payload),
   )->pack.$payload;
}

sub icmpv4 {
   my $self = shift;

   my $hdr = Net::Frame::Layer::ICMPv4->new;

   return $hdr;
}

sub echo_icmpv4 {
   my $self = shift;
   my ($data) = @_;

   $data ||= 'echo';

   my $hdr = Net::Frame::Layer::ICMPv4::Echo->new(
      payload => $data,
   );

   return $hdr;
}

sub frame {
   my $self = shift;
   my ($layers) = @_;

   $self->brik_help_run_undef_arg('frame', $layers) or return;
   $self->brik_help_run_invalid_arg('frame', $layers, 'ARRAY') or return;

   my $request = Net::Frame::Simple->new(
      layers => $layers,
   );

   return $request;
}

sub is_read {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('is_read', $data) or return;

   if (ref($data) eq 'HASH'
   &&  exists($data->{raw})
   &&  exists($data->{firstLayer})
   &&  exists($data->{timestamp})) {
      return 1;
   }

   return 0;
}

sub is_simple {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('is_simple', $data) or return;

   if (ref($data) eq 'Net::Frame::Simple') {
      return 1;
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Network::Frame - network::frame Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
