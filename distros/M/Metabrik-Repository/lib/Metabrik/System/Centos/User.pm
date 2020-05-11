#
# $Id$
#
# system::centos::user Brik
#
package Metabrik::System::Centos::User;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable manage management creation group create) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         create_user => [ qw(user) ],
         add_user_to_group => [ qw(user group) ],
      },
      require_binaries => {
         adduser => [ ],
      },
      need_packages => {
         centos => [ qw(shadow-utils) ],
      },
   };
}

sub create_user {
   my $self = shift;
   my ($user) = @_;

   $self->brik_help_run_undef_arg('create_user', $user) or return;

   my $cmd = "adduser $user";

   return $self->sudo_execute($cmd);
}

sub add_user_to_group {
   my $self = shift;
   my ($user, $group) = @_;

   $self->brik_help_run_undef_arg('add_user_to_group', $user) or return;
   $self->brik_help_run_undef_arg('add_user_to_group', $group) or return;

   my $cmd = "adduser $user $group";

   return $self->sudo_execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Centos::User - system::centos::user Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
