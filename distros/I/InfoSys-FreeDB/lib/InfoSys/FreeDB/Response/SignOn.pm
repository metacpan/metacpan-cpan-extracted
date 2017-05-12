package InfoSys::FreeDB::Response::SignOn;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use InfoSys::FreeDB::Response qw(:line_parse);

# Used by _initialize
our %DEFAULT_VALUE = (
    'connection_allowed' => 1,
    'read_allowed' => 1,
    'write_allowed' => 1,
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::SignOn - FreeDB sign-on response

=head1 SYNOPSIS

This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.

=head1 ABSTRACT

FreeDB sign-on response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::SignOn> contains information about FreeDB sign-on responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::SignOn> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<connection_allowed>>

Passed to L<set_connection_allowed()>. Defaults to B<1>.

=item B<C<date>>

Passed to L<set_date()>.

=item B<C<hostname>>

Passed to L<set_hostname()>.

=item B<C<read_allowed>>

Passed to L<set_read_allowed()>. Defaults to B<1>.

=item B<C<version>>

Passed to L<set_version()>.

=item B<C<write_allowed>>

Passed to L<set_write_allowed()>. Defaults to B<1>.

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

Creates a new C<InfoSys::FreeDB::Response::SignOn> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_date()

Returns the current date and time.

=item get_hostname()

Returns the server host name.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item get_version()

Returns the version number of server software.

=item is_connection_allowed()

Returns whether connecting is allowed or not.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item is_read_allowed()

Returns whether reading is allowed or not.

=item is_write_allowed()

Returns whether writing is allowed or not.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_connection_allowed(VALUE)

State that connecting is allowed. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_date(VALUE)

Set the current date and time. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_hostname(VALUE)

Set the server host name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_read_allowed(VALUE)

State that reading is allowed. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_version(VALUE)

Set the version number of server software. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_write_allowed(VALUE)

State that writing is allowed. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::SignOn::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    my @tail = split(/\s+/, $tail, 7);
    if ($code == 200) {
        %opt = (
            code => $code,
            result => 'OK, read/write allowed',
            hostname => $tail[0],
            version => $tail[3],
            date => $tail[6],
        );
    }
    elsif ($code == 201) {
        %opt = (
            code => $code,
            result => 'OK, read only',
            write_allowed => 0,
            hostname => $tail[0],
            version => $tail[3],
            date => $tail[6],
        );
    }
    elsif ($code == 432) {
        %opt = (
            code => $code,
            result => 'No connections allowed: permission denied',
            connection_allowed => 0,
            read_allowed => 0,
            write_allowed => 0,
            hostname => $tail[0],
            version => $tail[3],
            date => $tail[6],
        );
    }
    elsif ($code == 433) {
        %opt = (
            code => $code,
            result => 'No connections allowed: X users allowed, Y currently active',
            connection_allowed => 0,
            read_allowed => 0,
            write_allowed => 0,
            hostname => $tail[0],
            version => $tail[3],
            date => $tail[6],
        );
    }
    elsif ($code == 434) {
        %opt = (
            code => $code,
            result => 'No connections allowed: system load too high',
            connection_allowed => 0,
            read_allowed => 0,
            write_allowed => 0,
            hostname => $tail[0],
            version => $tail[3],
            date => $tail[6],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::SignOn::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200, 201, 432, 433 and 434.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::SignOn::_initialize, first argument must be 'HASH' reference.");

    # connection_allowed, BOOLEAN, with default value
    $self->set_connection_allowed( exists( $opt->{connection_allowed} ) ? $opt->{connection_allowed} : $DEFAULT_VALUE{connection_allowed} );

    # date, SINGLE
    exists( $opt->{date} ) && $self->set_date( $opt->{date} );

    # hostname, SINGLE
    exists( $opt->{hostname} ) && $self->set_hostname( $opt->{hostname} );

    # read_allowed, BOOLEAN, with default value
    $self->set_read_allowed( exists( $opt->{read_allowed} ) ? $opt->{read_allowed} : $DEFAULT_VALUE{read_allowed} );

    # version, SINGLE
    exists( $opt->{version} ) && $self->set_version( $opt->{version} );

    # write_allowed, BOOLEAN, with default value
    $self->set_write_allowed( exists( $opt->{write_allowed} ) ? $opt->{write_allowed} : $DEFAULT_VALUE{write_allowed} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_date {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_SignOn}{date} );
}

sub get_hostname {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_SignOn}{hostname} );
}

sub get_version {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_SignOn}{version} );
}

sub is_connection_allowed {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_SignOn}{connection_allowed} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_read_allowed {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_SignOn}{read_allowed} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub is_write_allowed {
    my $self = shift;

    if ( $self->{InfoSys_FreeDB_Response_SignOn}{write_allowed} ) {
        return(1);
    }
    else {
        return(0);
    }
}

sub set_connection_allowed {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_SignOn}{connection_allowed} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_SignOn}{connection_allowed} = 0;
    }
}

sub set_date {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'date', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::SignOn::set_date, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_SignOn}{date} = $val;
}

sub set_hostname {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'hostname', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::SignOn::set_hostname, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_SignOn}{hostname} = $val;
}

sub set_read_allowed {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_SignOn}{read_allowed} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_SignOn}{read_allowed} = 0;
    }
}

sub set_version {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'version', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::SignOn::set_version, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_SignOn}{version} = $val;
}

sub set_write_allowed {
    my $self = shift;

    if (shift) {
        $self->{InfoSys_FreeDB_Response_SignOn}{write_allowed} = 1;
    }
    else {
        $self->{InfoSys_FreeDB_Response_SignOn}{write_allowed} = 0;
    }
}

