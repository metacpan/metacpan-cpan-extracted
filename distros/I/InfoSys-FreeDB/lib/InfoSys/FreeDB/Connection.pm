package InfoSys::FreeDB::Connection;

use 5.006;
use base qw( Exporter );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
require Exporter;

our $FINAL_DOT_RX = '[\r\n]\.[\r\n]';

our $FINAL_EOL_RX = '[\r\n]';

# Used by _initialize
our %DEFAULT_VALUE = (
    'proto_level' => 1,
    'proxy_port' => 8080,
);

# Exporter variable
our %EXPORT_TAGS = (
    'line_parse' => [ qw(
        $FINAL_DOT_RX
        $FINAL_EOL_RX
    ) ],
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

# Exporter variable
our @EXPORT = qw(
);

# Exporter variable
our @EXPORT_OK = qw(
    $FINAL_DOT_RX
    $FINAL_EOL_RX
);

1;

__END__

=head1 NAME

InfoSys::FreeDB::Connection - FreeDB abstract connection

=head1 SYNOPSIS

None. This is an abstract class.

=head1 ABSTRACT

FreeDB abstract connection

=head1 DESCRIPTION

C<InfoSys::FreeDB::Connection> is the abstract connection class of the C<InfoSys::FreeDB> module hierarchy.

=head1 EXPORT

By default nothing is exported.

=head2 line_parse

This tag contains variables useful to parse the messages from C<FreeDB> servers.

=over

=item $FINAL_DOT_RX

Regular expression to parse the end of message dot.

=item $FINAL_EOL_RX

Regular expression to parse the end of line.

=back

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Connection> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<client_host>>

Passed to L<set_client_host()>. Mandatory option.

=item B<C<client_name>>

Passed to L<set_client_name()>. Mandatory option.

=item B<C<client_user>>

Passed to L<set_client_user()>. Mandatory option.

=item B<C<client_version>>

Passed to L<set_client_version()>. Mandatory option.

=item B<C<freedb_host>>

Passed to L<set_freedb_host()>. Mandatory option.

=item B<C<freedb_port>>

Passed to L<set_freedb_port()>. Mandatory option.

=item B<C<proto_level>>

Passed to L<set_proto_level()>. Defaults to B<1>.

=item B<C<proxy_host>>

Passed to L<set_proxy_host()>.

=item B<C<proxy_passwd>>

Passed to L<set_proxy_passwd()>.

=item B<C<proxy_port>>

Passed to L<set_proxy_port()>. Defaults to B<8080>.

=item B<C<proxy_user>>

Passed to L<set_proxy_user()>.

=back

=back

=head1 METHODS

=over

=item connect()

This is an interface method. Connects the object to the FreeDB information service using the object's attributes. A C<hello> commend is sent out, the protocol level is queried and set to the highest level available. On error an exception C<Error::Simple> is thrown.

=item discid(ENTRY)

Issues a C<discid> command on the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. On error an exception C<Error::Simple> is thrown.

=item disconnect()

Disconnects the object from the FreeDB information service.

=item get_client_host()

Returns the connecting client host.

=item get_client_name()

Returns the connecting client name.

=item get_client_user()

Returns the connecting client user.

=item get_client_version()

Returns the connecting client version.

=item get_freedb_host()

Returns the FreeDB host.

=item get_freedb_port()

Returns the FreeDB port.

=item get_proto_level()

Returns the current protocol level.

=item get_proxy_host()

Returns the proxy host to use.

=item get_proxy_passwd()

Returns the proxy password to use.

=item get_proxy_port()

Returns the proxy port to use.

=item get_proxy_user()

Returns the proxy user name to use.

=item log()

This is an interface method. Issues a C<log> command on the FreeDB database. TO BE SPECIFIED

=item lscat()

Issues an C<lscat> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::LsCat> object. On error an exception C<Error::Simple> is thrown.

=item motd()

Issues an C<motd> command on the FreeDB database. Returns C<InfoSys::FreeDB::Response::Motd> object. On error an exception C<Error::Simple> is thrown.

=item proto([ LEVEL ])

This is an interface method. Issues a C<proto> command on the FreeDB database. If C<LEVEL> is not specified, the protocol level is queried. If C<LEVEL> is specified it is used to set the protocol level. Returns C<InfoSys::FreeDB::Response::Proto> object. On error an exception C<Error::Simple> is thrown.

=item query(ENTRY)

Queries the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. Returns a C<InfoSys::FreeDB::Response::Query> object. On error an exception C<Error::Simple> is thrown.

=item quit()

This is an interface method. Issues a C<quit> command on the FreeDB database and disconnects. Returns C<InfoSys::FreeDB::Response::Quit> object. On error an exception C<Error::Simple> is thrown.

=item read(MATCH)

Reads an entry from the FreeDB database. C<MATCH> is a C<InfoSys::FreeDB::Match> object. Returns a C<InfoSys::FreeDB::Response::Match> object. On error an exception C<Error::Simple> is thrown.

=item set_client_host(VALUE)

Set the connecting client host. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_name(VALUE)

Set the connecting client name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_user(VALUE)

Set the connecting client user. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_version(VALUE)

Set the connecting client version. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_freedb_host(VALUE)

Set the FreeDB host. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_freedb_port(VALUE)

Set the FreeDB port. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_proto_level(VALUE)

Set the current protocol level. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_proxy_host(VALUE)

Set the proxy host to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proxy_passwd(VALUE)

Set the proxy password to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proxy_port(VALUE)

Set the proxy port to use. C<VALUE> is the value. Default value at initialization is C<8080>. On error an exception C<Error::Simple> is thrown.

=item set_proxy_user(VALUE)

Set the proxy user name to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item sites()

Issues a C<sites> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Sites> object. On error an exception C<Error::Simple> is thrown.

=item stat()

Issues a C<stat> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Stat> object. On error an exception C<Error::Simple> is thrown.

=item update()

This is an interface method. Issues a C<update> command on the FreeDB database. TO BE SPECIFIED

=item ver()

Issues a C<ver> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Ver> object. On error an exception C<Error::Simple> is thrown.

=item whom()

Issues a C<whom> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Whom> object. On error an exception C<Error::Simple> is thrown.

=item write(ENTRY, CATEGORY)

This is an interface method. Writes an entry to the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. C<CATEGORY> is a valid FreeDB category. Returns a C<InfoSys::FreeDB::Response::Write::1> object in the case an error occurred in the first pass of the writing. Otherwise a C<InfoSys::FreeDB::Response::Write::2> object is returned. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
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
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, first argument must be 'HASH' reference.");

    # _connection_, SINGLE
    exists( $opt->{_connection_} ) && $self->set__connection_( $opt->{_connection_} );

    # client_host, SINGLE, mandatory
    exists( $opt->{client_host} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'client_host' is mandatory.");
    $self->set_client_host( $opt->{client_host} );

    # client_name, SINGLE, mandatory
    exists( $opt->{client_name} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'client_name' is mandatory.");
    $self->set_client_name( $opt->{client_name} );

    # client_user, SINGLE, mandatory
    exists( $opt->{client_user} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'client_user' is mandatory.");
    $self->set_client_user( $opt->{client_user} );

    # client_version, SINGLE, mandatory
    exists( $opt->{client_version} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'client_version' is mandatory.");
    $self->set_client_version( $opt->{client_version} );

    # freedb_host, SINGLE, mandatory
    exists( $opt->{freedb_host} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'freedb_host' is mandatory.");
    $self->set_freedb_host( $opt->{freedb_host} );

    # freedb_port, SINGLE, mandatory
    exists( $opt->{freedb_port} ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_initialize, option 'freedb_port' is mandatory.");
    $self->set_freedb_port( $opt->{freedb_port} );

    # proto_level, SINGLE, with default value
    $self->set_proto_level( exists( $opt->{proto_level} ) ? $opt->{proto_level} : $DEFAULT_VALUE{proto_level} );

    # proxy_host, SINGLE
    exists( $opt->{proxy_host} ) && $self->set_proxy_host( $opt->{proxy_host} );

    # proxy_passwd, SINGLE
    exists( $opt->{proxy_passwd} ) && $self->set_proxy_passwd( $opt->{proxy_passwd} );

    # proxy_port, SINGLE, with default value
    $self->set_proxy_port( exists( $opt->{proxy_port} ) ? $opt->{proxy_port} : $DEFAULT_VALUE{proxy_port} );

    # proxy_user, SINGLE
    exists( $opt->{proxy_user} ) && $self->set_proxy_user( $opt->{proxy_user} );

    # Return $self
    return($self);
}

sub _value_is_allowed {
    return(1);
}

sub _wait_command_reply {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::_wait_command_reply, call this method in a subclass that has implemented it.");
}

sub connect {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::connect, call this method in a subclass that has implemented it.");
}

sub discid {
    my $self = shift;
    my $entry = shift;

    # Send command and wait for reply
    my @cmd = ( 'discid', scalar( $entry->get_track() ) );
    foreach my $track ( $entry->get_track() ) {
        push( @cmd, $track->get_offset() );
    }
    push( @cmd, $entry->get_disc_length() );
    my $cmd = join( ' ', @cmd );
    my $content_ref = $self->_wait_command_reply($cmd, {
        200 => $FINAL_EOL_RX,
        500 => $FINAL_EOL_RX,
    } );

    # Parse the result
    require InfoSys::FreeDB::Response::DiscId;
    my $res = InfoSys::FreeDB::Response::DiscId->new_from_content_ref(
        $content_ref
    );

    # Write the discid in the entry
    $res->is_error() ||
        $entry->set_discid( $res->get_discid() );

    # Return the result
    return($res);
}

sub disconnect {
    my $self = shift;

    # Call quit
    return( $self->quit() );
}

sub get__connection_ {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{_connection_} );
}

sub get_client_host {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{client_host} );
}

sub get_client_name {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{client_name} );
}

sub get_client_user {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{client_user} );
}

sub get_client_version {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{client_version} );
}

sub get_freedb_host {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{freedb_host} );
}

sub get_freedb_port {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{freedb_port} );
}

sub get_proto_level {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{proto_level} );
}

sub get_proxy_host {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{proxy_host} );
}

sub get_proxy_passwd {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{proxy_passwd} );
}

sub get_proxy_port {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{proxy_port} );
}

sub get_proxy_user {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection}{proxy_user} );
}

sub log {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::log, call this method in a subclass that has implemented it.");
}

sub lscat {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'cddb lscat';
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::LsCat;
    return( InfoSys::FreeDB::Response::LsCat->new_from_content_ref(
        $content_ref
    ) );
}

sub motd {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'motd';
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
        401 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Motd;
    return( InfoSys::FreeDB::Response::Motd->new_from_content_ref(
        $content_ref
    ) );
}

sub proto {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::proto, call this method in a subclass that has implemented it.");
}

sub query {
    my $self = shift;
    my $entry = shift;

    # Make the discid
    $self->discid( $entry );

    # Send command and wait for reply
    my @cmd = (
        'cddb',
        'query',
        $entry->get_discid(),
        scalar( $entry->get_track() )
    );
    foreach my $track ( $entry->get_track() ) {
        push( @cmd, $track->get_offset() );
    }
    push( @cmd, $entry->get_disc_length() );
    my $cmd = join( ' ', @cmd );
    my $content_ref = $self->_wait_command_reply($cmd, {
        200 => $FINAL_EOL_RX,
        210 => $FINAL_EOL_RX,
        211 => $FINAL_DOT_RX,
        202 => $FINAL_EOL_RX,
        403 => $FINAL_EOL_RX,
        409 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Query;
    return( InfoSys::FreeDB::Response::Query->new_from_content_ref(
        $content_ref
    ) );
}

sub quit {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::quit, call this method in a subclass that has implemented it.");
}

sub read {
    my $self = shift;
    my $match = shift;

    # Send command and wait for reply
    my @cmd = (
        'cddb',
        'read',
        $match->get_categ(),
        $match->get_discid(),
    );
    my $cmd = join( ' ', @cmd );
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
        211 => $FINAL_DOT_RX,
        401 => $FINAL_EOL_RX,
        402 => $FINAL_EOL_RX,
        403 => $FINAL_EOL_RX,
        409 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Read;
    return( InfoSys::FreeDB::Response::Read->new_from_content_ref(
        $content_ref
    ) );
}

sub set__connection_ {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( '_connection_', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set__connection_, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{_connection_} = $val;
}

sub set_client_host {
    my $self = shift;
    my $val = shift;

    # Value for 'client_host' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_host, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_host', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_host, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{client_host} = $val;
}

sub set_client_name {
    my $self = shift;
    my $val = shift;

    # Value for 'client_name' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_name, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_name', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{client_name} = $val;
}

sub set_client_user {
    my $self = shift;
    my $val = shift;

    # Value for 'client_user' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_user, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_user', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_user, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{client_user} = $val;
}

sub set_client_version {
    my $self = shift;
    my $val = shift;

    # Value for 'client_version' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_version, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_version', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_client_version, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{client_version} = $val;
}

sub set_freedb_host {
    my $self = shift;
    my $val = shift;

    # Value for 'freedb_host' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_freedb_host, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'freedb_host', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_freedb_host, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{freedb_host} = $val;
}

sub set_freedb_port {
    my $self = shift;
    my $val = shift;

    # Value for 'freedb_port' is not allowed to be empty
    defined($val) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_freedb_port, value may not be empty.");

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'freedb_port', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_freedb_port, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{freedb_port} = $val;
}

sub set_proto_level {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proto_level', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_proto_level, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{proto_level} = $val;
}

sub set_proxy_host {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proxy_host', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_proxy_host, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{proxy_host} = $val;
}

sub set_proxy_passwd {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proxy_passwd', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_proxy_passwd, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{proxy_passwd} = $val;
}

sub set_proxy_port {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proxy_port', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_proxy_port, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{proxy_port} = $val;
}

sub set_proxy_user {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'proxy_user', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::set_proxy_user, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection}{proxy_user} = $val;
}

sub sites {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'sites';
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
        401 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Sites;
    return( InfoSys::FreeDB::Response::Sites->new_from_content_ref(
        $content_ref
    ) );
}

sub stat {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'stat';
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Stat;
    return( InfoSys::FreeDB::Response::Stat->new_from_content_ref(
        $content_ref
    ) );
}

sub update {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::update, call this method in a subclass that has implemented it.");
}

sub ver {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'ver';
    my $content_ref = $self->_wait_command_reply($cmd, {
        200 => $FINAL_EOL_RX,
        211 => $FINAL_DOT_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Ver;
    return( InfoSys::FreeDB::Response::Ver->new_from_content_ref(
        $content_ref
    ) );
}

sub whom {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'whom';
    my $content_ref = $self->_wait_command_reply($cmd, {
        210 => $FINAL_DOT_RX,
        401 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Whom;
    return( InfoSys::FreeDB::Response::Whom->new_from_content_ref(
        $content_ref
    ) );
}

sub write {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::write, call this method in a subclass that has implemented it.");
}

