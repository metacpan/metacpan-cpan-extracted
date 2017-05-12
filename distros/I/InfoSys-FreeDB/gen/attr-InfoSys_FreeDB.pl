use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg = $pkg_base;
my $pkg_connection = "${pkg_base}::Connection";
my $pkg_entry = "${pkg_base}::Entry";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB connection factory',
        abstract => 'FreeDB connection factory',
        synopsis => &::read_synopsis( 'syn-http.pl', '.' ),
        description => <<EOF,
C<${pkg}> is the connection factory of the C<${pkg}> module hierarchy. This class creates connections using the protocols supported by FreeDB*.

\=over

\=item (*)

Currently CDDBP and HTTP protocols are supported.

\=back
EOF
        todo => <<EOF,
\=head2 Implement

\=over

\=item log()

\=item update()

\=back

\=head2 Test

\=over

\=item write()

\=back

\=head2 Analyse

\=over

\=item CDDBP through firewall

\=back
EOF
    },
    attr_opt => [
    ],
    constr_opt => [
    ],
    meth_opt => [
        {
            method_name => 'create_connection',
            parameter_description => 'OPT_HASH_REF',
            description => <<EOF,
Creates a C<${pkg_connection}> object. C<OPT_HASH_REF> is a hash reference used to pass connection creation options. On error an exception C<Error::Simple> is thrown.

\=over

\=item SPEED-UP NOTE

If protocol level C<1> is specified, the C<connect> method tries to use the highest available protocol level. To do so, it queries the FreeDB to find out exaclty which level is supported. On C<CDDBP> connections this doesn't take that long. On C<HTTP> connections it does. To speed up C<HTTP> connections specify a higher C<proto_level> -say C<5>.

\=back

Options for C<OPT_HASH_REF> may include:

\=over

\=item B<C<auto_connected>>

Connect the created object just after instantiation. Defaults to C<1>.

\=item B<C<client_host>>

The hostname of the client. Defaults to C<&Sys::Hostname::hostname()>.

\=item B<C<client_name>>

Mandatory option to name the connecting client software.

\=item B<C<client_user>>

The user name of the client. Defaults to C<scalar( getpwuid(\$E<gt>) )>.

\=item B<C<client_version>>

Mandatory option with the client software version string.

\=item B<C<freedb_cgi>>*

The FreeDB C<cgi> to use. Defaults to C<~cddb/cddb.cgi>.

\=item B<C<freedb_host>>

The FreeDB host. Defaults to C<freedb.freedb.org>.

\=item B<C<freedb_port>>

The port on the FreeDB host. Defaults to C<80> for C<HTTP> and to C<888> for C<CDDBP> connection types.

\=item B<C<protocol>>

The protocol to use. Either C<HTTP> or C<CDDBP>. Defaults to C<HTTP>.

\=item B<C<proto_level>>

The FreeDB protocol level. Defaults to B<1>.

\=item B<C<proxy_host>>**

The proxy host to use.

\=item B<C<proxy_passwd>>**

The proxy password to use.

\=item B<C<proxy_port>>**

The port on the proxy host. Defaults to 8080.

\=item B<C<proxy_user>>**

The proxy user name to use.

\=back

\=over

\=item (*)

Only supported for the HTTP protocol.

\=item (**)

Proxy is only supported for the HTTP protocol.

\=back

EOF
            body => <<'EOF',
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' ||
        throw Error::Simple("ERROR: InfoSys::FreeDB::create_connection, first argument must be 'HASH' reference.");

    # Set default values for $opt
    $opt->{client_host} = &Sys::Hostname::hostname()
        if (! $opt->{client_host} );
    $opt->{client_user} = scalar( getpwuid($>) )
        if (! $opt->{client_user} );
    $opt->{freedb_host} = 'freedb.freedb.org'
        if (! $opt->{freedb_host} );

    # Set default value to protocol
    $opt->{protocol} = 'HTTP' if ( ! $opt->{protocol} );

    # Select the correct connection class
    my $conn = undef;
    if ( $opt->{protocol} eq 'HTTP' ) {
        $opt->{freedb_port} = 80
            if (! $opt->{freedb_port} );
        require InfoSys::FreeDB::Connection::HTTP;
        $conn = InfoSys::FreeDB::Connection::HTTP->new($opt);
    }
    elsif ( $opt->{protocol} eq 'CDDBP' ){
        $opt->{freedb_port} = 888
            if (! $opt->{freedb_port} );
        require InfoSys::FreeDB::Connection::CDDBP;
        $conn = InfoSys::FreeDB::Connection::CDDBP->new($opt);
    }
    else {
        throw Error::Simple("ERROR: InfoSys::FreeDB::create_connection, protocol '$opt->{protocol}' is not supported. Only 'HTTP' and 'CDDBP' are.");
    }

    # Connect if necessary
    $opt->{auto_connected} = 1 if ( !exists( $opt->{auto_connected} ) );
    $opt->{auto_connected} && $conn->connect();

    # Return the connection
    return($conn);
EOF
        },
    ],
    use_opt => [
        {
            dependency_name => 'Sys::Hostname',
        },
    ],
} );
