# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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

package Math::OEIS::Names;
use 5.006;
use strict;
use Carp 'croak';

use Math::OEIS::SortedFile;
our @ISA = ('Math::OEIS::SortedFile');

our $VERSION = 10;

use constant base_filename => 'names';

# C<($anum,$str) = Math::OEIS::Names-E<gt>line_split($line)>
# Split a line from the names or stripped file into A-number and text.
# Not a documented feature yet.
sub line_split {
  my ($self, $line) = @_;
  ### Names line_split(): $line
  $line =~ /^((A\d+)\s*)(.*)/
    or return;  # perhaps comment lines
  return (substr($line,0,length($2)),
          substr($line,length($1),length($3)));
}

use constant::defer _HAVE_ENCODE => sub {
  eval { require Encode; 1 } || 0;
};

sub anum_to_name {
  my ($self, $anum) = @_;
  ### $anum
  my $line = $self->anum_to_line($anum);
  if (! defined $line) { return undef; }

  my ($got_anum, $name) = $self->line_split($line);
  if ($got_anum ne $anum) { return undef; }

  if (_HAVE_ENCODE) {
    $name = Encode::decode('utf8', $name, Encode::FB_PERLQQ());
  }
  return $name;
}


# sub anum_to_name {
#   my ($class, $anum) = @_;
#   $anum =~ /^A[0-9]+$/ or die "Bad A-number: ", $anum;
#   return `zgrep -e ^$anum $ENV{HOME}/OEIS/names.gz`;
# }

1;
__END__

=for stopwords OEIS gunzipped lookup UTF-8 Oopery filename filehandle Ryde

=head1 NAME

Math::OEIS::Names - read the OEIS F<names> file

=head1 SYNOPSIS

 my $name = Math::OEIS::Names->anum_to_name('A123456');

=head1 DESCRIPTION

This is an interface to the OEIS F<names> file.  The file should be
downloaded and unzipped to F<~/OEIS/names>,

    cd ~/OEIS
    wget http://oeis.org/names.gz
    gunzip names.gz

F<names> is a very large file listing each A-number and the sequence name.
The name is a single line description, perhaps a slightly long line.

The F<names> file is sorted by A-number so C<anum_to_name()> is a text file
binary search (currently implemented with L<Search::Dict>).

Terms of use for the names file data can be found at (Creative Commons
Attribution Non-Commercial 3.0, at the time of writing).

=over

L<http://oeis.org/wiki/The_OEIS_End-User_License_Agreement>

=back

=head1 FUNCTIONS

=over

=item C<$name = Math::OEIS::Names-E<gt>anum_to_name($anum)>

For a given C<$anum> string such as "A000001" return the sequence name
as a string, or if not found then return C<undef>.

The returned C<$name> may contain non-ASCII characters.  In Perl 5.8 up
they're returned as Perl wide chars.  In earlier Perl C<$name> is the native
encoding of the names file (which is UTF-8).

=item C<Math::OEIS::Names-E<gt>close()>

Close the F<names> file, if not already closed.

=back

=head2 Oopery

=over

=item C<$obj = Math::OEIS::Names-E<gt>new (key =E<gt> value, ...)>

Create and return a new C<Math::OEIS::Names> object to read an OEIS "names"
file.  The optional key/value parameters are

    filename => $filename         default ~/OEIS/names
    fh       => $filehandle

The default filename is F<~/OEIS/names>, or other directory per
F<Math::OEIS-E<gt>local_directories()> .  A different filename can be given
or an open filehandle.  When reading an C<fh> the C<filename> can be given
too and may be used in diagnostics.

=item C<$name = $obj-E<gt>anum_to_name($anum)>

For a given C<$anum> string such as "A000001" return the sequence name
as a string, or if not found then return C<undef>.

When running in C<perl -T> taint mode the C<$name> returned is tainted in
the usual way for reading from a file.

=item C<$filename = $obj-E<gt>filename()>

Return the F<names> filename from a given C<$obj> object.  This is the
C<filename> parameter if given, or C<default_filename()> otherwise.

=item C<$filename = Math::OEIS::Names-E<gt>default_filename()>

=item C<$filename = $obj-E<gt>default_filename()>

Return the default filename which is used if no C<filename> or C<fh> option
is given.  C<default_filename()> can be called either as a class method or
object method.

=item C<$obj-E<gt>close()>

Close the file handle, if not already closed.

=back

=head1 SEE ALSO

C<Math::OEIS>,
C<Math::OEIS::Stripped>

OEIS files page L<http://oeis.org/allfiles.html>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-oeis/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
