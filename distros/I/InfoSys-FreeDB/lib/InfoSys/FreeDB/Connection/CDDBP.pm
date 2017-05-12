package InfoSys::FreeDB::Connection::CDDBP;

use 5.006;
use base qw( InfoSys::FreeDB::Connection );
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use IO::Socket::INET;
use InfoSys::FreeDB::Connection qw(:line_parse);

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'sign_on_response' => [ 'InfoSys::FreeDB::Response::SignOn' ],
);

# Used by _value_is_allowed
our %ALLOW_REF = (
);

# Used by _value_is_allowed
our %ALLOW_RX = (
);

# Used by _value_is_allowed
our %ALLOW_VALUE = (
);

# Package version
our ($VERSION) = '$Revision: 0.92 $' =~ /\$Revision:\s+([^\s]+)/;

1;

__END__

=head1 NAME

InfoSys::FreeDB::Connection::CDDBP - FreeDB CDDBP connection

=head1 SYNOPSIS

 require InfoSys::FreeDB;
 require InfoSys::FreeDB::Entry;
 
 # Read entry from the default CD device
 my $entry = InfoSys::FreeDB::Entry->new_from_cdparanoia();
 
 # Create a CDDBP connection
 my $fact = InfoSys::FreeDB->new();
 my $conn = $fact->create_connection( {
     client_name => 'testing-InfoSys::FreeDB',
     client_version => $InfoSys::FreeDB::VERSION,
     protocol => 'CDDBP',
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

FreeDB CDDBP connection

=head1 DESCRIPTION

C<InfoSys::FreeDB::Connection::CDDBP> is the CDDBP implementation of the C<InfoSys::FreeDB::Connection> abstract class.

=head1 CONSTRUCTOR

=over

=item new(OPT_HASH_REF)

Creates a new C<InfoSys::FreeDB::Connection::CDDBP> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. C<OPT_HASH_REF> is mandatory. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<sign_on_response>>

Passed to L<set_sign_on_response()>.

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

=item discid(ENTRY)

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<discid> command on the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. On error an exception C<Error::Simple> is thrown.

=item disconnect()

This method is overloaded from package C<InfoSys::FreeDB::Connection>. Disconnects the object from the FreeDB information service.

=item get_client_host()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client host.

=item get_client_name()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client name.

=item get_client_user()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client user.

=item get_client_version()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Returns the connecting client version.

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

=item get_sign_on_response()

Returns the sign-on response.

=item hello()

Sends a hello command to the FreeDB server. Returns a C<InfoSys::FreeDB::Response::Hello> object. On error an exception C<Error::Simple> is thrown.

=item log()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues a C<log> command on the FreeDB database. TO BE SPECIFIED

=item lscat()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues an C<lscat> command on the FreeDB database. Returns a C<InfoSys::FreeDB::Response::LsCat> object. On error an exception C<Error::Simple> is thrown.

=item motd()

This method is inherited from package C<InfoSys::FreeDB::Connection>. Issues an C<motd> command on the FreeDB database. Returns C<InfoSys::FreeDB::Response::Motd> object. On error an exception C<Error::Simple> is thrown.

=item proto([ LEVEL ])

This method is an implementation from package C<InfoSys::FreeDB::Connection>. Issues a C<proto> command on the FreeDB database. If C<LEVEL> is not specified, the protocol level is queried. If C<LEVEL> is specified it is used to set the protocol level. Returns C<InfoSys::FreeDB::Response::Proto> object. On error an exception C<Error::Simple> is thrown.

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

=item set_sign_on_response(VALUE)

Set the sign-on response. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=over

=item VALUE must be a (sub)class of:

=over

=item InfoSys::FreeDB::Response::SignOn

=back

=back

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

This method is an implementation from package C<InfoSys::FreeDB::Connection>. THIS METHOD IS NOT YET TESTED Writes an entry to the FreeDB database. C<ENTRY> is a C<InfoSys::FreeDB::Entry> object. C<CATEGORY> is a valid FreeDB category. Returns a C<InfoSys::FreeDB::Response::Write::1> object in the case an error occurred in the first pass of the writing. Otherwise a C<InfoSys::FreeDB::Response::Write::2> object is returned. On error an exception C<Error::Simple> is thrown._

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
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

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::_initialize, first argument must be 'HASH' reference.");

    # sign_on_response, SINGLE
    exists( $opt->{sign_on_response} ) && $self->set_sign_on_response( $opt->{sign_on_response} );

    # Call the superclass' _initialize
    $self->SUPER::_initialize($opt);

    # Return $self
    return($self);
}

sub _mk_hello {
    my $self = shift;

    return('hello ' . join(' ',
        $self->get_client_user(),
        $self->get_client_host(),
        $self->get_client_name(),
        $self->get_client_version(),
    ) );
}

sub _value_is_allowed {
    my $name = shift;

    # Value is allowed if no ALLOW clauses exist for the named attribute
    if ( ! exists( $ALLOW_ISA{$name} ) && ! exists( $ALLOW_REF{$name} ) && ! exists( $ALLOW_RX{$name} ) && ! exists( $ALLOW_VALUE{$name} ) ) {
        return(1);
    }

    # At this point, all values in @_ must to be allowed
    CHECK_VALUES:
    foreach my $val (@_) {
        # Check ALLOW_ISA
        if ( ref($val) && exists( $ALLOW_ISA{$name} ) ) {
            foreach my $class ( @{ $ALLOW_ISA{$name} } ) {
                &UNIVERSAL::isa( $val, $class ) && next CHECK_VALUES;
            }
        }

        # Check ALLOW_REF
        if ( ref($val) && exists( $ALLOW_REF{$name} ) ) {
            exists( $ALLOW_REF{$name}{ ref($val) } ) && next CHECK_VALUES;
        }

        # Check ALLOW_RX
        if ( defined($val) && ! ref($val) && exists( $ALLOW_RX{$name} ) ) {
            foreach my $rx ( @{ $ALLOW_RX{$name} } ) {
                $val =~ /$rx/ && next CHECK_VALUES;
            }
        }

        # Check ALLOW_VALUE
        if ( ! ref($val) && exists( $ALLOW_VALUE{$name} ) ) {
            exists( $ALLOW_VALUE{$name}{$val} ) && next CHECK_VALUES;
        }

        # We caught a not allowed value
        return(0);
    }

    # OK, all values are allowed
    return(1);
}

sub _wait_command_reply {
    my $self = shift;
    my $cmd = shift;
    my $rx = shift;

    # Check if connection is defined
    defined( $self->get__connection_() ) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::_wait_command_reply, not connected.");

    # Set blocking
    $self->get__connection_->blocking(1);

    # Send command
    if ($cmd) {
        $self->get__connection_()->send($cmd . "\r\n");
    }

    # Wait for code
    $self->get__connection_()->recv(my $head, 5);
    $head =~ s/^\s+//;
    my ($code) = $head =~ /(\d{3})/;
    exists($rx->{$code}) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::_wait_command_reply, unknown code '$code' returned.");

    # Wait for the final DOT or EOL
    my $content .= $head;
    $self->get__connection_()->blocking(0);
    while (1) {
        $self->get__connection_()->recv(my $rest, 1024);
        $content .= $rest;
        $content =~ /$rx->{$code}/ && last;
        sleep(1);
    }

    # Return the content reference
    return(\$content);
}

sub _wait_write_reply {
    my $self = shift;
    my $entry = shift;
    my $rx = shift;

    # Check if connection is defined
    defined( $self->get__connection_() ) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::_wait_write_reply, not connected.");

    # Set blocking
    $self->get__connection_->blocking(1);

    # Send entry
    foreach my $line ( @{$entry} ) {
        $self->get__connection_()->send($line . "\r\n");
    }

    # Wait for code
    $self->get__connection_()->recv(my $head, 5);
    $head =~ s/^\s+//;
    my ($code) = $head =~ /(\d{3})/;
    exists($rx->{$code}) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::_wait_write_reply, unknown code '$code' returned.");

    # Wait for the final DOT or EOL
    my $content .= $head;
    $self->get__connection_()->blocking(0);
    while (1) {
        $self->get__connection_()->recv(my $rest, 1024);
        $content .= $rest;
        $content =~ /$rx->{$code}/ && last;
        sleep(1);
    }

    # Return the content reference
    return(\$content);
}

sub connect {
    my $self = shift;

    # Make socket connection
    my $host = $self->get_freedb_host();
    my $port = $self->get_freedb_port();
    my $connection = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
    );
    defined($connection) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::connect, handshake failed, failed to connect to host '$host', port '$port'.");

    # Set connection
    $self->set__connection_($connection);

    # Send command and wait for reply
    my $content_ref = $self->_wait_command_reply(undef, {
        200 => $FINAL_EOL_RX,
        201 => $FINAL_EOL_RX,
        432 => $FINAL_EOL_RX,
        433 => $FINAL_EOL_RX,
        434 => $FINAL_EOL_RX,
    } );

    # Parse the result and store it
    require InfoSys::FreeDB::Response::SignOn;
    $self->set_sign_on_response(
        InfoSys::FreeDB::Response::SignOn->new_from_content_ref(
            $content_ref
        ),
    );

    # Disconnect and throw exception if error
    if ( ! $self->get_sign_on_response()->is_connection_allowed() ) {
        $self->set__connection_();
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::connect, handshake failed, connection is not allowed.");
    }

    # Send a hello
    my $hello = $self->hello();

    # Disconnect and throw exception if error
    if ( $hello->is_error() ) {
        $self->set__connection_();
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::connect, handshake failed, hello returned an error.");
    }

    # Return if the protocol level is greater than 1
    ( $self->get_proto_level() > 1 ) &&
        return(undef);

    # Check the protocol
    my $proto = $self->proto();

    # Disconnect and throw exception if error
    if ( $proto->is_error() ) {
        $self->set__connection_();
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::connect, handshake failed, proto returned an error.");
    }

    # Set the highest protocol
    $proto = $self->proto( $proto->get_supported_level() );

    # Disconnect and throw exception if error
    if ( $proto->is_error() ) {
        $self->set__connection_();
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::connect, handshake failed, proto returned an error.");
    }

    # Return undef
    return(undef);
}

sub disconnect {
    my $self = shift;

    # Call quit
    return( $self->quit() );
}

sub get_sign_on_response {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Connection_CDDBP}{sign_on_response} );
}

sub hello {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'cddb ' . $self->_mk_hello();
    my $content_ref = $self->_wait_command_reply($cmd, {
        200 => $FINAL_EOL_RX,
        431 => $FINAL_EOL_RX,
        402 => $FINAL_EOL_RX,
    } );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Hello;
    return( InfoSys::FreeDB::Response::Hello->new_from_content_ref(
        $content_ref
    ) );
}

sub proto {
    my $self = shift;
    my $level = shift;

    # Send command and wait for reply
    my $cmd = 'proto';
    $cmd .= " $level" if ($level);
    my $content_ref = $self->_wait_command_reply($cmd, {
        200 => $FINAL_EOL_RX,
        201 => $FINAL_EOL_RX,
        501 => $FINAL_EOL_RX,
        502 => $FINAL_EOL_RX,
    } );

    # Parse result
    require InfoSys::FreeDB::Response::Proto;
    my $res = InfoSys::FreeDB::Response::Proto->new_from_content_ref(
        $content_ref
    );

    # Remember current protocol level
    $self->set_proto_level( $res->get_cur_level() );

    # Return the result
    return($res);
}

sub quit {
    my $self = shift;

    # Send command and wait for reply
    my $cmd = 'quit';
    my $content_ref = $self->_wait_command_reply($cmd, {
        230 => $FINAL_EOL_RX,
    } );

    # Clear the connection
    $self->set__connection_();

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Quit;
    return( InfoSys::FreeDB::Response::Quit->new_from_content_ref(
        $content_ref
    ) );
}

sub set_sign_on_response {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'sign_on_response', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::set_sign_on_response, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Connection_CDDBP}{sign_on_response} = $val;
}

sub update {
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::update, THIS METHOD IS NOT YET IMPLEMENTED.");
}

sub write {
    my $self = shift;
    my $entry = shift;
    my $cat = shift;

    # Throw exception if no cat
    ( $cat ) ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::write, no category specified.");

    # Get the discid
    my $res = $self->discid($entry);

    # Throw exception if error
    $res->get_code() == 200 ||
        throw Error::Simple('ERROR: InfoSys::FreeDB::Connection::CDDBP::write, ' . $res->get_result() . '.');

    # Send command and wait for reply
    my $cmd = "cddb write $cat " . $res->get_discid();
    my $content_ref = $self->_wait_command_reply($cmd, {
        320 => $FINAL_EOL_RX,
        401 => $FINAL_EOL_RX,
        402 => $FINAL_EOL_RX,
        409 => $FINAL_EOL_RX,
        501 => $FINAL_EOL_RX,
    } );

    # Parse the result
    require InfoSys::FreeDB::Response::Write::1;
    my $pass1 = InfoSys::FreeDB::Response::Write::1->new_from_content_ref(
        $content_ref
    );

    # Return result if error
    $pass1->is_error() &&
        return($pass1);

    # Send entry and wait for reply
    $content_ref = $self->_wait_write_reply(
        $entry->write_array_ref(),
        {
            200 => $FINAL_EOL_RX,
            401 => $FINAL_EOL_RX,
        }
    );

    # Parse the result and return it
    require InfoSys::FreeDB::Response::Write::2;
    return( InfoSys::FreeDB::Response::Write::2->new_from_content_ref(
        $content_ref
    ) );
}

