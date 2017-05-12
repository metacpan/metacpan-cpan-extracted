#
# $Id: Type.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# file::type Brik
#
package Metabrik::File::Type;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         get_mime_type => [ qw(file|file_list) ],
         get_magic_type => [ qw(file|file_list) ],
         is_mime_type => [ qw(file|file_list mime_type) ],
         is_magic_type => [ qw(file|file_list mime_type) ],
         get_types => [ qw(file|file_list) ],
      },
      require_modules => {
         'File::LibMagic' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libmagic-dev) ],
         debian => [ qw(libmagic-dev) ],
      },
   };
}

sub get_mime_type {
   my $self = shift;
   my ($files) = @_;

   $self->brik_help_run_undef_arg('get_mime_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('get_mime_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $magic = File::LibMagic->new;

   if ($ref eq 'ARRAY') {
      my $types = {};
      for my $file (@$files) {
         my $type = $self->get_mime_type($file) or next;
         $types->{$file} = $type;
      }

      return $types;
   }
   else {
      $self->brik_help_run_file_not_found('get_mime_type', $files) or return;
      my $info = $magic->info_from_filename($files);

      return $info->{mime_type};
   }

   # Error
   return;
}

sub get_magic_type {
   my $self = shift;
   my ($files) = @_;

   $self->brik_help_run_undef_arg('get_magic_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('get_magic_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $magic = File::LibMagic->new;

   if ($ref eq 'ARRAY') {
      my $types = {};
      for my $file (@$files) {
         my $type = $self->get_magic_type($file) or next;
         $types->{$file} = $type;
      }
      return $types;
   }
   else {
      $self->brik_help_run_file_not_found('get_magic_type', $files) or return;
      my $info = $magic->info_from_filename($files);
      return $info->{description};
   }

   # Error
   return;
}

sub is_mime_type {
   my $self = shift;
   my ($files, $mime_type) = @_;

   $self->brik_help_run_undef_arg('is_mime_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_mime_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $types = {};
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('is_mime_type', $files) or return;
      for my $file (@$files) {
         my $res = $self->is_mime_type($file, $mime_type) or next;
         $types->{$files} = $res;
      }
   }
   else {
      my $type = $self->get_mime_type($files, $mime_type) or return;
      if ($type eq $mime_type) {
         $types->{$files} = 1;
      }
      else {
         $types->{$files} = 0;
      }
   }

   return $ref eq 'ARRAY' ? $types : $types->{$files};
}

sub is_magic_type {
   my $self = shift;
   my ($files, $magic_type) = @_;

   $self->brik_help_run_undef_arg('is_magic_type', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_magic_type', $files, 'ARRAY', 'SCALAR')
      or return;

   my $types = {};
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('is_magic_type', $files) or return;
      for my $file (@$files) {
         my $res = $self->is_magic_type($file, $magic_type) or next;
         $types->{$files} = $res;
      }
   }
   else {
      my $type = $self->get_magic_type($files, $magic_type) or return;
      if ($type eq $magic_type) {
         $types->{$files} = 1;
      }
      else {
         $types->{$files} = 0;
      }
   }

   return $ref eq 'ARRAY' ? $types : $types->{$files};
}

sub get_types {
   my $self = shift;
   my ($files) = @_;

   $self->brik_help_run_undef_arg('get_types', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('get_types', $files, 'ARRAY', 'SCALAR')
      or return;

   my $mime = $self->get_mime_type($files) or return;
   my $magic = $self->get_magic_type($files) or return;

   return {
      mime => $mime,
      magic => $magic,
   };
}

1;

__END__

=head1 NAME

Metabrik::File::Type - file::type Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
