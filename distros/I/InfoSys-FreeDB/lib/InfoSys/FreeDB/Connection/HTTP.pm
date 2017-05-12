package InfoSys::FreeDB::Connection::HTTP;

use 5.006;
use base qw( InfoSys::FreeDB::Connection );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use LWP::UserAgent;

# Used by _initialize
our %DEFAULT_VALUE = (
    'freedb_cgi' => '~cddb/cddb.cgi',
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Connection::HTTP - FreeDB HTTP connection

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 require InfoSys::FreeDB::Entry;
 
 # Read entry from the default CD device
 my $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();
 
 # Create a HTTP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
 } );
 
 # Query FreeDB
 my $res_q = $conn->query( $entry );
 scalar( $res_q->get_match() ) ||
     die 'no matches found for the disck in the default CD-Rom drive';
 
 # Read the first match
 my $res_r = $conn->read( ( $res_q->get_match() )[0] );
 
 # Write the entry to STDERR
 use IO::Handle;
 my $fh = IO::Handle->new_from_fd( fileno(STDERR), 'w' );
 $res_r->get_entry()->write_fh( $fh );

=head1 ABSTRACT

FreeDB HTTP connection

=head1 DESCRIPTION

C<InfoSys::FreeDB::Connection::HTTP> is the HTTP implementation of the C<InfoSys::FreeDB::Connection> abstract class.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Connection::HTTP> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<freedb_cgi>>

Passed to L<set_freedb_cgi()>. Defaults to B<'~cddb/cddb.cgi'>.

=back

Options for C<OPT_HASH_REF> inherited through package B<C<InfoSys::FreeDB::Connection>> may include:

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

This method is an implementation from package C<InfoSys::FreeDB::Connection>. Connects the object to the FreeDB information service using the object's attributes. A C<hello> commend is sent out, the protocol level is queried and set to the highest level available. On error an exception C<Error::Simple> is thrown.

=over

=item SPEED-UP NOTE

If the C<freedb_host> isn't C<freedb.freedb.org> and protocol level C<1> is specified, the C<connect> method tries to use the highest available protocol level. To do so, it queries the FreeDB to find out exaclty which level is supported. On C<HTTP> connections this takes long. To speed up C<HTTP> connections specify a higher C<proto_level> -say C<5> before C<connect()> is called.

=back

=item discid(ENTRY)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<discid> command on the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. On error an exception C<Error::Simple> is thrown.

=item disconnect()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Disconnects the object from the FreeDB information service.

=item get_client_host()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client host.

=item get_client_name()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client name.

=item get_client_user()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client user.

=item get_client_version()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client version.

=item get_freedb_cgi()

Returns the FreeDB cgi.

=item get_freedb_host()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the FreeDB host.

=item get_freedb_port()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the FreeDB port.

=item get_proto_level()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the current protocol level.

=item get_proxy_host()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the proxy host to use.

=item get_proxy_passwd()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the proxy password to use.

=item get_proxy_port()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the proxy port to use.

=item get_proxy_user()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the proxy user name to use.

=item hello()

This method is not supported over C<HTTP>.

=item log()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<log> command on the FreeDB database. TO BE SPECIFIED

=item lscat()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues an C<lscat> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::LsCat> object. On error an exception C<Error::Simple> is thrown.

=item motd()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues an C<motd> command on the FreeDB database. Returns C<InfoSys::FreeDB::Response::Motd> object. On error an exception C<Error::Simple> is thrown.

=item proto([ LEVEL ])

This method is an implementation from package C<InfoSys::FreeDB::Connection>. This method is not supported over C<HTTP>.

=item query(ENTRY)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Queries the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. Returns a C<InfoSys::FreeDB::Response::Query> object. On error an exception C<Error::Simple> is thrown.

=item quit()

This method is an implementation from package C<InfoSys::FreeDB::Connection>. Issues a C<quit> command on the FreeDB database and disconnects. Returns C<InfoSys::FreeDB::Response::Quit> object. On error an exception C<Error::Simple> is thrown.

=item read(MATCH)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Reads an entry from the FreeDB database. C<MATCH> is a C<InfoSys::FreeDB::Match> object. Returns a C<InfoSys::FreeDB::Response::Match> object. On error an exception C<Error::Simple> is thrown.

=item set_client_host(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the connecting client host. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_name(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the connecting client name. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_user(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the connecting client user. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_client_version(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the connecting client version. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_freedb_cgi(VALUE)

Set the FreeDB cgi. C<VALUE> is the value. Default value at initialization is C<~cddb/cddb.cgi>. On error an exception C<Error::Simple> is thrown.

=item set_freedb_host(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the FreeDB host. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_freedb_port(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the FreeDB port. C<VALUE> is the value. C<VALUE> may not be C<undef>. On error an exception C<Error::Simple> is thrown.

=item set_proto_level(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the current protocol level. C<VALUE> is the value. Default value at initialization is C<1>. On error an exception C<Error::Simple> is thrown.

=item set_proxy_host(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the proxy host to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proxy_passwd(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the proxy password to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_proxy_port(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the proxy port to use. C<VALUE> is the value. Default value at initialization is C<8080>. On error an exception C<Error::Simple> is thrown.

=item set_proxy_user(VALUE)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Set the proxy user name to use. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item sites()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<sites> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Sites> object. On error an exception C<Error::Simple> is thrown.

=item stat()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<stat> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Stat> object. On error an exception C<Error::Simple> is thrown.

=item update()

This method is an implementation from package C<InfoSys::FreeDB::Connection>. THIS METHOD IS NOT YET IMPLEMENTED Issues a C<update> command on the FreeDB database. TO BE SPECIFIED_

=item ver()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<ver> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Ver> object. On error an exception C<Error::Simple> is thrown.

=item whom()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<whom> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::Whom> object. On error an exception C<Error::Simple> is thrown.

=item write(ENTRY, CATEGORY)

This method is an implementation from package C<InfoSys::FreeDB::Connection>. This method is not supported over C<HTTP>.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
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

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::HTTP::_initialize, first argument must be 'HASH' reference.");

    # freedb_cgi, SINGLE, with default value
    $self->set_freedb_cgi( exists( $opt->{freedb_cgi} ) ? $opt->{freedb_cgi} : $DEFAULT_VALUE{freedb_cgi} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _mk_hello {
    my $self = shift;

    return('&hello=' . join('+',
            $self->get_client_user(),
            $self->get_client_host(),
            $self->get_client_name(),
            $self->get_client_version(),
        ) .
        '&proto=' .
        $self->get_proto_level()
    );
}

sub _mk_url_base {
    my $self = shift;

    my $url = 'http://' .  $self->get_freedb_host();
    $url .= ':' . $self->get_freedb_port() if ($self->get_freedb_port() );
    $url .= '/' . $self->get_freedb_cgi();
    return($url);
}

sub _value_is_allowed {
    return(1);
}

sub _wait_command_reply {
    my $self = shift;
    my $cmd = shift;
    my $rx = shift;

    # Check if connection is defined
    defined( $self->get__connection_() ) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Connection::HTTP::_wait_command_reply, no connection available.');

    # Make url
    $cmd =~ s/\s+/\+/g;
    my $url = $self->_mk_url_base();
    $url .= '?cmd=' . $cmd . $self->_mk_hello();

    # Make request
    my $request = HTTP::Request->new(GET => $url);
    defined($request) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::_wait_command_reply, failed to make HTTP::Request object out of url '$url'.");

    # Set proxy authorization if required
    if ( $self->get_proxy_host() && $self->get_proxy_user() ) {
        $request->proxy_authorization_basic( $self->get_proxy_user(),
                                                   $self->get_proxy_passwd() );
    }

    # Execute the request through the connection
    my $response = $self->get__connection_()->simple_request($request);
    $response->is_success() ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::_wait_command_reply, failed to execute request for url '$url'.");

    # Return the content reference
    return( $response->content_ref() );
}

sub connect {
    my $self = shift;

    # Make connection through user agent
    my $connection = LWP::UserAgent->new();
    defined($connection) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::connect, Failed to instantiate an \'LWP::UserAgent\' object.");

    # Set _connection_
    $self->set__connection_($connection);

    # Set proxy if required
    if ( $self->get_proxy_host() ) {
        my $url =  'http://' . $self->get_proxy_host() . ':' .
                                                    $self->get_proxy_port();
        $connection->proxy ('http', $url);
    }

    # Return if the protocol level is greater than 1
    ( $self->get_proto_level() > 1 ) &&
        return(undef);

    # Return if the freedb_host is "freedb.freedb.org"
    ( $self->get_freedb_host() eq "freedb.freedb.org" ) &&
        return(undef);

    # Check the stat
    my $stat = $self->stat();

    # Disconnect and throw exception if error
    if ( $stat->is_error() ) {
        $self->set__connection_();
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::HTTP::connect, handshake failed, stat returned an error.");
    }

    # Set the highest protocol
    $self->set_proto_level( $stat->get_proto_max() );

    # Return undef
    return(undef);
}

sub get_freedb_cgi {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection_HTTP}{freedb_cgi} );
}

sub hello {
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::hello, this method is not supported over 'HTTP'.");
}

sub proto {
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::proto, this method is not supported over 'HTTP'.");
}

sub quit {
    require InfoSys::FreeDB::Response::Quit;
    return( InfoSys::FreeDB::Response::Quit->new( {
        code => 230,
        result => 'OK, goodbye',
        hostname => '<this.is.a.dummy.quit.response>',
    } ) );
}

sub set_freedb_cgi {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'freedb_cgi', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::HTTP::set_freedb_cgi, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection_HTTP}{freedb_cgi} = $val;
}

sub update {
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::update, THIS METHOD IS NOT YET IMPLEMENTED.");
}

sub write {
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::write, this method is not supported over 'HTTP'.");
}

