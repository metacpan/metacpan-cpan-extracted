use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::SignOn";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB sign-on response',
        abstract => 'FreeDB sign-on response',
        synopsis => <<'EOF',
This class is used internally by the C<InfoSys::FreeDB::Connection::CDDBP> class.
EOF
        description => <<EOF,
C<${pkg}> contains information about FreeDB sign-on responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'connection_allowed',
             type => 'BOOLEAN',
             short_description => 'connecting is allowed',
             default_value => 1,
        },
        {
             method_factory_name => 'date',
             short_description => 'the current date and time',
        },
        {
             method_factory_name => 'hostname',
             short_description => 'the server host name',
        },
        {
             method_factory_name => 'read_allowed',
             type => 'BOOLEAN',
             short_description => 'reading is allowed',
             default_value => 1,
        },
        {
             method_factory_name => 'version',
             short_description => 'the version number of server software',
        },
        {
             method_factory_name => 'write_allowed',
             type => 'BOOLEAN',
             short_description => 'writing is allowed',
             default_value => 1,
        },
    ],
    constr_opt => [
        {
            method_name => 'new_from_content_ref',
            parameter_description => 'CONTENT_REF',
            description => <<EOF,
Creates a new C<$pkg> object from the specified content reference. C<CONTENT_REF> is a string reference. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
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
EOF
        },
    ],
    meth_opt => [
    ],
    use_opt => [
        {
            dependency_name => 'InfoSys::FreeDB::Response',
            import_list => [ 'qw(:line_parse)' ],
        },
    ],
    sym_opt => [
    ],
} );
