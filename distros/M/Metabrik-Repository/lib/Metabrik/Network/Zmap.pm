#
# $Id$
#
# network::zmap Brik
#
package Metabrik::Network::Zmap;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         device => [ qw(device) ],
         bandwidth => [ qw(bps) ],
         rate => [ qw(pps) ],
         max_targets => [ qw(count) ],
         max_results => [ qw(count) ],
         max_runtime => [ qw(seconds) ],
         probes => [ qw(count) ],
         cooldown_time => [ qw(seconds) ],
      },
      attributes_default => {
         bandwidth => '4M', # 4 Mbps, 512 kBps
         probes => 1,
         cooldown_time => 8,
      },
      commands => {
         install => [ ], # Inherited
         scan => [ qw(port output|OPTIONAL device|OPTIONAL) ],
      },
      require_binaries => {
         zmap => [ ],
      },
      need_packages => {
         ubuntu => [ qw(zmap) ],
         debian => [ qw(zmap) ],
         kali => [ qw(zmap) ],
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

sub scan {
   my $self = shift;
   my ($port, $output, $device) = @_;

   $device ||= $self->device;
   $output ||= '-';
   $self->brik_help_run_undef_arg('scan', $port) or return;
   $self->brik_help_run_undef_arg('scan', $output) or return;
   $self->brik_help_run_undef_arg('scan', $device) or return;

   my $bandwidth = $self->bandwidth;
   my $rate = $self->rate;
   my $max_targets = $self->max_targets;
   my $max_runtime = $self->max_runtime;
   my $max_results = $self->max_results;
   my $cooldown_time = $self->cooldown_time;
   my $probes = $self->probes;

   my $cmd = "zmap -p $port -i $device -o \"$output\" -P $probes -c $cooldown_time";

   if (defined($max_targets)) {
      $cmd .= " -n $max_targets";
   }
   elsif (defined($max_results)) {
      $cmd .= " -N $max_results";
   }
   elsif (defined($max_runtime)) {
      $cmd .= " -t $max_runtime";
   }

   if (defined($rate)) {
      $cmd .= " -r $rate";
   }
   elsif (defined($bandwidth)) {
      $cmd .= " -B $bandwidth";
   }

   $self->log->verbose("scan: zmap[$cmd]");

   return $self->sudo_system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Network::Zmap - network::zmap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
