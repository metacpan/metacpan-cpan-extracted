package InfoSys::FreeDB::Response::Ver;

use 5.006;
use base qw( InfoSys::FreeDB::Response );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use InfoSys::FreeDB::Response qw(:line_parse);

# Used by _initialize
our %DEFAULT_VALUE = (
    'copyright' => 'Seet message_text.',
    'message_text' => 'See copyright and/or version',
    'version' => 'Seet message_text.',
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Response::Ver - FreeDB ver response

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Get ver from FreeDB
 my $res = $conn->ver();
 
 # Write a bit of ver to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 $fh->print( $res->get_message_text(), "\n" );

=head1 ABSTRACT

FreeDB ver response

=head1 DESCRIPTION

C<InfoSys::FreeDB::Response::Ver> contains information about FreeDB ver responses.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Response::Ver> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<copyright>>

Passed to L<set_copyright()>. Defaults to B<'Seet message_text.'>.

=item B<C<message_text>>

Passed to L<set_message_text()>. Defaults to B<'See copyright and/or version'>.

=item B<C<version>>

Passed to L<set_version()>. Defaults to B<'Seet message_text.'>.

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

Creates a new C<InfoSys::FreeDB::Response::Ver> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item get_code()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response code.

=item get_copyright()

Returns the copyright string.

=item get_message_text()

Returns the message text.

=item get_result()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns the response result text.

=item get_version()

Returns the version number of server software.

=item is_error()

This method is inherited from package C<InfoSys::FreeDB::Response>. Returns whether the response has an error or not.

=item set_code(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response code. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_copyright(VALUE)

Set the copyright string. C<VALUE> is the value. Default value at initialization is C<Seet message_text.>. On error an exception C<Error::Simple> is thrown.

=item set_error(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. State that the response has an error. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_message_text(VALUE)

Set the message text. C<VALUE> is the value. Default value at initialization is C<See copyright and/or version>. On error an exception C<Error::Simple> is thrown.

=item set_result(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Response>. Set the response result text. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_version(VALUE)

Set the version number of server software. C<VALUE> is the value. Default value at initialization is C<Seet message_text.>. On error an exception C<Error::Simple> is thrown.

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
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Ver::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 200) {
        my @tail = split(/\s+/, $tail, 3);
        %opt = (
            code => $code,
            result => 'Version information',
            version => $tail[1],
            copyright => $tail[2],
        );
    }
    elsif ($code == 211) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'OK',
            message_text => join("\n", @content_ref),
        );
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Ver::new_from_content_ref, unknown code '$code' returned. Allowed codes are 200 and 211.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Ver::_initialize, first argument must be 'HASH' reference.");

    # copyright, SINGLE, with default value
    $self->set_copyright( exists( $opt->{copyright} ) ? $opt->{copyright} : $DEFAULT_VALUE{copyright} );

    # message_text, SINGLE, with default value
    $self->set_message_text( exists( $opt->{message_text} ) ? $opt->{message_text} : $DEFAULT_VALUE{message_text} );

    # version, SINGLE, with default value
    $self->set_version( exists( $opt->{version} ) ? $opt->{version} : $DEFAULT_VALUE{version} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub get_copyright {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Ver}{copyright} );
}

sub get_message_text {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Ver}{message_text} );
}

sub get_version {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Response_Ver}{version} );
}

sub set_copyright {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'copyright', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Ver::set_copyright, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Ver}{copyright} = $val;
}

sub set_message_text {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'message_text', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Ver::set_message_text, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Ver}{message_text} = $val;
}

sub set_version {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'version', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Response::Ver::set_version, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Response_Ver}{version} = $val;
}

