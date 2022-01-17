#
# $Id$
#
# network::traceroute Brik
#
package Metabrik::Network::Traceroute;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         first_hop => [ qw(hop_number) ],
         last_hop => [ qw(hop_number) ],
         rtimeout => [ qw(timeout_second) ],
         try => [ qw(try_count) ],
      },
      attributes_default => {
         first_hop => 5,
         last_hop => 50,
         rtimeout => 1,
         try => 2,
      },
      commands => {
         install => [ ], # Inherited
         tcp => [ qw(host port) ],
      },
      require_binaries => {
         'tcptraceroute', => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tcptraceroute) ],
         debian => [ qw(tcptraceroute) ],
         kali => [ qw(tcptraceroute) ],
      },
   };
}

sub tcp {
   my $self = shift;
   my ($host, $port) = @_;

   my $rtimeout = $self->rtimeout;
   my $try = $self->try;
   my $first = $self->first_hop;
   my $last = $self->last_hop;
   $self->brik_help_run_undef_arg('tcp', $host) or return;
   $self->brik_help_run_undef_arg('tcp', $port) or return;

   my $cmd = "tcptraceroute -n -q $try -f $first -m $last -w $rtimeout  $host $port";

   $self->log->verbose("tcp: running...");
   my $lines = $self->capture($cmd);
   $self->log->verbose("tcp: running...Done");

   my $trace = {
      raw => $lines,
   };
   for my $this (@$lines) {
      (my $l = $this) =~ s/^\s*//;
      if ($l =~ /^\d+/) {
         my @toks = split(/\s+/, $l);
         my $hop = $toks[0];
         my $ip;
         for (1..$try) {
            my $i = $toks[$_];
            if ($i =~ /^\d+\.\d+\.\d+\.\d+$/) {
               $ip = $i;
               last;
            }
         }
         $trace->{$hop} = $ip || '0.0.0.0';
      }
   }

   return $trace;
}

1;

__END__

=head1 NAME

Metabrik::Network::Traceroute - network::traceroute Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
