#
# $Id$
#
# network::wps Brik
#
package Metabrik::Network::Wps;
use strict;
use warnings;

use base qw(Metabrik::Network::Wlan Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable wifi wlan wireless) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         brute_force_wps => [ qw(essid bssid|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Shell::Command' => [ ],
      },
      require_binaries => {
         'sudo', => [ ],
         'reaver', => [ ],
      },
      need_packages => {
         ubuntu => [ qw(reaver) ],
         debian => [ qw(reaver) ],
         kali => [ qw(reaver) ],
      },
   };
}

sub brute_force_wps {
   my $self = shift;
   my ($essid, $bssid) = @_;

   $self->brik_help_run_undef_arg('brute_force_wps', $essid) or return;

   # If user provided bssid, we skip auto-detection
   if (! defined($bssid)) {
      my $scan = $self->scan;
      if (! defined($scan)) {
         return $self->log->error("brute_force_wps: no AP found?");
      }

      my $ap;
      for my $this (keys %$scan) {
         $self->log->info("this[$this] essid[$essid]");
         if ($scan->{$this}->{essid} eq $essid) {
            $ap = $scan->{$this};
            last;
         }
      }

      if (! defined($ap)) {
         return $self->log->error("brute_force_wps: no AP found by that essid [$essid]");
      }

      $bssid = $ap->{address};
   }

   my $monitor = $self->start_monitor_mode or return;

   my $cmd = "sudo reaver -i $monitor -b $bssid -vv";

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   my $r = $sc->system($cmd);

   $self->stop_monitor_mode;

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Network::Wps - network::wps Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
