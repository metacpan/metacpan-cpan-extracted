#
# $Id: Mount.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::mount Brik
#
package Metabrik::System::Mount;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable mtab fstab) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ],  # Inherited
         is_device_mounted => [ qw(device) ],
         is_directory_mounted => [ qw(directory) ],
         get_device_mounted_directory => [ qw(device) ],
         umount_directory => [ qw(directory) ],
         umount_device => [ qw(device) ],
      },
      require_binaries => {
         mount => [ ],
      },
      need_packages => {
         ubuntu => [ qw(mount) ],
         debian => [ qw(mount) ],
      },
   };
}

sub is_device_mounted {
   my $self = shift;
   my ($device) = @_;

   $self->brik_help_run_undef_arg('is_device_mounted', $device) or return;

   $self->as_array(1);

   my $lines = $self->read('/etc/mtab') or return;
   return grep {/^\s*$device\s+/} @$lines;
}

sub is_directory_mounted {
   my $self = shift;
   my ($directory) = @_;

   $self->brik_help_run_undef_arg('is_directory_mounted', $directory) or return;

   $directory =~ s{/*$}{}g;

   $self->as_array(1);

   my $lines = $self->read('/etc/mtab') or return;
   return grep {/^\s*\S+\s+$directory\s+/} @$lines;
}

sub get_device_mounted_directory {
   my $self = shift;
   my ($device) = @_;

   $self->brik_help_run_undef_arg('get_device_mounted_directory', $device) or return;

   $self->as_array(1);

   my $lines = $self->read('/etc/mtab') or return;

   my $directory = '';
   for (@$lines) {
      if (/^\s*$device\s+(\S+)\s+/) {
         $directory = $1;
         last;
      }
   }

   $directory =~ s{/*$}{}g;

   return $directory;
}

sub umount_directory {
   my $self = shift;
   my ($directory) = @_;

   $self->brik_help_run_undef_arg('umount_directory', $directory) or return;

   $directory =~ s{/*$}{}g;

   my $is_mounted = $self->is_directory_mounted($directory);
   if (! defined($is_mounted)) {
      return;
   }

   if (! $is_mounted) {
      return $self->log->error("umount_directory: directory [$directory] not mounted");
   }

   my $cmd = 'umount '.$directory;
   return $self->sudo_execute($cmd);
}

sub umount_device {
   my $self = shift;
   my ($device) = @_;

   $self->brik_help_run_undef_arg('umount_device', $device) or return;

   my $is_mounted = $self->is_device_mounted($device);
   if (! defined($is_mounted)) {
      return;
   }

   if (! $is_mounted) {
      return $self->log->error("umount_device: device [$device] not mounted");
   }

   my $directory = $self->get_device_mounted_directory($device) or return;

   my $cmd = 'umount '.$directory;
   return $self->sudo_execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Mount - system::mount Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
