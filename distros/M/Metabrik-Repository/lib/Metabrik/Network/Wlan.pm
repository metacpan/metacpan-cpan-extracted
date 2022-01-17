#
# $Id$
#
# network::wlan Brik
#
package Metabrik::Network::Wlan;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable wifi wlan wireless monitor) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         monitor => [ qw(device) ],
         essid => [ qw(essid) ],
         key => [ qw(key) ],
         bitrate => [ qw(bitrate_mb|54MB|130MB) ],
         _monitor_mode_started => [ ],
      },
      attributes_default => {
         device => 'wlan0',
         monitor => 'mon0',
      },
      commands => {
         install => [ ], # Inherited
         scan => [ qw(device|OPTIONAL) ],
         set_bitrate => [ qw(bitrate|OPTIONAL device|OPTIONAL) ],
         set_wepkey => [ qw(key|OPTIONAL device|OPTIONAL) ],
         connect => [ qw(device|OPTIONAL essid|OPTIONAL) ],
         start_monitor_mode => [ qw(device|OPTIONAL) ],
         stop_monitor_mode => [ qw(monitor|OPTIONAL) ],
      },
      require_binaries => {
         'sudo', => [ ],
         'iwlist', => [ ],
         'iwconfig', => [ ],
      },
      optional_binaries => {
         'airmon-ng' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(aircrack-ng iw) ],
         debian => [ qw(aircrack-ng iw) ],
         kali => [ qw(aircrack-ng iw) ],
      },
   };
}

sub scan {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   $self->brik_help_run_undef_arg('scan', $device) or return;

   $self->log->verbose("scan: using device [$device]");

   my $cmd = "iwlist $device scan";

   my $result = $self->capture($cmd);

   if (@$result > 0) {
      return $self->_list_ap($result);
   }

   return $self->log->error("scan: no result");
}

sub _list_ap {
   my $self = shift;
   my ($scan) = @_;

   my $ap_hash = {};

   my $cell = '';
   my $address = '';
   my $channel = '';
   my $frequency = '';
   my $essid = '';
   my $encryption = '';
   my $raw = [];
   my $quality = '';
   for my $line (@$scan) {
      push @$raw, $line;

      if ($line =~ /^\s+Cell\s+(\d+).*Address:\s+(.*)$/) {
         # We just hit a new Cell, we reset data.
         if (length($cell)) {
            $ap_hash->{"cell_$cell"} = {
               cell => $cell,
               address => $address,
               essid => $essid,
               encryption => $encryption,
               raw => $raw,
               quality => $quality,
            };

            $cell = '';
            $address = '';
            $channel = '';
            $frequency = '';
            $essid = '';
            $encryption = '';
            $raw = [];
            $quality = '';

            # We put back the current line.
            push @$raw, $line;
         }
         $cell = $1;
         $address = $2;
         next;
      }

      if ($line =~ /^\s+Channel:(\d+)/) {
         $channel = $1;
         next;
      }

      if ($line =~ /^\s+Frequency:(\d+\.\d+)/) {
         $frequency = $1;
         next;
      }

      if ($line =~ /^\s+Quality=(\d+)\/(\d+)/) {
         $quality = sprintf("%.2f", 100 * $1 / $2);
         next;
      }

      if ($line =~ /^\s+Encryption key:(\S+)/) {
         my $this = $1;
         if ($this eq 'off') {
            $encryption = 0;
         }
         elsif ($this eq 'on') {
            $encryption = 1;
         }
         else {
            $encryption = -1;
         }
      }

      if ($line =~ /^\s+ESSID:"(\S+)"/) {
         $essid = $1;
         $self->log->verbose("cell [$cell] address [$address] essid[$essid] encryption[$encryption] quality[$quality] channel[$channel] frequency[$frequency]");
         next;
      }

   }

   $ap_hash->{"cell_$cell"} = {
      cell => $cell,
      address => $address,
      channel => $channel,
      frequency => $frequency,
      essid => $essid,
      encryption => $encryption,
      raw => $raw,
      quality => $quality,
   };

   return $ap_hash;
}

sub connect {
   my $self = shift;
   my ($device, $essid) = @_;

   $device ||= $self->device;
   $essid ||= $self->essid;
   $self->brik_help_run_undef_arg('connect', $device) or return;
   $self->brik_help_run_undef_arg('connect', $essid) or return;

   my $cmd = "sudo iwconfig $device essid $essid";

   $self->capture_stderr(1);
   my $r = $self->capture($cmd) or return;

   $self->log->verbose("connect: $r");

   $self->set_bitrate or return;

   # For WEP, we can use:
   # "iwconfig $device key $key"

   return $r;
}

sub set_bitrate {
   my $self = shift;
   my ($bitrate, $device) = @_;

   $bitrate ||= $self->bitrate;
   $device ||= $self->device;
   $self->brik_help_run_undef_arg('set_bitrate', $bitrate) or return;
   $self->brik_help_run_undef_arg('set_bitrate', $device) or return;

   my $cmd = "sudo iwconfig $device rate $bitrate";

   $self->capture_stderr(1);

   return $self->capture($cmd);
}

sub set_wepkey {
   my $self = shift;
   my ($key, $device) = @_;

   $key ||= $self->key;
   $device ||= $self->device;
   $self->brik_help_run_undef_arg('set_wepkey', $key) or return;
   $self->brik_help_run_undef_arg('set_wepkey', $device) or return;

   my $cmd = "sudo iwconfig $device key $key";

   $self->capture_stderr(1);

   return $self->capture($cmd);
}

sub start_monitor_mode {
   my $self = shift;
   my ($device) = @_;

   $device ||= $self->device;
   $self->brik_help_run_undef_arg('start_monitor_mode', $device) or return;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_has_binary('airmon-ng');
   if (! $found) {
      return $self->log->error("start_monitor_mode: you have to install aircrack-ng package");
   }

   my $cmd = "sudo airmon-ng start $device";

   $self->capture_stderr(1);

   my $r = $self->capture($cmd);

   if (defined($r)) {
      my $monitor = '';
      for my $line (@$r) {
         if ($line =~ /monitor mode enabled on (\S+)\)/) {
            $monitor = $1;
            last;
         }
      }

      if (! length($monitor)) {
         return $self->log->error("start_monitor_mode: cannot start monitor mode");
      }

      if ($monitor !~ /^[a-z]+(?:\d+)?$/) {
         return $self->log->error("start_monitor_mode: cannot start monitor mode with monitor [$monitor]");
      }

      $self->monitor($monitor);
      $self->_monitor_mode_started(1);
   }

   return $self->monitor;
}

sub stop_monitor_mode {
   my $self = shift;
   my ($monitor) = @_;

   $monitor ||= $self->monitor;
   my $started = $self->_monitor_mode_started;
   $self->brik_help_run_undef_arg('start_monitor_mode', $started) or return;
   $self->brik_help_run_undef_arg('start_monitor_mode', $monitor) or return;

   # airmon-ng is optional, so we check here.
   my $found = $self->brik_has_binary('airmon-ng');
   if (! $found) {
      return $self->log->error("stop_monitor_mode: you have to install aircrack-ng package");
   }

   my $cmd = "sudo airmon-ng stop $monitor";

   $self->capture_stderr(1);

   my $r = $self->capture($cmd);

   if (defined($r)) {
      $self->_monitor_mode_started(0);
   }

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Network::Wlan - network::wlan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
