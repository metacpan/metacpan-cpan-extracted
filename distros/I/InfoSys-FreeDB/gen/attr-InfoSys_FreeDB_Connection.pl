use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_entry = "${pkg_base}::Entry";
my $pkg_match = "${pkg_base}::Match";
my $pkg_response = "${pkg_base}::Response";
my $pkg_response_match = "${pkg_response}::Match";
my $pkg_response_lscat = "${pkg_response}::LsCat";
my $pkg_response_motd = "${pkg_response}::Motd";
my $pkg_response_proto = "${pkg_response}::Proto";
my $pkg_response_quit = "${pkg_response}::Quit";
my $pkg_response_query = "${pkg_response}::Query";
my $pkg_response_sites = "${pkg_response}::Sites";
my $pkg_response_stat = "${pkg_response}::Stat";
my $pkg_response_ver = "${pkg_response}::Ver";
my $pkg_response_whom = "${pkg_response}::Whom";
my $pkg_response_write_1 = "${pkg_response}::Write::1";
my $pkg_response_write_2 = "${pkg_response}::Write::2";
my $pkg = "${pkg_base}::Connection";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB abstract connection',
        abstract => 'FreeDB abstract connection',
        synopsis => <<'EOF',
None. This is an abstract class.
EOF
        description => <<EOF,
C<${pkg}> is the abstract connection class of the C<${pkg_base}> module hierarchy.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'client_name',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the connecting client name',
        },
        {
             method_factory_name => 'client_version',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the connecting client version',
        },
        {
             method_factory_name => 'client_host',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the connecting client host',
        },
        {
             method_factory_name => 'client_user',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the connecting client user',
        },
        {
             method_factory_name => 'freedb_host',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the FreeDB host',
        },
        {
             method_factory_name => 'freedb_port',
             mandatory => 1,
             allow_empty => 0,
             short_description => 'the FreeDB port',
        },
        {
             method_factory_name => 'proto_level',
             short_description => 'the current protocol level',
             default_value => 1,
        },
        {
             method_factory_name => 'proxy_host',
             short_description => 'the proxy host to use',
        },
        {
             method_factory_name => 'proxy_passwd',
             short_description => 'the proxy password to use',
        },
        {
             method_factory_name => 'proxy_port',
             default_value => 8080,
             short_description => 'the proxy port to use',
        },
        {
             method_factory_name => 'proxy_user',
             short_description => 'the proxy user name to use',
        },
        {
             method_factory_name => '_connection_',
             documented => 0,
        },
    ],
    constr_opt => [
    ],
    meth_opt => [
        {
            method_name => '_wait_command_reply',
            documented => 0,
            interface => 1,
        },
        {
            method_name => 'connect',
            interface => 1,
            description => <<EOF,
Connects the object to the FreeDB information service using the object's attributes. A C<hello> commend is sent out, the protocol level is queried and set to the highest level available. On error an exception C<Error::Simple> is thrown.
EOF
        },
        {
            method_name => 'disconnect',
            description => <<EOF,
Disconnects the object from the FreeDB information service.
EOF
            body => <<'EOF',
    my $self = shift;

    # Call quit
    return( $self->quit() );
EOF
        },
        {
            method_name => 'discid',
            parameter_description => 'ENTRY',
            description => <<EOF,
Issues a C<discid> command on the FreeDB database. C<ENTRY> is a C<$pkg_entry> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'log',
            interface => 1,
            description => <<EOF,
Issues a C<log> command on the FreeDB database. TO BE SPECIFIED
EOF
        },
        {
            method_name => 'lscat',
            description => <<EOF,
Issues an C<lscat> command on the FreeDB database. Returns a C<$pkg_response_lscat> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'motd',
            description => <<EOF,
Issues an C<motd> command on the FreeDB database. Returns C<$pkg_response_motd> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'proto',
            parameter_description => '[ LEVEL ]',
            interface => 1,
            description => <<EOF,
Issues a C<proto> command on the FreeDB database. If C<LEVEL> is not specified, the protocol level is queried. If C<LEVEL> is specified it is used to set the protocol level. Returns C<$pkg_response_proto> object. On error an exception C<Error::Simple> is thrown.
EOF
        },
        {
            method_name => 'query',
            parameter_description => 'ENTRY',
            description => <<EOF,
Queries the FreeDB database. C<ENTRY> is a C<$pkg_entry> object. Returns a C<$pkg_response_query> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'quit',
            interface => 1,
            description => <<EOF,
Issues a C<quit> command on the FreeDB database and disconnects. Returns C<$pkg_response_quit> object. On error an exception C<Error::Simple> is thrown.
EOF
        },
        {
            method_name => 'read',
            parameter_description => 'MATCH',
            description => <<EOF,
Reads an entry from the FreeDB database. C<MATCH> is a C<$pkg_match> object. Returns a C<$pkg_response_match> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'sites',
            description => <<EOF,
Issues a C<sites> command on the FreeDB database. Returns a C<$pkg_response_sites> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'stat',
            description => <<EOF,
Issues a C<stat> command on the FreeDB database. Returns a C<$pkg_response_stat> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'update',
            interface => 1,
            description => <<EOF,
Issues a C<update> command on the FreeDB database. TO BE SPECIFIED
EOF
        },
        {
            method_name => 'ver',
            description => <<EOF,
Issues a C<ver> command on the FreeDB database. Returns a C<$pkg_response_ver> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'whom',
            description => <<EOF,
Issues a C<whom> command on the FreeDB database. Returns a C<$pkg_response_whom> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
        {
            method_name => 'write',
            parameter_description => 'ENTRY, CATEGORY',
            interface => 1,
            description => <<EOF,
Writes an entry to the FreeDB database. C<ENTRY> is a C<$pkg_entry> object. C<CATEGORY> is a valid FreeDB category. Returns a C<$pkg_response_write_1> object in the case an error occurred in the first pass of the writing. Otherwise a C<$pkg_response_write_2> object is returned. On error an exception C<Error::Simple> is thrown.
EOF
        },
    ],
    use_opt => [
    ],
    sym_opt => [
        {
            symbol_name => '$FINAL_DOT_RX',
            export_tag => [ qw( line_parse ) ],
            description => <<EOF,
Regular expression to parse the end of message dot.
EOF
            assignment => <<'EOF',
'[\r\n]\.[\r\n]';
EOF
        },
        {
            symbol_name => '$FINAL_EOL_RX',
            export_tag => [ qw( line_parse ) ],
            description => <<EOF,
Regular expression to parse the end of line.
EOF
            assignment => <<'EOF',
'[\r\n]';
EOF
        },
    ],
    tag_opt => [
        {
            export_tag_name => 'line_parse',
            description => <<EOF,
This tag contains variables useful to parse the messages from C<FreeDB> servers.
EOF
        },
    ],
} );
