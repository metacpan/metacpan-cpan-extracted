package InfoSys::FreeDB::Response::Proto;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use InfoSys::FreeDB::Response qw(:line_parse);

# Used by _initialize
our %DEFAULT_VALUE = (
    'cur_level' => 0,
    'supported_level' => 0,
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::Proto - FreeDB proto response

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 
 # Create a CDDBP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
     protocol => 'CDDBP',
 } );
 
 # What's the current protocol level on FreeDB server?
 my $res = $conn->proto();
 
 # Write the current protocol level to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 $fh->print( "\n", $res->get_cur_level(), "\n" );
 
 # Set the protocol level to 3 on FreeDB server?
 $res = $conn->proto(3);

=head1 ABSTRACT

FreeDB proto response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Proto> contains information about FreeDB proto responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Proto> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<cur_level>>

Passed to L<set_cur_level()>. Defaults to B<0>.

=item B<C<supported_level>>

Passed to L<set_supported_level()>. Defaults to B<0>.

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

Creates a new C<InfoSys::FreeDB::Response::Proto> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_cur_level()

Returns the current protocol level.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item get_supported_level()

Returns the supported protocol level.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_cur_level(VALUE)

Set the current protocol level. C<VALUE> is the value. Default value at initialization is C<0>. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_supported_level(VALUE)

Set the supported protocol level. C<VALUE> is the value. Default value at initialization is C<0>. On error an exception C<Error::Simple> is thrown.

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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Proto::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    my @tail = split(/[,\s]+/, $tail, 7);
    if ($code == 200) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'CDDB protocol level',
            cur_level => $tail[4],
            supported_level => $tail[6],
        );
    }
    elsif ($code == 201) {
        %opt = (
            code => $code,
            result => 'OK, protocol version',
            cur_level => $tail[5],
        );
    }
    elsif ($code == 501) {
        %opt = (
            code => $code,
            result => 'Illegal protocol level',
        );
    }
    elsif ($code == 502) {
        %opt = (
            code => $code,
            result => 'Protocol level already cur_level',
            cur_level => $tail[3],
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Proto::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200, 201, 501 and 502.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Proto::_initialize, first argument must be 'HASH' reference.");

    # cur_level, SINGLE, with default value
    $self->set_cur_level( exists( $opt->{cur_level} ) ? $opt->{cur_level} : $DEFAULT_VALUE{cur_level} );

    # supported_level, SINGLE, with default value
    $self->set_supported_level( exists( $opt->{supported_level} ) ? $opt->{supported_level} : $DEFAULT_VALUE{supported_level} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_cur_level {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Proto}{cur_level} );
}

sub get_supported_level {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Proto}{supported_level} );
}

sub set_cur_level {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'cur_level', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Proto::set_cur_level, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Proto}{cur_level} = $val;
}

sub set_supported_level {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'supported_level', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Proto::set_supported_level, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Proto}{supported_level} = $val;
}

