# -*-CPerl-*-
# Last changed Time-stamp: <2017-05-28 13:54:04 mtw>

=head1 NAME

FileDirUtil - A Moose Role for basic File IO

=head1 SYNOPSIS

  package FooBar;
  use Moose;

  with 'FileDirUtil';

  sub BUILD {
     my $self = shift;
     $self->set_ifilebn;
  }

=head1 DESCRIPTION

FileDirUtil is a convenience Moose Role for basic File IO, providing
transparent access to L<Path::Class::File> and L<Path::Class::Dir> for
input files and output directories, respectively, via the following
attributes:

=over 3

=item ifile

A string representing the path to an input file in platform-native
syntax, e.g. I<'moo/foo.bar'>. This will be coerced into a
L<Path::Class::File> object.

=item odir

A L<Path::Class::Dir> object or an ArrayRef specifying path segments
of directories which will be joined to create a single
L<Path::Class::Dir> directory object.

=back

=cut

package FileDirUtil;

use version; our $VERSION = qv('0.03');
use Moose::Util::TypeConstraints;
use Moose::Role;
use Path::Class::File;
use Path::Class::Dir;
use File::Basename;
use Params::Coerce ();
use namespace::autoclean;

subtype 'MyFile' => as class_type('Path::Class::File');

coerce 'MyFile'
  => from 'Str'
  => via { Path::Class::File->new($_) };

subtype 'MyDir' => as class_type('Path::Class::Dir');

coerce 'MyDir'
  => from 'Object'
  => via {$_ -> isa('Path::Class::Dir') ? $_ : Params::Coerce::coerce ('Path::Class::Dir', $_); }
  => from 'ArrayRef'
  => via { Path::Class::Dir->new( @{ $_ } ) };

has 'ifile' => (
		is => 'ro',
		isa => 'MyFile',
		predicate => 'has_ifile',
		coerce => 1,
	      );

has 'ifilebn' => (
		  is => 'rw',
		  isa => 'Str',
		  predicate => 'has_ifilebn',
		  init_arg => undef, # make this unsettable via constructor
		 );

has 'odir' => (
	       is => 'rw',
	       isa => 'MyDir',
	       predicate => 'has_odir',
	       coerce => 1,
	      );

# This should be set automatically inside a BUILD methods, however it
# semms this doesnt work well for Roles. Hence do it the ugly way and
# call this method manually inside your object...
sub set_ifilebn {
    my $self = shift;
    $self->ifilebn(fileparse($self->ifile->basename, qr/\.[^.]*/));
};

# for perl tests below
package FDU;
use Moose;
with 'FileDirUtil';



__END__


=head1 SEE ALSO

=over

=item L<Path::Class::Dir>

=item L<Path::Class::File>

=back

=head1 AUTHOR

Michael T. Wolfinger, C<< <michael at wolfinger.eu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-filedirutil at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FileDirUtil>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FileDirUtil


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FileDirUtil>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FileDirUtil>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FileDirUtil>

=item * Search CPAN

L<http://search.cpan.org/dist/FileDirUtil/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Michael T. Wolfinger <michael@wolfinger.eu> and <michael.wolfinger@univie.ac.at>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with this program. If not, see
L<http://www.gnu.org/licenses/>.

=cut

1; 
