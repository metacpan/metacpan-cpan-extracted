#
# $Id: Iostat.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::freebsd::iostat Brik
#
package Metabrik::System::Freebsd::Iostat;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         standard => [ ],
         extended => [ ],
      },
      require_binaries => {
         iostat => [ ],
      },
   };
}

sub standard {
   my $self = shift;

   # Display two times with -c 2. The first result row is always the same (?)
   # -C is used to add CPU stats too.
   my $cmd = 'iostat -C -c 2 -w0.1';

   #
   # FreeBSD 10.2-RELEASE
   #
   # 0: "       tty            ada0             ada1            pass0             cpu",
   # 1: " tin  tout  KB/t tps  MB/s   KB/t tps  MB/s   KB/t tps  MB/s  us ni sy in id",
   # 2: "   0  1151 36.26  27  0.96  35.96  27  0.96   0.38   0  0.00   3  0  2  0 95",
   # 3: "   0     0 29.14   7  0.20  29.14   7  0.20   0.00   0  0.00   2  0  0  0 98",

   my $lines = $self->capture($cmd) or return;

   my $dev = [];
   my $info = {
      raw => $lines,
   };
   my $row = 0;
   for my $line (@$lines) {
      $line =~ s{^\s*}{};
      $line =~ s{\s*$}{};

      my @t = split(/\s+/, $line);

      # Device line
      if ($row == 0) {
         $dev = \@t;
      }
      # Stats line
      elsif ($row == 3) {
         my $offset = 0;
         for my $this (@$dev) {
            if ($this eq 'tty') {
               $info->{$this}{characters_read} = $t[$offset++];
               $info->{$this}{characters_written} = $t[$offset++];
            }
            elsif ($this eq 'cpu') {
               $info->{$this}{user} = $t[-5];
               $info->{$this}{nice} = $t[-4];
               $info->{$this}{system} = $t[-3];
               $info->{$this}{interrupt} = $t[-2];
               $info->{$this}{idle} = $t[-1];
            }
            else {
               $info->{$this}{kilobytes_per_transfer} = $t[$offset++];
               $info->{$this}{transfers_per_second} = $t[$offset++];
               $info->{$this}{megabytes_per_second} = $t[$offset++];
            }
         }
      }

      $row++;
   }

   return $info;
}

sub extended {
   my $self = shift;

   my $cmd = 'iostat -C -c 2 -w0.1 -x';

   # "                        extended device statistics             cpu ",
   # "device     r/s   w/s    kr/s    kw/s qlen svc_t  %b  us ni sy in id ",
   # "ada0       3.3  19.3   237.2   749.4    0   4.2   7   3  0  2  0 95",
   # "ada1       3.2  19.5   236.2   749.5    0   4.2   7 ",
   # "pass0      0.0   0.0     0.0     0.0    0 244.0   0 ",
   # "pass1      0.0   0.0     0.0     0.0    0 248.0   0 ",
   # "pass2      0.0   0.0     0.0     0.0    0   0.0   0 ",
   # "                        extended device statistics             cpu ",
   # "device     r/s   w/s    kr/s    kw/s qlen svc_t  %b  us ni sy in id ",
   # "ada0       0.0   0.0     0.0     0.0    0   0.0   0   3  0  1  0 96",
   # "ada1       0.0   0.0     0.0     0.0    0   0.0   0 ",
   # "pass0      0.0   0.0     0.0     0.0    0   0.0   0 ",
   # "pass1      0.0   0.0     0.0     0.0    0   0.0   0 ",
   # "pass2      0.0   0.0     0.0     0.0    0   0.0   0 ",

   my $lines = $self->capture($cmd) or return;

   my $info = {
      raw => $lines,
   };
   my $count = 0;
   for my $line (@$lines) {
      $line =~ s{^\s*}{};
      $line =~ s{\s*$}{};

      # Skip until second chunks of results
      if ($line =~ m{extended device statistics}) {
         $count++;
         next;
      }
      if ($count < 2) {
         next;
      }

      my @t = split(/\s+/, $line);

      my $offset = 0;
      my $dev = $t[$offset++];
      my $r_s = $t[$offset++];
      my $w_s = $t[$offset++];
      my $kr_s = $t[$offset++];
      my $kw_s = $t[$offset++];
      my $qlen = $t[$offset++];
      my $svc_t = $t[$offset++];
      my $b_percentage = $t[$offset++];

      # device line is a header
      if ($dev eq 'device') {
         next;
      }

      $info->{$dev}{read_op_per_second} = $r_s;
      $info->{$dev}{write_op_per_second} = $w_s;
      $info->{$dev}{kilobytes_read_per_second} = $kr_s;
      $info->{$dev}{kilobytes_write_per_second} = $kw_s;
      $info->{$dev}{transaction_queue_length} = $qlen;
      $info->{$dev}{average_transaction_duration_in_ms} = $svc_t;
      $info->{$dev}{outstanding_transaction_time_percentage} = $b_percentage;

      # Only one line contains CPU info
      if (! exists($info->{cpu})) {
         $info->{cpu}{user} = $t[-5];
         $info->{cpu}{nice} = $t[-4];
         $info->{cpu}{system} = $t[-3];
         $info->{cpu}{interrupt} = $t[-2];
         $info->{cpu}{idle} = $t[-1];
      }
   }

   return $info;
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Iostat - system::freebsd::iostat Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
