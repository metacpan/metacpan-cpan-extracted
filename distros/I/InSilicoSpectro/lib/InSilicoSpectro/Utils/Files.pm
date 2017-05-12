use strict;

package InSilicoSpectro::Utils::Files;
require Exporter;

=head1 NAME

InSilicoSpectro::Utils::Files

=head1 DESCRIPTION

Miscelaneous Files utilities

=head1 FUNCTIONS

=head3 rmdirRecursive($dir, [$limit])

Remove recursively directory $dir (dies if there is more than $limit files in it)

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

our (@ISA,@EXPORT,@EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw(&rmdirRecursive);
@EXPORT_OK = ();

use File::Find::Rule;
use File::Spec;
use Carp;

sub rmdirRecursive{
  my ($dir, $limit)=@_;
  my @files=File::Find::Rule->file()->in($dir);
  my $n=scalar @files;
  croak "attempt to remove $n files (>$limit)" if (defined $limit) && ($n>$limit);
  foreach(@files){
    unlink $_ or croak "cannot remove $_: $!";
  }
  my @dirs=File::Find::Rule->directory->in($dir);
  foreach (reverse sort @dirs){
    rmdir $_ or croak "cannot rmdir $_: $!";
  }
}


1;
