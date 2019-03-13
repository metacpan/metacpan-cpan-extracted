#
# $Id: Pps.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# system::linux::pps Brik
#
package Metabrik::System::Linux::Pps;
use strict;
use warnings;

use base qw(Metabrik::Network::Device Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         strip_crlf => 1,
      },
      commands => {
         loop => [ qw(device|OPTIONAL interval|OPTIONAL) ],
      },
   };
}

sub loop {
   my $self = shift;
   my ($device, $interval) = @_;

   $device ||= $self->default or return;
   $interval ||= 1;  # 1 second interval

   if (ref($device) eq 'ARRAY') {
      $device = $device->[0];
   }

   my $rx_packets = "/sys/class/net/$device/statistics/rx_packets";
   my $tx_packets = "/sys/class/net/$device/statistics/tx_packets";
   if (! -f $rx_packets && ! -f $tx_packets) {
      return $self->log->error("loop: file not found [$rx_packets] and [$tx_packets]");
   }

   while (1) {
      my $r1 = $self->read($rx_packets) or return;
      my $t1 = $self->read($tx_packets) or return;
      sleep($interval);
      my $r2 = $self->read($rx_packets) or return;
      my $t2 = $self->read($tx_packets) or return;
      my $rdiff = $r2->[0] - $r1->[0];
      my $tdiff = $t2->[0] - $t1->[0];
      $self->log->info("loop: TX [$device]: $tdiff pkts/s RX [$device]: $rdiff pkts/s");
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::System::Linux::Pps - system::linux::pps Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
