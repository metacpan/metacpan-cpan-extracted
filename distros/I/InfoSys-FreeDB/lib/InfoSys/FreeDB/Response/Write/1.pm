package InfoSys::FreeDB::Response::Write::1;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use InfoSys::FreeDB::Response qw(:line_parse);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::Write::1 - FreeDB write first pass response

=head1 SYNOPSIS

This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.

=head1 ABSTRACT

FreeDB write first pass response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Write::1> contains information about FreeDB write first pass responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Write::1> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<categ>>

Passed to L<set_categ()>.

=item B<C<discid>>

Passed to L<set_discid()>.

=back

Options for C<OPT_HASH_REF> inherited through package B<C<InfoSys::FreeDB::Response>> may include:

=over

=item B<C<code>>

Passed to L<set_code()>. Mandatory option.

=item B<C<error>>

Passed to L<set_error()>.

=item B<C<result>>

Passed to L<set_result()>. Mandatory option.

=back

=item new_from_content_ref(CONTENT_REF)

Creates a new C<InfoSys::FreeDB::Response::Write::1> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item get_categ()

Returns the CD category.

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_discid()

Returns the CD disk ID number.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item set_categ(VALUE)

Set the CD category. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_discid(VALUE)

Set the CD disk ID number. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
L<InfoSys::FreeDB::Entry>,
L<InfoSys::FreeDB::Entry::Track>,
L<InfoSys::FreeDB::Match>,
L<InfoSys::FreeDB::Response>,
L<InfoSys::FreeDB::Response::DiscId>,
L<InfoSys::FreeDB::Response::Hello>,
L<InfoSys::FreeDB::Response::LsCat>,
L<InfoSys::FreeDB::Response::Motd>,
L<InfoSys::FreeDB::Response::Proto>,
L<InfoSys::FreeDB::Response::Query>,
L<InfoSys::FreeDB::Response::Quit>,
L<InfoSys::FreeDB::Response::Read>,
L<InfoSys::FreeDB::Response::SignOn>,
L<InfoSys::FreeDB::Response::Sites>,
L<InfoSys::FreeDB::Response::Stat>,
L<InfoSys::FreeDB::Response::Ver>,
L<InfoSys::FreeDB::Response::Whom>,
L<InfoSys::FreeDB::Response::Write::2>,
L<InfoSys::FreeDB::Site>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: September 2003
Last update: December 2003

=head1 AUTHOR

Vincenzo Zocca

=head1 COPYRIGHT

Copyright 2003 by Vincenzo Zocca

=head1 LICENSE

This file is part of the C<InfoSys::FreeDB> module hierarchy for Perl by
Vincenzo Zocca.

The InfoSys::FreeDB module hierarchy is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

The InfoSys::FreeDB module hierarchy is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the InfoSys::FreeDB module hierarchy; if not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

=cut

sub new_from_content_ref {
    my $class = shift;
    my $content_ref = shift;

    # Convert $opt->{content_ref} to @content_ref
    my @content_ref = split(/[\n\r]+/, ${$content_ref} );

    # Parse first line
    my $line = shift(@content_ref);
    my ($code, $tail) = $line =~ /$CODE_RX/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Write::1::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 320) {
        my @tail = split(/\s+/, $tail, 2);
        %opt = (
            categ => $tail[0],
            code => $code,
            discid => $tail[1],
            result => 'OK, input CDDB data',
        );
    }
    elsif ($code == 401) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Permission denied',
        );
    }
    elsif ($code == 402) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Server file system full/file access failed',
        );
    }
    elsif ($code == 409) {
        %opt = (
            code => $code,
            error => 1,
            result => 'No handshake',
        );
    }
    elsif ($code == 501) {
        %opt = (
            code => $code,
            error => 1,
            result => 'Entry rejected: ' . $tail,
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Write::1::new_from_content_ref, unknown code '$code' returned. Allowed codes are 320, 401, 402, 409 and 501.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Write::1::_initialize, first argument must be 'HASH' reference.");

    # categ, SINGLE
    exists( $opt->{categ} ) && $self->set_categ( $opt->{categ} );

    # discid, SINGLE
    exists( $opt->{discid} ) && $self->set_discid( $opt->{discid} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_categ {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Write_1}{categ} );
}

sub get_discid {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Write_1}{discid} );
}

sub set_categ {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'categ', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Write::1::set_categ, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Write_1}{categ} = $val;
}

sub set_discid {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'discid', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Write::1::set_discid, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Write_1}{discid} = $val;
}

