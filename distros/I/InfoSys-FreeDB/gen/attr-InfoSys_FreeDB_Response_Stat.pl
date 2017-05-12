use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg_response = "${pkg_base}::Response";
my $pkg = "${pkg_response}::Stat";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        base => [$pkg_response],
        short_description => 'FreeDB stat response',
        abstract => 'FreeDB stat response',
        synopsis => &::read_synopsis( 'syn-http-stat.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information about FreeDB stat responses.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'gets',
             type => 'BOOLEAN',
             short_description => 'the client is allowed to get log information',
        },
        {
             method_factory_name => 'posting',
             type => 'BOOLEAN',
             short_description => 'the client is allowed to post new entries',
        },
        {
             method_factory_name => 'proto_cur',
             short_description => 'the server\'s current operating protocol level',
        },
        {
             method_factory_name => 'proto_max',
             short_description => 'the maximum supported protocol level',
        },
        {
             method_factory_name => 'quotes',
             type => 'BOOLEAN',
             short_description => 'the quoted arguments are enabled',
        },
        {
             method_factory_name => 'strip_ext',
             type => 'BOOLEAN',
             short_description => 'the extended data is stripped by the server before presented to the user',
        },
        {
             method_factory_name => 'updates',
             type => 'BOOLEAN',
             short_description => 'the client is allowed to initiate a database update',
        },
        {
             method_factory_name => 'users_cur',
             short_description => 'the number of users currently connected to the server',
        },
        {
             method_factory_name => 'users_max',
             short_description => 'the number of users that can concurrently connect to the server',
        },
        {
             method_factory_name => 'database_entries',
             short_description => 'the total number of entries in the database',
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
    my ($code) = $line =~ /^\s*(\d{3})\s/;
    defined ($code) ||
        throw Error::Simple ('ERROR: InfoSys::FreeDB::Response::Stat::new_from_content_ref, first line of specified \'content_ref\' does not contain a code.');
    my %opt;
    if ($code == 210) {
        pop(@content_ref);
        %opt = (
            code => $code,
            result => 'Ok',
            message_text => join("\n", @content_ref),
        );

        foreach my $line (@content_ref) {
            my $val;
            if ( ($val) = $line =~ /$STAT_DB_ENTRIES_RX/i ) {
                $opt{database_entries} = $val;
                last;
            }
            elsif ( ($val) = $line =~ /$STAT_GETS_RX/i ) {
                $opt{gets} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_POSTING_RX/i ) {
                $opt{posting} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_PROTO_CUR_RX/i ) {
                $opt{proto_cur} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_PROTO_MAX_RX/i ) {
                $opt{proto_max} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_QUOTES_RX/i ) {
                $opt{quotes} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_STRIP_EXT/i ) {
                $opt{strip_ext} = $val =~ /yes/i;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_USERS_CUR_RX/i ) {
                $opt{users_cur} = $val;
                next;
            }
            elsif ( ($val) = $line =~ /$STAT_USERS_MAX_RX/i ) {
                $opt{users_max} = $val;
                next;
            }
        }
    }
    else {
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Response::Stat::new_from_content_ref, unknown code '$code' returned. Allowed code is 210.");
    }

    # Create a new object and return it
    return( $class->new( \%opt ) );
EOF
        },
    ],
    meth_opt => [
    ],
    use_opt => [
    ],
    sym_opt => [
        {
            symbol_name => '$STAT_DB_ENTRIES_RX',
            assignment => <<'EOF',
'^\s*database\s+entries\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_GETS_RX',
            assignment => <<'EOF',
'^\s*gets\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_POSTING_RX',
            assignment => <<'EOF',
'^\s*posting\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_PROTO_CUR_RX',
            assignment => <<'EOF',
'^\s*current\s+proto\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_PROTO_MAX_RX',
            assignment => <<'EOF',
'^\s*max\s+proto\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_QUOTES_RX',
            assignment => <<'EOF',
'^\s*quotes\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_STRIP_EXT',
            assignment => <<'EOF',
'^\s*strip\s+ext\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_UPDATES_RX',
            assignment => <<'EOF',
'^\s*updates\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_USERS_CUR_RX',
            assignment => <<'EOF',
'^\s*current\s+users\s*:\s*(\S+)';
EOF
        },
        {
            symbol_name => '$STAT_USERS_MAX_RX',
            assignment => <<'EOF',
'^\s*max\s+users\s*:\s*(\S+)';
EOF
        },
    ],
} );
