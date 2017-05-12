# Copyright 2009, 2010, 2011, 2014 Kevin Ryde.
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


package Iterator::Locate;
use 5.005;
use strict;
use File::Locate::Iterator;
use base 'Iterator';
use vars qw($VERSION);

$VERSION = 23;

sub new {
  my $class = shift;
  my $it = File::Locate::Iterator->new (@_);
  return $class->SUPER::new
    (sub {
       if (defined (my $entry = $it->next)) {
         return $entry;
       }
       Iterator::is_done();
     });
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Iterator::Locate -- read "locate" database with Iterator

=head1 SYNOPSIS

 use Iterator::Locate;
 my $it = Iterator::Locate->new;
 until ($it->is_exhausted) {
   my $entry = $it->value;
   print $entry,"\n";
 }

=head1 CLASS HIERARCHY

C<Iterator::Locate> is a subclass of C<Iterator>,

    Iterator
      Iterator::Locate

=head1 DESCRIPTION

An C<Iterator::Locate> object reads a "locate" database file in iterator
style.  It's a front-end to the C<File::Locate::Iterator> module, allowing
the various C<Iterator> module features to be used for filtering or
crunching entries from a locate database.

See F<examples/iterator-pm.pl> in the File-Locate-Iterator sources for a
simple complete program.

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<$it = Iterator::Locate-E<gt>new (key=E<gt>value,...)>

Create and return a new C<Iterator::Locate> object.  Optional key/value
arguments are passed to C<File::Locate::Iterator-E<gt>new>.

=back

=head1 SEE ALSO

L<Iterator>, L<File::Locate::Iterator>

=head1 HOME PAGE

http://user42.tuxfamily.org/file-locate-iterator/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2014 Kevin Ryde

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
