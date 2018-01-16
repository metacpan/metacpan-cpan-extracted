#
# $Id: Volatility.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# forensic::Volatility Brik
#
package Metabrik::Forensic::Volatility;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable carving carve file filecarve filecarving) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         profile => [ qw(profile) ],
         input => [ qw(file) ],
         capture_mode => [ qw(0|1) ],
      },
      attributes_default => {
         profile => 'Win7SP1x64',
         capture_mode => 1,
      },
      commands => {
         install => [ ], # Inherited
         imageinfo => [ qw(file|OPTIONAL) ],
         command => [ qw(command file|OPTIONAL profile|OPTIONAL) ],
         envars => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         pstree => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         pslist => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         netscan => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hashdump => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         psxview => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hivelist => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         hivedump => [ qw(offset file|OPTIONAL profile|OPTIONAL) ],
         filescan => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         consoles => [ qw(file|OPTIONAL profile|OPTIONAL) ],
         memdump => [ qw(pid file|OPTIONAL profile|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'volatility' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(volatility) ],
         debian => [ qw(volatility) ],
      },
   };
}

sub imageinfo {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->input;
   my $datadir = $self->datadir;
   $self->brik_help_run_undef_arg('imageinfo', $file) or return;
   $self->brik_help_run_file_not_found('imageinfo', $file) or return;

   my $cmd = "volatility imageinfo -f \"$file\"";

   $self->log->info("imageinfo: running...");
   my $data = $self->capture($cmd);
   $self->log->info("imageinfo: running...done");

   my @profiles = ();
   for my $line (@$data) {
      if ($line =~ m{suggested profile}i) {
         my @toks = split(/\s+/, $line);
         @profiles = @toks[4..$#toks];
         for (@profiles) {
            s/,$//g;
         }
      }
   }

   return \@profiles;
}

sub command {
   my $self = shift;
   my ($command, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('command', $command) or return;
   $self->brik_help_run_undef_arg('command', $file) or return;
   $self->brik_help_run_undef_arg('command', $profile) or return;

   my $cmd = "volatility --profile $profile $command -f \"$file\"";

   return $self->execute($cmd);
}

sub envars {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('envars', $file) or return;
   $self->brik_help_run_undef_arg('envars', $profile) or return;

   my $cmd = "volatility --profile $profile envars -f $file";

   return $self->execute($cmd);
}

sub pstree {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('pstree', $file) or return;
   $self->brik_help_run_undef_arg('pstree', $profile) or return;

   my $cmd = "volatility --profile $profile pstree -v -f $file";

   return $self->execute($cmd);
}

sub pslist {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('pslist', $file) or return;
   $self->brik_help_run_undef_arg('pslist', $profile) or return;

   my $cmd = "volatility --profile $profile pslist -v -f $file";

   $self->capture_stderr(0);
   my $lines = $self->execute($cmd) or return;
   $self->capture_stderr(1);

   # Offset(V)|Name|PID|PPID|Thds|Hnds|Sess|Wow64|Start                          Exit
   my $skip = 3;
   my @info = ();
   for my $line (@$lines) {
      if ($skip != 0) {
         $skip--;
         next;
      }
      my @t = split(/\s+/, $line, 9);
      my $offset = $t[0];
      my $name = $t[1];
      my $pid = $t[2];
      my $ppid = $t[3];
      my $thds = $t[4];
      my $hhds = $t[5];
      my $sess = $t[6];
      my $wow64 = $t[7];
      my $start_exit = $t[8];

      # "2016-06-04 16:23:13 UTC+0000"
      # "2016-06-04 16:26:04 UTC+0000   2016-06-04 16:26:06 UTC+0000"
      $start_exit =~ s{\s*$}{};
      my ($start, $exit) = $start_exit =~ m{^(\S+ \S+ \S+)(?:\s+(\S+ \S+ \S+))?$};

      push @info, {
         offset => $offset,
         name => $name,
         pid => $pid,
         ppid => $ppid,
         thds => $thds,
         hhds => $hhds,
         sess => $sess,
         wow64 => $wow64,
         start => $start,
         exit => $exit,
         #start_exit => $start_exit,
      };
   }

   return \@info;
}

sub netscan {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('netscan', $file) or return;
   $self->brik_help_run_undef_arg('netscan', $profile) or return;

   my $cmd = "volatility --profile $profile netscan -v -f $file";

   $self->capture_stderr(0);
   my $lines = $self->execute($cmd) or return;
   $self->capture_stderr(1);

   # "Offset(P)   Proto   Local Address   Foreign Address    State     Pid   Owner     Created",
   my $skip = 1;
   my @info = ();
   my @raw = ();
   for my $line (@$lines) {
      if ($skip != 0) {
         $skip--;
         next;
      }

# "0x41b9520  TCPv6  -:0   7808:2401:80fa:ffff:7808:2401:80fa:ffff:0 CLOSED 1820  avgmfapx.exe"
      if ($line =~ m{\s+TCPv(4|6)\s+}) {
         my @t = split(/\s+/, $line, 7);
         my $offset = $t[0];
         my $proto = $t[1];
         my $local_address = $t[2];
         my $foreign_address = $t[3];
         my $state = $t[4];
         my $pid = $t[5];
         my $owner = $t[6];

         push @info, {
            offset => $offset,
            proto => $proto,
            local_address => $local_address,
            foreign_address => $foreign_address,
            state => $state,
            pid => $pid,
            owner => $owner,
            created => 'undef',
         };
      }
# "0x171e1360 UDPv4  10.0.3.15:138  *:*    4  System  2016-10-15 14:58:46 UTC+0000",
      elsif ($line =~ m{\s+UDPv(4|6)\s+}) {
         my @t = split(/\s+/, $line, 7);
         my $offset = $t[0];
         my $proto = $t[1];
         my $local_address = $t[2];
         my $foreign_address = $t[3];
         my $pid = $t[4];
         my $owner = $t[5];
         my $created = $t[6];

         push @info, {
            offset => $offset,
            proto => $proto,
            local_address => $local_address,
            foreign_address => $foreign_address,
            state => 'undef',
            pid => $pid,
            owner => $owner,
            created => $created,
         };
      }
      else {
         $self->log->warning("netscan: don't know what to do with line [$line]");
      }
   }

   return \@info;
}

sub memdump {
   my $self = shift;
   my ($pid, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('memdump', $pid) or return;
   $self->brik_help_run_undef_arg('memdump', $file) or return;
   $self->brik_help_run_undef_arg('memdump', $profile) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($pid) or return;

   my $cmd = "volatility --profile $profile memdump -p $pid --dump-dir $pid/ -f $file";
   $self->execute($cmd) or return;

   return "$pid/$pid.dmp";
}

sub hashdump {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hashdump', $file) or return;
   $self->brik_help_run_undef_arg('hashdump', $profile) or return;

   my $cmd = "volatility --profile $profile hashdump -f $file";

   return $self->execute($cmd);
}

sub psxview {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('psxview', $file) or return;
   $self->brik_help_run_undef_arg('psxview', $profile) or return;

   my $cmd = "volatility --profile $profile psxview -f $file";

   return $self->execute($cmd);
}

sub hivelist {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hivelist', $file) or return;
   $self->brik_help_run_undef_arg('hivelist', $profile) or return;

   my $cmd = "volatility --profile $profile hivelist -f $file";

   $self->capture_stderr(0);
   my $lines = $self->execute($cmd) or return;
   $self->capture_stderr(1);

   # "Virtual            Physical           Name"
   my $skip = 2;
   my @info = ();
   for my $line (@$lines) {
      if ($skip != 0) {
         $skip--;
         next;
      }
      my @t = split(/\s+/, $line, 3);
      my $virtual = $t[0];
      my $physical = $t[1];
      my $name = $t[2];

      push @info, {
         virtual => $virtual,
         physical => $physical,
         name => $name,
      };
   }

   return \@info;
}

sub hivedump {
   my $self = shift;
   my ($offset, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('hivedump', $offset) or return;
   $self->brik_help_run_undef_arg('hivedump', $file) or return;
   $self->brik_help_run_undef_arg('hivedump', $profile) or return;

   my $cmd = "volatility --profile $profile hivedump --hive-offset $offset -f $file";

   return $self->execute($cmd);
}

sub filescan {
   my $self = shift;
   my ($offset, $file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('filescan', $offset) or return;
   $self->brik_help_run_undef_arg('filescan', $file) or return;
   $self->brik_help_run_undef_arg('filescan', $profile) or return;

   my $cmd = "volatility --profile $profile filescan -f $file";

   return $self->execute($cmd);
}

sub consoles {
   my $self = shift;
   my ($file, $profile) = @_;

   $file ||= $self->input;
   $profile ||= $self->profile;
   $self->brik_help_run_undef_arg('consoles', $file) or return;
   $self->brik_help_run_undef_arg('consoles', $profile) or return;

   my $cmd = "volatility --profile $profile consoles -f $file";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Volatility - forensic::volatility Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
