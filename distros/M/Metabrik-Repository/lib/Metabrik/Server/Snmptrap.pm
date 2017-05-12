#
# $Id: Snmptrap.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# server::snmptrap Brik
#
package Metabrik::Server::Snmptrap;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable snmp trap trapd snmptrapd) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         _wf => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 162,
      },
      commands => {
         install => [ ], # Inherited
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL datadir|OPTIONAL) ],
         stop => [ ],
      },
      require_modules => {
         'Net::SNMPTrapd' => [ ],
         'Metabrik::Worker::Fork' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libsnmp-dev) ],
         debian => [ qw(libsnmp-dev) ],
      },
   };
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $root ||= $self->datadir;

   if ($port < 1024 && $< != 0) {
      return $self->log->error("start: need root privileges to bind port [$port]");
   }

   my $proc = Net::SNMPTrapd->new
      or return $self->log->error("start: ".Net::SNMPTrapd->error);

   my $wf = Metabrik::Worker::Fork->new_from_brik_init($self) or return;

   defined(my $pid = $wf->start) or return $self->log->error("start: start failed");

   # Son
   if (! $pid) {
      $self->debug && $self->log->debug("start: son process started: $$");

      while (1) {
         my $trap = $proc->get_trap;
         if (! defined($trap)) {
            printf "$0: %s\n", Net::SNMPTrapd->error;
            exit(1);
         }
         elsif ($trap == 0) {
            next;
         }

         if (! defined($trap->process_trap)) {
            printf("$0: %s\n", Net::SNMPTrapd->error);
         } else {
            printf("%s\t%i\t%i\t%s\n",
               $trap->remoteaddr,
               $trap->remoteport,
               $trap->version,
               $trap->community,
            );
         }
      }

      $self->debug && $self->log->debug("start: son process exited: $$");

      exit(0);
   }

   # Father
   $self->_wf($wf);

   return $wf->pid;
}

sub stop {
   my $self = shift;

   my $wf = $self->_wf;

   if (defined($wf)) {
      $self->log->verbose("stop: process with pid [".$wf->pid."]");
      $wf->stop;
      $self->_wf(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Server::Snmptrap - server::snmptrap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
