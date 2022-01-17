#
# $Id$
#
# system::freebsd::top Brik
#
package Metabrik::System::Freebsd::Top;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         stats => [ ],
         list => [ ],
      },
      require_binaries => {
         top => [ ],
      },
   };
}

sub _convert_size {
   my $self = shift;
   my ($size) = @_;

   return unless defined($size);

   if ($size =~ m{^(\d+)K$}) {
      return $1."000";
   }
   elsif ($size =~ m{^(\d+)M$}) {
      return $1."000000";
   }
   elsif ($size =~ m{^(\d+)G$}) {
      return $1."000000000";
   }
   elsif ($size =~ m{^(\d+)T$}) { # LOL
      return $1."000000000000";
   }

   return $size;
}

sub stats {
   my $self = shift;

   my $cmd = 'top -Sb 0';

   #
   # FreeBSD 10.2-RELEASE
   #
   # 0: last pid: 61608;  load averages:  0.99,  1.04,  1.06  up 4+20:20:19    10:32:11
   # 1: 279 processes: 2 running, 269 sleeping, 1 stopped, 6 zombie, 1 waiting
   # 1: 272 processes: 2 running, 263 sleeping, 6 zombie, 1 waiting,
   # 2: 
   # 3: Mem: 4116M Active, 15G Inact, 11G Wired, 21M Cache, 958M Free
   # 3: Mem: 5435M Active, 14G Inact, 11G Wired, 135M Cache, 1655M Buf, 326M Free
   # 4: ARC: 9086M Total, 3939M MFU, 1973M MRU, 1417K Anon, 102M Header, 3071M Other
   # 5: Swap: 16G Total, 8940K Used, 16G Free

   my $lines = $self->capture($cmd) or return;

   my $info = {
      raw => $lines,
   };
   my $row = 0;
   for my $line (@$lines) {
      $line =~ s{^\s*}{};
      $line =~ s{\s*$}{};

      if ($row == 0) {
         my @f = $line =~ m{^last pid:\s+(\d+);\s+load averages:\s+(\S+),\s+(\S+),\s+(\S+)\s+up (\S+)\s+(\S+)$};

         #$self->log->debug("@f");

         $info->{last_pid} = $f[0];
         $info->{load_average_1m} = $f[1];
         $info->{load_average_5m} = $f[2];
         $info->{load_average_15m} = $f[3];
         $info->{uptime} = $f[4];
         $info->{time} = $f[5];
      }
      elsif ($row == 1) {
         my @f = $line =~ m{^(\d+) processes: (?:(\d+) running, )?(?:(\d+) sleeping, )?(?:(\d+) stopped, )?(?:(\d+) zombie, )?(?:(\d+) waiting)?$};

         #$self->log->debug("@f");

         $info->{total_processes} = $f[0] || 0;
         $info->{running_processes} = $f[1] || 0;
         $info->{sleeping_processes} = $f[2] || 0;
         $info->{stopped_processes} = $f[3] || 0;
         $info->{zombie_processes} = $f[4] || 0;
         $info->{waiting_processes} = $f[5] || 0;
      }
      elsif ($row == 3) {
         my @f = $line =~ m{^Mem: (?:(\S+) Active, )?(?:(\S+) Inact, )?(?:(\S+) Wired, )?(?:(\S+) Cache, )?(?:(\S+) Buf, )?(?:(\S+) Free)?$};

         #$self->log->debug("@f");

         $info->{active_memory} = $self->_convert_size($f[0]) || 0;
         $info->{inactive_memory} = $self->_convert_size($f[1]) || 0;
         $info->{wired_memory} = $self->_convert_size($f[2]) || 0;
         $info->{cache_memory} = $self->_convert_size($f[3]) || 0;
         $info->{free_memory} = $self->_convert_size($f[4]) || 0;
      }
      elsif ($row == 4) {
         my @f = $line =~ m{^ARC: (\S+) Total, (\S+) MFU, (\S+) MRU, (\S+) Anon, (\S+) Header, (\S+) Other$};

         #$self->log->debug("@f");

         $info->{total_arc} = $self->_convert_size($f[0]) || 0;
         $info->{mfu_arc} = $self->_convert_size($f[1]) || 0;
         $info->{mru_arc} = $self->_convert_size($f[2]) || 0;
         $info->{anon_arc} = $self->_convert_size($f[3]) || 0;
         $info->{header_arc} = $self->_convert_size($f[4]) || 0;
         $info->{other_arc} = $self->_convert_size($f[5]) || 0;
      }
      elsif ($row == 5) {
         # "Swap: 16G Total, 16G Free"
         my @f = $line =~ m{^Swap: (?:(\S+) Total, )?(?:(\S+) Used, )?(?:(\S+) Free)?$};

         #$self->log->debug("@f");

         $info->{total_swap} = $self->_convert_size($f[0]) || 0;
         $info->{used_swap} = $self->_convert_size($f[1]) || 0;
         $info->{free_swap} = $self->_convert_size($f[2]) || 0;
      }

      $row++;
   }

   return $info;
}

sub list {
   my $self = shift;

   my $cmd = 'top -Sb 999';

   #
   # FreeBSD 10.3-RELEASE
   #
   #   PID USERNAME       THR PRI NICE   SIZE    RES STATE   C   TIME    WCPU COMMAND
   #    11 root             4 155 ki31     0K    64K RUN     3 439.6H 400.00% idle
   # 90893 elasticsearch   70  20    0 53636M 10994M uwait   2 343:24   4.49% java
   #   834 root            29  20    0  1468M   399M uwait   0  55:51   0.78% java
 

   my $lines = $self->capture($cmd) or return;

   my @list = ();
   my $skip = 1;
   for my $line (@$lines) {
      if ($line =~ m{THR\s+PRI\s+NICE}) {
         $skip = 0;
         next;
      }
      if ($skip) {
         next;
      }

      $line =~ s{^\s*}{};
      $line =~ s{\s*$}{};

      my @t = split(/\s+/, $line);

      push @list, {
         pid => $t[0],
         user => $t[1],
         thread => $t[2],
         priority => $t[3],
         nice => $t[4],
         total_process_memory_size => $t[5],
         resident_memory_in_kilobytes => $t[6],
         process_state => $t[7],
         cpu_number => $t[8],
         system_and_user_cpu_seconds => $t[9],
         weighted_cpu_percentage => $t[10],
         raw => $line,
      };
   }

   return \@list;
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Top - system::freebsd::top Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
