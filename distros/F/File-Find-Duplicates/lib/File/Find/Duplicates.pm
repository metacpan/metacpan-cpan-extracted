package File::Find::Duplicates;

=head1 NAME

File::Find::Duplicates - Find duplicate files

=head1 SYNOPSIS

  use File::Find::Duplicates;

  my @dupes = find_duplicate_files('/basedir1', '/basedir2');

  foreach my $dupeset (@dupes) { 
    printf "Files %s (of size %d) hash to %s\n",
      join(", ", @{$dupeset->files}), $dupeset->size, $dupeset->md5;
  }

=head1 DESCRIPTION

This module provides a way of finding duplicate files on your system.

=head1 FUNCTIONS

=head2 find_duplicate_files

  my %dupes = find_duplicate_files('/basedir1', '/basedir2');

When passed a base directory (or list of such directories) it returns
a list of objects with the following methods:

=head2 files

A listref of the names of the duplicate files.

=head2 size

The size of the duplicate files.

=head2 md5

The md5 sum of the duplicate files.

=head1 TODO

Check the contents of tars, zipfiles etc to ensure none of these also
exist elsewhere (if so requested).

=head1 SEE ALSO

L<File::Find>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-File-Find-Duplicates@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2001-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

use strict;
use File::Find;
use Digest::MD5;
require Exporter;
use vars qw($VERSION @ISA @EXPORT);

@ISA     = qw/Exporter/;
@EXPORT  = qw/find_duplicate_files/;
$VERSION = '1.00';

use Class::Struct 'File::Find::Duplicates::Set' =>
  [ files => '@', size => '$', md5 => '$' ];

sub find_duplicate_files {
  my (@dupes, %files);
  find sub {
    -f && push @{ $files{ (stat(_))[7] } }, $File::Find::name;
  }, @_;
  foreach my $size (sort { $b <=> $a } keys %files) {
    next unless @{ $files{$size} } > 1;
    my %md5;
    foreach my $file (@{ $files{$size} }) {
      open(my $fh, $file) or next;
      binmode($fh);
      push @{ $md5{ Digest::MD5->new->addfile($fh)->hexdigest } }, $file;
    }

    push @dupes, map File::Find::Duplicates::Set->new(
      files => $md5{$_},
      size  => $size,
      md5   => $_,
      ),
      grep @{ $md5{$_} } > 1, keys %md5;
  }
  return @dupes;
}

return q/
 dissolving ... removing ... there is water at the bottom of the ocean
/;
