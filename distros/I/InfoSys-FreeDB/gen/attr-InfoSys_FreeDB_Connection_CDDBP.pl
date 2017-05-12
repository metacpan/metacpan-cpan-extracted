use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_connection = "${pkg_base}::Connection";
my $pkg_rsponse_signon = "${pkg_base}::Response::SignOn";
my $pkg = "${pkg_connection}::CDDBP";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [ $pkg_connection ],
        short_description => 'FreeDB CDDBP connection',
        abstract => 'FreeDB CDDBP connection',
        synopsis => &::read_synopsis( 'syn-cddbp.pl', '.' ),
        description => <<EOF,
C<${pkg}> is the CDDBP implementation of the C<$pkg_connection> abstract class.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'sign_on_response',
             short_description => 'the sign-on response',
             allow_isa => [ $pkg_rsponse_signon ],
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
        {
            method_name => '_mk_hello',
            documented => 0,
            body => <<'EOF',
    my $self = shift;

    return('hello ' . join(' ',
        $self->get_client_user(),
        $self->get_client_host(),
        $self->get_client_name(),
        $self->get_client_version(),
    ) );
EOF
        },
        {
            method_name => '_wait_command_reply',
            documented => 0,
            body => <<'EOF',
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
EOF
        },
        {
            method_name => '_wait_write_reply',
            documented => 0,
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'connect',
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'disconnect',
            body => <<'EOF',
    my $self = shift;

    # Call quit
    return( $self->quit() );
EOF
        },
        {
            method_name => 'hello',
            description => <<EOF,
Sends a hello command to the FreeDB server. Returns a C<InfoSys::FreeDB::Response::Hello> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'proto',
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'quit',
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'update',
            description => <<EOF,
THIS METHOD IS NOT YET IMPLEMENTED __SUPER_POD___
EOF
            body => <<'EOF',
    throw Error::Simple("ERROR: InfoSys::FreeDB::Connection::CDDBP::update, THIS METHOD IS NOT YET IMPLEMENTED.");
EOF
        },
        {
            method_name => 'write',
            description => <<EOF,
THIS METHOD IS NOT YET TESTED __SUPER_POD___
EOF
            body => <<'EOF',
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
EOF
        },
    ],
    use_opt => [
        {
            dependency_name => 'IO::Socket::INET',
        },
        {
            dependency_name => 'InfoSys::FreeDB::Connection',
            import_list => [ 'qw(:line_parse)' ],
        },
    ],
    sym_opt => [
    ],
} );
