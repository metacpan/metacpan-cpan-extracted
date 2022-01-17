#
# $Id$
#
# worker::fork Brik
#
package Metabrik::Worker::Fork;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable process) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         pid => [ qw(forked_process_id) ],
      },
      commands => {
         start => [ ],
         stop => [ ],
         is_son_alive => [ ],
      },
      require_modules => {
         #'POSIX' => [ ],
      },
   };
}

sub start {
   my $self = shift;

   # Fork a new process
   defined(my $pid = fork()) or return $self->log->error("start: fork: $!");
   if ($pid) { # Father
      my $restore = $SIG{INT};

      $self->pid($pid);

      $SIG{INT} = sub {
         $self->log->debug("SIGINT: caught, son [$pid] QUITs now");
         $self->stop;
         $SIG{INT} = $restore;
         return 1;
      };
   }

   # Return to father and son processes
   return $pid;
}

sub stop {
   my $self = shift;

   if ($self->pid) {
      kill('TERM', $self->pid);
      waitpid($self->pid, POSIX::WNOHANG());  # Cleanup zombie state in case it is dead
      $self->pid(undef);
   }

   return 1;
}

sub is_son_alive {
   my $self = shift;

   my $pid = $self->pid;
   if (defined($pid)) {
      waitpid($pid, POSIX::WNOHANG());  # Cleanup zombie state in case it is dead
      my $r = kill('ZERO', $pid);
      $self->log->debug("is_son_alive: kill returned [$r] for pid [$pid]");
      if ($r) { # Son still alive
         return 1;
      }
   }

   return 0;
}

sub brik_fini {
   my $self = shift;

   return $self->stop;
}

1;

__END__

=head1 NAME

Metabrik::Worker::Fork - worker::fork Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
