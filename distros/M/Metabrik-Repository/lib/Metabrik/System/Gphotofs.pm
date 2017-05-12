#
# $Id: Gphotofs.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::gphotofs Brik
#
package Metabrik::System::Gphotofs;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable mtp mtpfs) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         mount_point => [ qw(directory) ],
      },
      attributes_default => {
      },
      commands => {
         install => [ ],  # Inherited
         mount => [ qw(mount_point|OPTIONAL) ],
         umount => [ qw(mount_point|OPTIONAL) ],
      },
      require_binaries => {
         gphotofs => [ ],
         fusermount => [ ],
      },
      need_packages => {
         ubuntu => [ qw(gphotofs fuse) ],
         debian => [ qw(gphotofs fuse) ],
      },
   };
}

sub mount {
   my $self = shift;
   my ($mount_point) = @_;

   $mount_point ||= $self->mount_point;
   $self->brik_help_run_undef_arg('mount', $mount_point) or return;
   $self->brik_help_run_directory_not_found('mount', $mount_point) or return;

   my $cmd = 'gphotofs "'.$mount_point.'" -o allow_other';

   $self->use_sudo(1);

   return $self->execute($cmd);
}

sub umount {
   my $self = shift;
   my ($mount_point) = @_;

   $mount_point ||= $self->mount_point;
   $self->brik_help_run_undef_arg('umount', $mount_point) or return;
   $self->brik_help_run_directory_not_found('umount', $mount_point) or return;

   my $cmd = 'fusermount -u "'.$mount_point.'"';

   $self->use_sudo(1);

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Gphotofs - system::gphotofs Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
