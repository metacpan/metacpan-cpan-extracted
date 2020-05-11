#
# $Id$
#
# file::find Brik
#
package Metabrik::File::Find;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         path => [ qw($path_list) ],
      },
      attributes_default => {
         path => [ '.' ],
      },
      commands => {
         all => [ qw(directory_pattern file_pattern) ],
         files => [ qw(directory|OPTIONAL file_pattern|OPTIONAL) ],
      },
      require_modules => {
         'File::Find' => [ ],
      },
   };
}

sub files {
   my $self = shift;
   my ($directory, $filepattern) = @_;

   $directory ||= '.';
   $filepattern ||= '.*';
   $self->brik_help_run_directory_not_found('files', $directory) or return;

   my $file_regex = qr/$filepattern/;
   my $dot_regex = qr/^\.$/;
   my $dot2_regex = qr/^\.\.$/;

   my @tmp_files = ();
   my $sub = sub {
      my $dir = $File::Find::dir;
      my $name = $File::Find::name;
      my $file = $_;
      # Skip dot and double dot directories
      if ($file =~ $dot_regex || $file =~ $dot2_regex) {
      }
      elsif ($file =~ $file_regex) {
         push @tmp_files, $name;
      }
   };

   {
      no warnings;
      File::Find::find($sub, ( $directory ));
   };

   @tmp_files = map { s/^\.\///; $_ } @tmp_files;  # Remove leading dot slash
   my %uniq_files = map { $_ => 1 } @tmp_files;
   my @files = sort { $a cmp $b } keys %uniq_files;
   @files = grep { -f $_ } @files; # Keep only files

   return \@files;
}

#sub directories {
#}

sub all {
   my $self = shift;
   my ($dirpattern, $filepattern) = @_;

   my $path = $self->path;
   $self->brik_help_run_undef_arg('all', $dirpattern) or return;
   $self->brik_help_run_undef_arg('all', $filepattern) or return;
   $self->brik_help_run_undef_arg('all', $path) or return;
   $self->brik_help_run_invalid_arg('all', $path, 'ARRAY') or return;

   my @dirs = ();
   my @files = ();

   # Escape dirpattern if we are searching for a directory hierarchy
   $dirpattern =~ s/\//\\\//g;

   my $dir_regex = qr/$dirpattern/;
   my $file_regex = qr/$filepattern/;
   my $dot_regex = qr/^\.$/;
   my $dot2_regex = qr/^\.\.$/;

   my $sub = sub {
      my $dir = $File::Find::dir;
      my $file = $_;
      # Skip dot and double dot directories
      if ($file =~ $dot_regex || $file =~ $dot2_regex) {
      }
      elsif ($dir =~ $dir_regex && $file =~ $file_regex) {
         push @dirs, "$dir/";
         push @files, "$dir/$file";
      }
   };

   {
      no warnings;
      File::Find::find($sub, @$path);
   };

   my %uniq_dirs = map { $_ => 1 } @dirs;
   my %uniq_files = map { $_ => 1 } @files;
   @dirs = sort { $a cmp $b } keys %uniq_dirs;
   @files = sort { $a cmp $b } keys %uniq_files;

   @dirs = map { s/^\.\///; $_ } @dirs;  # Remove leading dot slash
   @files = map { s/^\.\///; $_ } @files;  # Remove leading dot slash

   return {
      directories => \@dirs,
      files => \@files,
   };
}

1;

__END__

=head1 NAME

Metabrik::File::Find - file::find Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
