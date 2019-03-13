#
# $Id: Netstat.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# system::freebsd::netstat Brik
#
package Metabrik::System::Freebsd::Netstat;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         interface => [ qw(name) ],
      },
      attributes_default => {
         interface => 're0',
      },
      commands => {
         stats => [ qw(interface|interface_list|OPTIONAL) ],
         compute_diff => [ qw(first_stats second_stats) ],
      },
      require_binaries => {
         netstat => [ ],
      },
   };
}

sub stats {
   my $self = shift;
   my ($interface) = @_;

   $interface ||= $self->interface;
   $self->brik_help_run_undef_arg('stats', $interface) or return;
   my $ref = $self->brik_help_run_invalid_arg('stats', $interface, 'ARRAY', 'SCALAR')
      or return;

   my $info = { };

   if ($ref eq 'ARRAY') {
      my @list = ();
      for my $this (@$interface) {
         $info = $self->stats($this) or next;
         push @list, $info;
      }

      return \@list;
   }
   else {
      #
      # FreeBSD 10.2-RELEASE
      #
      # netstat -i -b -n -I re0
      # 0: "Name    Mtu Network       Address              Ipkts Ierrs Idrop     Ibytes    Opkts Oerrs     Obytes  Coll",
      # 1: "re0    1500 <Link#1>      <mac>             47110755     0     0 17188577531 72244809     0 94220997385     0",
      # 2: "re0       - <ip>/24       <ip>              44645072     -     - 16112030427 71929477     - 92914300016     -",

      my $cmd = 'netstat -i -b -n -I '.$interface;

      my $lines = $self->capture($cmd) or return;

      for my $line (@$lines) {
         $line =~ s{^\s*}{};
         $line =~ s{\s*$}{};

         # Only the line with valid MTU depicts a physical interface. We only keep that one.
         if ($line =~ m{^\S+\s+\d+}) {
            my @t = split(/\s+/, $line);

            if ($interface eq $t[0]) {
               my $offset = 0;
               $info->{interface} = $t[$offset++];
               $info->{mtu} = $t[$offset++];
               $info->{network} = $t[$offset++];
               $info->{mac_address} = $t[$offset++];
               $info->{total_input_packets} = $t[$offset++];
               $info->{total_input_errors} = $t[$offset++];
               $info->{total_input_drop} = $t[$offset++];
               $info->{total_input_bytes} = $t[$offset++];
               $info->{total_output_packets} = $t[$offset++];
               $info->{total_output_errors} = $t[$offset++];
               $info->{total_output_bytes} = $t[$offset++];
               $info->{coll} = $t[$offset++];

               last;
            }
         }
      }
   }

   return $info;
}

sub compute_diff {
   my $self = shift;
   my ($first, $second) = @_;

   $self->brik_help_run_undef_arg('compute_diff', $first) or return;
   $self->brik_help_run_undef_arg('compute_diff', $second) or return;
   $self->brik_help_run_invalid_arg('compute_diff', $first, 'HASH') or return;
   $self->brik_help_run_invalid_arg('compute_diff', $second, 'HASH') or return;

   my $diff = {};
   if (exists($first->{total_input_bytes}) && exists($second->{total_input_bytes})) {
      $diff->{input_bytes} = $second->{total_input_bytes} - $first->{total_input_bytes};
   }
   if (exists($first->{total_output_bytes}) && exists($second->{total_output_bytes})) {
      $diff->{output_bytes} = $second->{total_output_bytes} - $first->{total_output_bytes};
   }
   if (exists($first->{total_input_packets}) && exists($second->{total_input_packets})) {
      $diff->{input_packets} = $second->{total_input_packets} - $first->{total_input_packets};
   }
   if (exists($first->{total_output_packets}) && exists($second->{total_output_packets})) {
      $diff->{output_packets} = $second->{total_output_packets} - $first->{total_output_packets};
   }
   if (exists($first->{total_input_errors}) && exists($second->{total_input_errors})) {
      $diff->{input_errors} = $second->{total_input_errors} - $first->{total_input_errors};
   }
   if (exists($first->{total_output_errors}) && exists($second->{total_output_errors})) {
      $diff->{output_errors} = $second->{total_output_errors} - $first->{total_output_errors};
   }

   return $diff;
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Netstat - system::freebsd::netstat Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
