package InfoSys::FreeDB::Response;

use 5.006;
use base qw( Exporter );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
require Exporter;

our $CODE_RX = '^\s*(\d{3})\s+(.*)';

# Exporter variable
our %EXPORT_TAGS = (
    'line_parse' => [ qw(
        $CODE_RX
    ) ],
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

# Exporter variable
our @EXPORT = qw(
);

# Exporter variable
our @EXPORT_OK = qw(
    $CODE_RX
);

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response - FreeDB response

=head1 SYNOPSIS

None. This is an abstract class.

=head1 ABSTRACT

FreeDB response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response> contains information about FreeDB responses.

=head1 EXPORT

By default nothing is exported.

=head2 line_parse

This tag contains variables useful to parse the messages from C<FreeDB> servers.

=over

=item $CODE_RX

Regular expression to parse the return code and the remaining tail.

=back

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<code>>

Passed to L<set_code()>. Mandatory option.

=item B<C<error>>

Passed to L<set_error()>.

=item B<C<result>>

Passed to L<set_result()>. Mandatory option.

=back

=back

=head1 METHODS

=over

=item get_code()

Returns the response code.

=item get_result()

Returns the response result text.

=item is_error()

Returns whether the response has an error or not.

=item set_code(VALUE)

Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
L<InfoSys::FreeDB::Entry>,
L<InfoSys::FreeDB::Entry::Track>,
L<InfoSys::FreeDB::Match>,
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
L<InfoSys::FreeDB::Response::Write::1>,
L<InfoSys::FreeDB::Response::Write::2>,
L<InfoSys::FreeDB::Site>

=head1 BUGS

None known (yet.)

=head1 HISTORY

First development: September 2003
Last update: October 2003

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

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, ( ref($class) || $class ) );
    return( $self->_initialize(@_) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::_initialize, first argument must be 'HASH' reference.");

    # code, SINGLE, mandatory
    exists( $opt->{code} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::_initialize, option 'code' is mandatory.");
    $self->set_code( $opt->{code} );

    # error, BOOLEAN
    exists( $opt->{error} ) && $self->set_error( $opt->{error} );

    # result, SINGLE, mandatory
    exists( $opt->{result} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::_initialize, option 'result' is mandatory.");
    $self->set_result( $opt->{result} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_code {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response}{code} );
}

sub get_result {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response}{result} );
}

sub is_error {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response}{error} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_code {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'code', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::set_code, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response}{code} = $val;
}

sub set_error {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response}{error} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response}{error} = 0;
    }
}

sub set_result {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'result', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::set_result, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response}{result} = $val;
}

