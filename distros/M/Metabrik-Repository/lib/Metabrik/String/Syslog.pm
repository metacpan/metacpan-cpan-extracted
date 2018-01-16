#
# $Id: Syslog.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# string::syslog Brik
#
package Metabrik::String::Syslog;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(hostname) ],
         process => [ qw(name) ],
         pid => [ qw(id) ],
         do_rfc3164 => [ qw(0|1) ],
         timestamp => [ qw(timestamp) ],
      },
      attributes_default => {
         process => 'metabrik',
         pid => $$,
         do_rfc3164 => 0,
      },
      commands => {
         encode => [ qw($data hostname|OPTIONAL process|OPTIONAL pid|OPTIONAL) ],
         decode => [ qw($data) ],
         date => [ qw(timestamp|OPTIONAL) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         hostname => defined($self->global) && $self->global->hostname || 'hostname',
      },
   };
}

sub encode {
   my $self = shift;
   my ($data, $hostname, $process, $pid) = @_;

   $hostname ||= $self->hostname;
   $process ||= $self->process;
   $pid ||= $self->pid;
   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_set_undef_arg('hostname', $hostname) or return;
   $self->brik_help_set_undef_arg('process', $process) or return;
   $self->brik_help_set_undef_arg('pid', $pid) or return;
   my $ref = $self->brik_help_run_invalid_arg('encode', $data, 'HASH', 'SCALAR')
      or return;

   my $timestamp = $self->timestamp;

   # Convert to key=value
   if ($ref eq 'HASH') {
      my $kv = '';
      for my $k (sort { $a cmp $b } keys %$data) {
         if ($k !~ m{\s}) {  # If there is no space char, we don't put between double quotes
            $kv .= "$k=\"".$data->{$k}."\" ";
         }
         else {
            $kv .= "\"$k\"=\"".$data->{$k}."\" ";
         }
      }
      $kv =~ s{\s*$}{};
      $data = $kv;
   }

   my $message = '';
   if ($self->do_rfc3164) {
      my $date = $self->date($timestamp);
      $message = "$date $hostname $process\[$pid\]: $data";
   }
   else {
      $message = "$process\[$pid\]: $data";
   }

   return $message;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'SCALAR') or return;

   my ($timestamp, $hostname, $process, $pid, $message);
   #  May 17 18:18:06
   if ($data =~ m{^(\S+\s+\d+\s+\S+)\s+(\S+)\s+(\S+)\[(\d+)\]:\s+(.*)$}) {
      $timestamp = $1;
      $hostname = $2;
      $process = $3;
      $pid = $4;
      $message = $5;
   }
   # Wed May 17 18:18:06 2017
   elsif ($data =~ m{^(\S+\s+\S+\s+\d+\s+\S+\s+\S+)\s+(\S+)\s+(\S+)\[(\d+)\]:\s+(.*)$}) {
      $timestamp = $1;
      $hostname = $2;
      $process = $3;
      $pid = $4;
      $message = $5;
   }

   if (! defined($timestamp)) {
      return $self->log->error("decode: unable to decode message [$data]");
   }

   return {
      timestamp => $timestamp,
      hostname => $hostname,
      process => $process,
      pid => $pid,
      message => $message,
   };
}

sub date {
   my $self = shift;
   my ($timestamp) = @_;

   my @month = qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};

   #
   # Courtesy of Net::Syslog
   #
   # But not RDC3164 compliant in regards to time format.
   # RFC3164: "Wed May 17 18:18:06 2017"
   # Not RFC3164: "May 17 18:18:06"
   #
   my @time = defined($timestamp) ? localtime($timestamp) : localtime();
   my $date =
      $month[$time[4]].
      ' '.
      (($time[3] < 10) ? (' '.$time[3]) : $time[3]).
      ' '.
      (($time[2] < 10 ) ? ('0'.$time[2]) : $time[2]).
      ':'.
      (($time[1] < 10) ? ('0'.$time[1]) : $time[1]).
      ':'.
      (($time[0] < 10) ? ('0'.$time[0]) : $time[0]);

   return $date;
}

1;

__END__

=head1 NAME

Metabrik::String::Syslog - string::syslog Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
