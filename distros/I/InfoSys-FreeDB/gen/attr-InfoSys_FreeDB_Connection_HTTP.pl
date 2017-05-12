use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_connection = "${pkg_base}::Connection";
my $pkg = "${pkg_connection}::HTTP";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [ $pkg_connection ],
        short_description => 'FreeDB HTTP connection',
        abstract => 'FreeDB HTTP connection',
        synopsis => &::read_synopsis( 'syn-http.pl', '.' ),
        description => <<EOF,
C<${pkg}> is the HTTP implementation of the C<$pkg_connection> abstract class.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'freedb_cgi',
             short_description => 'the FreeDB cgi',
             default_value => '~cddb/cddb.cgi',
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

    return('&hello=' . join('+',
            $self->get_client_user(),
            $self->get_client_host(),
            $self->get_client_name(),
            $self->get_client_version(),
        ) .
        '&proto=' .
        $self->get_proto_level()
    );
EOF
        },
        {
            method_name => '_mk_url_base',
            documented => 0,
            body => <<'EOF',
    my $self = shift;

    my $url = 'http://' .  $self->get_freedb_host();
    $url .= ':' . $self->get_freedb_port() if ($self->get_freedb_port() );
    $url .= '/' . $self->get_freedb_cgi();
    return($url);
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
EOF
        },
        {
            method_name => 'connect',
            description => <<'EOF',
__SUPER_POD__

=over

=item SPEED-UP NOTE

If the C<freedb_host> isn't C<freedb.freedb.org> and protocol level C<1> is specified, the C<connect> method tries to use the highest available protocol level. To do so, it queries the FreeDB to find out exaclty which level is supported. On C<HTTP> connections this takes long. To speed up C<HTTP> connections specify a higher C<proto_level> -say C<5> before C<connect()> is called.

=back
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'hello',
            description => <<EOF,
This method is not supported over C<HTTP>.
EOF
            body => <<'EOF',
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::hello, this method is not supported over 'HTTP'.");
EOF
        },
        {
            method_name => 'proto',
            description => <<EOF,
This method is not supported over C<HTTP>.
EOF
            body => <<'EOF',
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::proto, this method is not supported over 'HTTP'.");
EOF
        },
        {
            method_name => 'quit',
            body => <<'EOF',
    require InfoSys::FreeDB::Response::Quit;
    return( InfoSys::FreeDB::Response::Quit->new( {
        code => 230,
        result => 'OK, goodbye',
        hostname => '<this.is.a.dummy.quit.response>',
    } ) );
EOF
        },
        {
            method_name => 'update',
            description => <<EOF,
THIS METHOD IS NOT YET IMPLEMENTED __SUPER_POD___
EOF
            body => <<'EOF',
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::update, THIS METHOD IS NOT YET IMPLEMENTED.");
EOF
        },
        {
            method_name => 'write',
            description => <<EOF,
This method is not supported over C<HTTP>.
EOF
            body => <<'EOF',
    throw Error::Simple ("ERROR: InfoSys::FreeDB::Connection::HTTP::write, this method is not supported over 'HTTP'.");
EOF
        },
    ],
    use_opt => [
        {
            dependency_name => 'LWP::UserAgent',
        },
    ],
    sym_opt => [
    ],
} );
