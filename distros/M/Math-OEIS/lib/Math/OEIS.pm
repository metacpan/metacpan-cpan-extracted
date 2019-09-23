# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

# This file is part of Math-OEIS.
#
# Math-OEIS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-OEIS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-OEIS.  If not, see <http://www.gnu.org/licenses/>.

package Math::OEIS;
use 5.006;
use strict;
use warnings;
use File::Spec;

our $VERSION = 13;

sub local_directories {
  # my ($class) = @_;
  # {
  #   my $path = $ENV{'OEIS_PATH'};
  #   if (defined $path) {
  #     return split /:;/, $path;
  #   }
  # }
  {
    require File::HomeDir;
    my $dir = File::HomeDir->my_home;
    if (defined $dir) {
      return File::Spec->catdir($dir, 'OEIS');
    }
  }
  return ();
}

sub local_filename {
  my ($class, $filename) = @_;
  foreach my $dir ($class->local_directories) {
    my $fullname = File::Spec->catfile ($dir, $filename);
    if (-e $fullname) {
      return $fullname;
    }
  }
  return undef;
}

# sub anum_to_remote_url {
#   my ($anum) = @_;
#   return "http://oeis.org/$anum/";
# }


1;
__END__

=for stopwords Math OEIS filename Ryde ie

=head1 NAME

Math::OEIS - some Online Encyclopedia of Integer Sequences things

=head1 SYNOPSIS

=for test_synopsis my ($filename, $basename);

 use Math::OEIS;
 $filename = Math::OEIS->local_filename($basename);

=head1 FUNCTIONS

=over

=item C<@dirs = Math::OEIS-E<gt>local_directories()>

Return a list of local OEIS directories to look for downloaded sequences and
related files.  Currently this is only F<~/OEIS>, ie. an F<OEIS>
sub-directory of the user's home directory (per C<File::HomeDir>).

=item C<$filename = Math::OEIS-E<gt>local_filename($basename)>

Find file C<$basename> in one of the C<local_directories()> directories.  If
found then return a filename including directory part.  If not found then
return C<undef>.

=back

=cut

# If the C<$ENV{'OEIS_PATH'}> environment variable is set then it's used as a
# list of directories, split on C<:> or C<;> characters.  C<:> separators is
# intended as Unix style, or C<;> for MS-DOS
#
#     OEIS_PATH=/home/foo/OEIS:/var/cache/OEIS
#
# =head1 ENVIRONMENT VARIABLES
#
# =over
#
# =item C<OEIS_PATH>
#
# =back

=pod

=head1 SEE ALSO

L<Math::OEIS::Names>,
L<Math::OEIS::Stripped>,
L<Math::OEIS::Grep>

L<File::HomeDir>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-oeis/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2019 Kevin Ryde

Math-OEIS is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-OEIS is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-OEIS.  If not, see L<http://www.gnu.org/licenses/>.

=cut
