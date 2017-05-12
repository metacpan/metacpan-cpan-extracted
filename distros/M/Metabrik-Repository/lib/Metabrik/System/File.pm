#
# $Id: File.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::file Brik
#
package Metabrik::System::File;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable chmod chgrp cp copy move rm mv remove mkdir mkd) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         overwrite => 0,
      },
      commands => {
         mkdir => [ qw(directory) ],
         rmdir => [ qw(directory) ],
         chmod => [ qw(file perms) ],
         chgrp => [ qw(file) ],
         copy => [ qw(source destination) ],
         sudo_copy => [ qw(source destination) ],
         move => [ qw(source destination) ],
         remove => [ qw(file|$file_list) ],
         rename => [ qw(source destination) ],
         cat => [ qw(source destination) ],
         create => [ qw(file size) ],
         glob => [ qw(pattern) ],
         is_relative => [ qw(path) ],
         is_absolute => [ qw(path) ],
         to_absolute_path => [ qw(path basepath|OPTIONAL) ],
         basefile => [ qw(path) ],
         basedir => [ qw(path) ],
         link => [ qw(from to) ],
         uniq => [ qw(input output) ],
         count => [ qw(input) ],
         touch => [ qw(file) ],
      },
      require_modules => {
         'File::Copy' => [ qw(mv copy) ],
         'File::Path' => [ qw(make_path) ],
         'File::Spec' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(coreutils) ],
         debian => [ qw(coreutils) ],
      },
      require_binaries => {
         sort => [ ],
         wc => [ ],
      },
   };
}

sub mkdir {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('mkdir', $path) or return;

   my $no_error = 1;
   File::Path::make_path($path, { error => \my $error });
   if ($error) {
      for my $this (@$error) {
         my ($file, $message) = %$this;
         if ($file eq '') {
            return $self->log->error("mkdir: make_path failed with error [$message]");
         }
         else {
            $self->log->warning("mkdir: error creating directory [$file]: error [$error]");
            $no_error = 0;
         }
      }
   }

   return $no_error;
}

sub rmdir {
}

sub chmod {
   my $self = shift;
   my ($file, $perms) = @_;

   $self->brik_help_run_undef_arg('chmod', $file) or return;
   my $ref = $self->brik_help_run_invalid_arg('chmod', $file, 'SCALAR', 'ARRAY')
      or return;
   $self->brik_help_run_undef_arg('chmod', $perms) or return;

   my $r;
   if ($ref eq 'ARRAY') {
      $r = CORE::chmod(oct($perms), @$file);
   }
   else {
      $r = CORE::chmod(oct($perms), $file);
   }

   if (! $r) {
      return $self->log->error("chmod: failed to chmod file [$file]: $!");
   }

   return $file;
}

sub chgrp {
}

sub copy {
   my $self = shift;
   my ($source, $destination) = @_;

   $self->brik_help_run_undef_arg('copy', $source) or return;
   $self->brik_help_run_undef_arg('copy', $destination) or return;

   my $r = File::Copy::copy($source, $destination);
   if (! $r) {
      return $self->log->error("copy: failed copying [$source] to [$destination]: error [$!]");
   }

   return $destination;
}

sub sudo_copy {
   my $self = shift;
   my ($source, $destination) = @_;

   $self->brik_help_run_undef_arg('sudo_copy', $source) or return;
   $self->brik_help_run_undef_arg('sudo_copy', $destination) or return;

   return $self->sudo_execute("cp -rp $source $destination");
}

sub move {
   my $self = shift;
   my ($source, $destination) = @_;

   $self->brik_help_run_undef_arg('move', $source) or return;
   $self->brik_help_run_undef_arg('move', $destination) or return;

   my $r = File::Copy::mv($source, $destination);
   if (! $r) {
      return $self->log->error("move: failed moving [$source] to [$destination]: error [$!]");
   }

   return $destination;
}

sub remove {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('remove', $file) or return;
   my $ref = $self->brik_help_run_invalid_arg('remove', $file, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      for my $this (@$file) {
         unlink($this) or $self->log->warning("remove: unable to unlink file [$file]: $!");
      }
   }
   else {
      unlink($file) or return $self->log->warning("remove: unable to unlink file [$file]: $!");
   }

   return $file;
}

sub rename {
}

sub cat {
#File::Spec->catfile(source, dest)
}

sub create {
   my $self = shift;
   my ($file, $size) = @_;

   $self->brik_help_run_undef_arg('create', $file) or return;
   $self->brik_help_run_undef_arg('create', $size) or return;

   my $overwrite = $self->overwrite;
   if (-f $file && ! $self->overwrite) {
      return $self->log->error("create: file [$file] already exists, use overwrite Attribute");
   }

   if (-f $file) {
      $self->remove($file) or return;
   }

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->overwrite(1);
   $fw->open($file) or return;
   if ($size > 0) {
      $fw->write(sprintf("G"x$size));
   }
   else {
      $fw->write('');
   }
   $fw->close;

   return $file;
}

sub glob {
   my $self = shift;
   my ($pattern) = @_;

   my @list = CORE::glob("$pattern");

   return \@list;
}

sub is_relative {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('is_relative', $path) or return;

   my $r = File::Spec->file_name_is_absolute($path);

   # We negate it, cause we want the opposite of this function
   return $r ? 0 : 1;
}

sub is_absolute {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('is_absolute', $path) or return;

   # We negate it, cause we want the opposite of this function
   return $self->is_relative($path) ? 0 : 1;
}

sub to_absolute_path {
   my $self = shift;
   my ($path, $base) = @_;

   $self->brik_help_run_undef_arg('to_absolute_path', $path) or return;

   return File::Spec->rel2abs($path, $base);
}

#
# Returns the file part of a path (maybe be a directory)
#
sub basefile {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('basename', $path) or return;

   # Remove any trailing /
   $path =~ s{/*$}{};

   my ($volume, $directories, $file) = File::Spec->splitpath($path);

   return $file;
}

#
# Returns the directory part of a path
#
sub basedir {
   my $self = shift;
   my ($path) = @_;

   $self->brik_help_run_undef_arg('basedir', $path) or return;

   # Remove any trailing /
   $path =~ s{/*$}{};

   my ($volume, $directories, $file) = File::Spec->splitpath($path);

   # Remove any trailing /
   $directories =~ s{/*$}{};

   return $directories;
}

#
# Creates a link from a file to another name
#
sub link {
   my $self = shift;
   my ($from, $to) = @_;

   $self->brik_help_run_undef_arg('link', $from) or return;
   $self->brik_help_run_file_not_found('link', $from) or return;
   $self->brik_help_run_undef_arg('link', $to) or return;

   my $r = symlink($from, $to);
   if (! defined($r)) {
      return $self->log->error("link: failed with error: [$!]");
   }

   return $to;
}

#
# Remove duplicated lines
#
sub uniq {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('uniq', $input) or return;
   $self->brik_help_run_undef_arg('uniq', $output) or return;

   my $cmd = "sort -u \"$input\" > \"$output\"";

   $self->execute($cmd) or return;

   return $self->count($output);
}

#
# Count number of lines from a file
#
sub count {
   my $self = shift;
   my ($input) = @_;

   $self->brik_help_run_undef_arg('count', $input) or return;

   my $cmd = "wc -l \"$input\"";

   my $r = $self->capture($cmd) or return;

   if (@$r != 1) {
      return $r;
   }

   my ($count) = $r->[0] =~ m{^(\d+)};

   return $count;
}

#
# Just create an empty file
#
sub touch {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('touch', $file) or return;

   return $self->create($file, 0);
}

1;

__END__

=head1 NAME

Metabrik::System::File - system::file Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
