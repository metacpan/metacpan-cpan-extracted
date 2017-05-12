#
# $Id: Parallel.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# worker::parallel Brik
#
package Metabrik::Worker::Parallel;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         pool_size => [ qw(count) ],
         pid => [ qw(pid) ],  # pid is available within son process only
         manager => [ qw(INTERNAL) ],
      },
      attributes_default => {
         pool_size => 10,
      },
      commands => {
         create_manager => [ qw(pool_size|OPTIONAL) ],
         reset_manager => [ ],
         start => [ qw(sub) ],
      },
      require_modules => {
         'Parallel::ForkManager' => [ ],
      },
   };
}

sub create_manager {
   my $self = shift;
   my ($pool_size) = @_;

   # Do not create another manager if one already exists.
   my $manager = $self->manager;
   if (defined($manager)) {
      return 1;
   }

   $pool_size ||= $self->pool_size;

   $manager = Parallel::ForkManager->new(
      $pool_size,
   );

   $self->manager($manager);

   return 1;
}

sub reset_manager {
   my $self = shift;

   my $manager = $self->manager;
   if (! defined($manager)) {
      return 1;
   }

   $manager->wait_all_children;
   $self->manager(undef);

   return 1;
}

sub start {
   my $self = shift;
   my ($sub) = @_;

   $self->brik_help_run_undef_arg('start', $sub) or return;
   my $ref = $self->brik_help_run_invalid_arg('start', $sub, 'CODE')
      or return;

   $self->create_manager or return;
   my $manager = $self->manager;

   my $pid = $manager->start and return 1;  # Success, return to parent

   # Continue within son
   $self->pid($pid);
   &{$sub}();

   $manager->finish;

   return 0;
}

sub stop {
   my $self = shift;

   my $manager = $self->manager;
   if (defined($manager)) {
      $manager->wait_all_children;
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   $self->reset_manager;

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::Worker::Parallel - worker::parallel Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
