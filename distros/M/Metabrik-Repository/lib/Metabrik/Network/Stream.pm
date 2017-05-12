#
# $Id: Stream.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# network::stream Brik
#
package Metabrik::Network::Stream;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         filter => [ qw(filter) ],
         protocol => [ qw(udp|tcp) ],
      },
      attributes_default => {
         filter => '',
         protocol => 'tcp',
      },
      commands => {
         from_pcap => [ qw(file filter|OPTIONAL) ],
         to_pcap => [ qw(stream file) ],
         list_source_ip_addresses => [ qw(stream) ],
         list_destination_ip_addresses => [ qw(stream) ],
         list_tcp_streams => [ qw($simple_frames_list) ],
         save_stream_payload => [ qw($simple_frames_list) ],
      },
      require_modules => {
         'Net::Frame::Layer::TCP' => [ ],
         'Net::Frame::Simple' => [ ],
         'Net::Frame::Dump::Writer' => [ ],
         'Metabrik::File::Pcap' => [ ],
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

sub from_pcap {
   my $self = shift;
   my ($file, $filter) = @_;

   $self->brik_help_run_undef_arg('from_pcap', $file) or return;
   $self->brik_help_run_file_not_found('from_pcap', $file) or return;

   $filter ||= $self->filter;

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($file, 'read', $filter) or return;

   my $src_ip;
   my $dst_ip;
   my $src_port;
   my $dst_port;
   my @stream = ();
   while (1) {
      my $h = $fp->read_next(10); # We read 10 by 10
      last if @$h == 0; # Eof
      for my $this (@$h) {
         my $simple = $fp->from_read($this) or next;
         my $network = $simple->ref->{IPv4} || $simple->ref->{IPv6};
         my $transport = $simple->ref->{TCP};

         if (defined($network) && defined($transport)) {
            my $this_src_ip = $network->src;
            my $this_dst_ip = $network->dst;
            my $this_src_port = $transport->src;
            my $this_dst_port = $transport->dst;
            # We found a new stream
            #if ($transport->flags == Net::Frame::Layer::TCP::NF_TCP_FLAGS_SYN()) {
               $src_ip = $this_src_ip;
               $dst_ip = $this_dst_ip;
               $src_port = $this_src_port;
               $dst_port = $this_dst_port;
               $self->log->info("from_pcap: new stream [$src_ip:$src_port] [$dst_ip:$dst_port]");
            #}

            next unless defined($src_ip);  # We haven't found a stream yet

            if (($this_src_ip eq $src_ip || $this_src_ip eq $dst_ip)
            &&  ($this_src_port eq $src_port || $this_src_port eq $dst_port)) {
               push @stream, $simple;
            }
         }
      }
   }

   my @data = ();
   for my $simple (@stream) {
      my $network = $simple->ref->{IPv4} || $simple->ref->{IPv6};
      my $transport = $simple->ref->{TCP};
      if (defined($transport) && length($transport->payload) && defined($network)) {
         $src_ip = $network->src;
         $dst_ip = $network->dst;
         $src_port = $transport->src;
         $dst_port = $transport->dst;
         my $payload = $transport->payload;
         $self->log->verbose("payload: $src_ip:$src_port > $dst_ip:$dst_port: [".unpack('H*', $payload)."]");
      }
   }

   return \@stream;
}

sub to_pcap {
   my $self = shift;
   my ($stream, $file) = @_;

   $self->brik_help_run_undef_arg('to_pcap', $file) or return;
   $self->brik_help_run_undef_arg('to_pcap', $stream) or return;
   $self->brik_help_run_invalid_arg('to_pcap', $stream, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('to_pcap', $stream) or return;

   my $first = $stream->[0];
   if (ref($first) ne 'Net::Frame::Simple') {
      return $self->log->error("to_pcap: stream must contains Net::Frame::Simple objects");
   }

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($file, 'write', $first->firstLayer) or return;
   my $frames = $fp->to_read($stream) or return;
   $fp->write($frames) or return;
   $fp->close;

   return 1;
}

sub list_source_ip_addresses {
   my $self = shift;
   my ($stream) = @_;

   $self->brik_help_run_undef_arg('list_source_ip_addresses', $stream) or return;
   $self->brik_help_run_invalid_arg('list_source_ip_addresses', $stream, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_source_ip_addresses', $stream) or return;

   if (ref($stream->[0]) ne 'Net::Frame::Simple') {
      return $self->log->error("list_source_ip_addresses: stream must contains Net::Frame::Simple objects");
   }

   my %src_ips = ();
   for my $simple (@$stream) {
      my $network = $simple->ref->{IPv4} || $simple->ref->{IPv6};
      if (defined($network)) {
         $src_ips{$network->src}++;
      }
   }

   return [ sort { $a cmp $b } keys %src_ips ];
}

sub list_destination_ip_addresses {
   my $self = shift;
   my ($stream) = @_;

   $self->brik_help_run_undef_arg('list_destination_ip_addresses', $stream) or return;
   $self->brik_help_run_invalid_arg('list_destination_ip_addresses', $stream, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_destination_ip_addresses', $stream) or return;

   if (ref($stream->[0]) ne 'Net::Frame::Simple') {
      return $self->log->error("list_destination_ip_addresses: stream must contains Net::Frame::Simple objects");
   }

   my %dst_ips = ();
   for my $simple (@$stream) {
      my $network = $simple->ref->{IPv4} || $simple->ref->{IPv6};
      if (defined($network)) {
         $dst_ips{$network->dst}++;
      } 
   }

   return [ sort { $a cmp $b } keys %dst_ips ];
}

sub list_tcp_streams {
   my $self = shift;
   my ($frames) = @_;

   $self->brik_help_run_undef_arg('list_tcp_streams', $frames) or return;
   $self->brik_help_run_invalid_arg('list_tcp_streams', $frames, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('list_tcp_streams', $frames) or return;

   if (ref($frames->[0]) ne 'Net::Frame::Simple') {
      return $self->log->error("list_tcp_streams: frames Argument must contain Net::Frame::Simple objects");
   }

   my %streams = ();
   for my $simple (@$frames) {
      my $transport = $simple->ref->{TCP} || next;
      my $network = $simple->ref->{IPv4} || $simple->ref->{IPv6} || next;

      my $src = $network->src;
      my $dst = $network->dst;
      my $src_port = $transport->src;
      my $dst_port = $transport->dst;

      my $id1 = "$src:$src_port-$dst:$dst_port"; # Try one way of dialog
      my $id2 = "$dst:$dst_port-$src:$src_port"; # Or the other
      if (exists($streams{$id1})) {
         push @{$streams{$id1}}, $simple;
      }
      else {
         push @{$streams{$id2}}, $simple;
      }
   }

   return \%streams;
}

sub save_stream_payload {
   my $self = shift;
   my ($frames) = @_;

   $self->brik_help_run_undef_arg('save_stream_payload', $frames) or return;
   $self->brik_help_run_invalid_arg('save_stream_payload', $frames, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('save_stream_payload', $frames) or return;

   if (ref($frames->[0]) ne 'Net::Frame::Simple') {
      return $self->log->error("save_stream_payload: frames Argument must contain Net::Frame::Simple objects");
   }

   my $data = '';
   for my $simple (@$frames) {
      my $transport = $simple->ref->{TCP} || $simple->ref->{UDP} || next;
      my $payload = $transport->payload or next;
      if (length($payload)) {
         $data .= $payload;
      }
   }

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Network::Stream - network::stream Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
