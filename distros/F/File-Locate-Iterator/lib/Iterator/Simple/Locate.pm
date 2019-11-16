# Copyright 2009, 2010, 2011, 2014, 2017, 2018, 2019 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.


package Iterator::Simple::Locate;
use 5.006;
use strict;
use warnings;
use File::Locate::Iterator;
use Iterator::Simple;

our $VERSION = 28;

sub new {
  my $class = shift;
  my $it = File::Locate::Iterator->new (@_);
  return Iterator::Simple::iterator (sub { $it->next });
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Iterator::Simple::Locate -- read "locate" database with Iterator::Simple

=head1 SYNOPSIS

 use Iterator::Simple::Locate;
 my $it = Iterator::Simple::Locate->new;
 while (defined (my $entry = $it->())) {
   print $entry,"\n";
 }

=head1 DESCRIPTION

C<Iterator::Simple::Locate> reads a "locate" database file in iterator
style.  It allows the various L<Iterator::Simple> features to be used to
filter or crunch entries from the locate database read by an underlying
L<File::Locate::Iterator>.

See F<examples/iterator-simple.pl> for a simple complete program and
F<examples/mini-locate.pl> for a bigger program.

=head1 FUNCTIONS

=over 4

=item C<< $it = Iterator::Simple::Locate->new (key=>value,...) >>

Create and return a new C<Iterator::Simple> object.  Optional key/value
pairs as passed to C<< File::Locate::Iterator->new() >>.

=item C<< $entry = $it->() >>

Return the next entry from the database, or return C<undef> when no more
entries.

=back

=head1 SEE ALSO

L<Iterator::Simple>, L<File::Locate::Iterator>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/file-locate-iterator/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2014, 2017, 2018, 2019 Kevin Ryde

File-Locate-Iterator is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

File-Locate-Iterator is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
File-Locate-Iterator.  If not, see http://www.gnu.org/licenses/

=cut
