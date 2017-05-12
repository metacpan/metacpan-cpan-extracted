package Debian::WNPP::Bug;

use strict;
use warnings;

our $VERSION = '0.64';

=head1 NAME

Debian::WNPP::Bug - handy representation of Debian WNPP bug reports

=head1 SYNOPSIS

    my $b = Debian::WNPP::Bug->new(
        {   number            => 1234,
            title             => 'RFP: nice-package -- do nice things easier',
            type              => 'rfp',
            package           => 'nice-package',
            short_description => 'do nice things together',
            submitter         => "Joe Developer <joe@developer.local>"
        }
    );

    print "$b";     # 1234

=cut

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(
    qw(
        number title type package short_description submitter
        )
);

=head1 CONSTRUCTOR

=over

=item new

Constructs new instance of the class. Initial values are to be given as a hash
reference.

=back

=head1 FIELDS

=over

=item number

The unique ID of the big in the BTS.

=item title

The title of the bug. Usually something like

    RFP: nice-package -- do nice things easier

=item type

The type of the WNPP bug. Either of:

=over

=item RFP

request for package

=item ITP

intent to package

=item O

orphaned package

=item RFH

request for help

=item RFA

request for adoption

=item ITA

intent to adopt

=back

=item package

Package name

=item short_description

The short description of the package

=item submitter

The bug submitter in the form C<< Full Name <email@address> >>

=back

=head1 OVERLOADS

=over

=item ""

C<Debian::WNPPBug> object instances stringify via the method L<|as_string>. The
default C<as_string> method returns the bug number.

=cut

use overload '""' => \&as_string;

=back

=head1 METHODS

=over

=item type_and_number

Returns a string representing the bug type and number in the form I<TYPE>
#I<number>, e.g. C<ITP #1234>.

=cut

sub type_and_number {
    my $self = shift;
    return $self->type . ' #' . $self->number;
}

=item as_string

Used for the "" overload. Returns the bug number.

=cut

sub as_string {
    my $self = shift;
    return $self->number;
}

=back

=head1 AUTHOR

=over 4

=item Damyan Ivanov <dmn@debian.org>

=back

=head1 COPYRIGHT & LICENSE

=over 4

=item Copyright (C) 2010 Damyan Ivanov <dmn@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1;
