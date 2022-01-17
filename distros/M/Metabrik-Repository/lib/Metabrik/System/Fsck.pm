#
# $Id$
#
# system::fsck Brik
#
package Metabrik::System::Fsck;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package Metabrik::System::Mount);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable fat fat16 fat32 repair disk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ],  # Inherited
         fat => [ qw(device) ],
      },
      require_binaries => {
         dosfsck => [ ],
      },
      need_packages => {
         ubuntu => [ qw(dosfstools) ],
         debian => [ qw(dosfstools) ],
         kali => [ qw(dosfstools) ],
      },
   };
}

sub fat {
   my $self = shift;
   my ($device) = @_;

   $self->brik_help_run_undef_arg('fat', $device) or return;

   my $is_mounted = $self->is_device_mounted($device);
   if (! defined($is_mounted)) {
      return;
   }

   if ($is_mounted) {
      my $directory = $self->get_device_mounted_directory($device) or return;
      return $self->log->error("fat: you must unmount [$directory] first");
   }

   my $cmd = 'dosfsck -w -r -l -v "'.$device.'"';
   return $self->sudo_execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Fsck - system::fsck Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
