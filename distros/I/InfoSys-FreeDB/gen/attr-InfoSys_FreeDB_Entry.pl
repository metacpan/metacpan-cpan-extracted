use strict;

my $pkg_top = 'InfoSys';
my $pkg_base = "${pkg_top}::FreeDB";
my $pkg = "${pkg_base}::Entry";
my $pkg_entry_track = "${pkg}::Track";

push (@::bean_desc, {
    bean_opt => {
        package => $pkg,
        short_description => 'FreeDB entry',
        abstract => 'FreeDB entry',
        synopsis => &::read_synopsis( 'syn-http.pl', '.' ),
        description => <<EOF,
C<${pkg}> contains information on FreeDB entries.
EOF
    },
    attr_opt => [
        {
             method_factory_name => 'title',
             short_description => 'the entry title',
        },
        {
             method_factory_name => 'client_name',
             short_description => 'the entry client name',
        },
        {
             method_factory_name => 'client_version',
             short_description => 'the entry client version',
        },
        {
             method_factory_name => 'client_comment',
             short_description => 'the entry client comment',
        },
        {
             method_factory_name => 'artist',
             short_description => 'the entry artist',
        },
        {
             method_factory_name => 'disc_length',
             short_description => 'the entry disc length',
        },
        {
             method_factory_name => 'revision',
             short_description => 'the entry revision',
        },
        {
             method_factory_name => 'discid',
             short_description => 'the entry discid',
        },
        {
             method_factory_name => 'year',
             short_description => 'the entry year',
        },
        {
             method_factory_name => 'genre',
             short_description => 'the entry genre',
        },
        {
             method_factory_name => 'extd',
             short_description => 'the entry extd',
        },
        {
             method_factory_name => 'track',
             type => 'MULTI',
             ordered => 1,
             allow_isa => [ $pkg_entry_track ],
             short_description => 'the entry track list',
        },
    ],
    constr_opt => [
        {
            method_name => 'new_from_array_ref',
            parameter_description => 'ARRAY_REF',
            description => <<EOF,
Creates a new C<$pkg> object from the specified array reference. C<ARRAY_REF> is an array reference containing the lines of the entry file. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $class = shift;
    my $array_ref = shift;

    # Create an empty object
    my $self = $class->new();

    # Read from the file array reference
    $self->read_array_ref($array_ref);

    # Return $self
    return($self);
EOF
        },
        {
            method_name => 'new_from_cdparanoia',
            parameter_description => '[ DEVICE ]',
            description => <<EOF,
Creates a new C<$pkg> object using C<cdparanoia>. If specified, C<DEVICE> is used as CD-Rom device name. Otherwise the default C<cdparanoia> CD-Rom device is used. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $class = shift;
    my $dev = shift;

    # Setup the cdparanoia command
    my $cmd = 'cdparanoia -Q';
    $cmd .= " -d '$dev'" if ($dev);

    # Run the cdparanoia command
    use IO::File;
    my $fh = IO::File->new ("$cmd 2>&1 |");
    defined ($fh) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::new_from_cdparanoia, Failed to open pipe from command '$cmd'.");

    # Create an empty object
    my $self = $class->new();

    # Parse cdparanoia's output
    my $frame_offset = 150;
    while ( my $line = $fh->getline() ) {
        my ($track, $frame_length, $frame_begin) = $line =~ /$CDPARA_TRACK_RX/;

        if ( defined($track) ) {
            require InfoSys::FreeDB::Entry::Track;
            $self->push_track( InfoSys::FreeDB::Entry::Track->new( {
                offset => $frame_offset,
            } ) );
            $frame_offset += $frame_length;
            next;
        }

        my ($frame_total) = $line =~ /$CDPARA_TOTAL_RX/;
        if ( defined($frame_total) ) {
            $self->set_disc_length( int($frame_total / 75) + 2);
            last;
        }
    }

    # Check if anything is read
    ($frame_offset == 150) &&
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::new_from_cdparanoia, Command '$cmd' did not produce any usable output.");

    # Return $self
    return($self);
EOF
        },
        {
            method_name => 'new_from_fn',
            parameter_description => 'FILE',
            description => <<EOF,
Creates a new C<$pkg> object from the specified file. C<FILE> is a file name. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $class = shift;
    my $file = shift;

    # Open file for reading
    my $fh = IO::File->new( $file, 'r');
    defined($fh) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::new_from_fn, failed to open file '$file' for reading.");

    # Call new_from_fh
    return( $class->new_from_fh( $fh) );
EOF
        },
        {
            method_name => 'new_from_fh',
            parameter_description => 'FILE_HANDLE',
            description => <<EOF,
Creates a new C<$pkg> object from the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $class = shift;
    my $fh = shift;

    # Create an empty object
    my $self = $class->new();

    # Read from the file handle
    $self->read_fh($fh);

    # Return $self
    return($self);
EOF
        },
    ],
    meth_opt => [
        {
            method_name => '_digit_sum',
            documented => 0,
            body => <<'EOF',
    my $int = int(shift);

    my $sum = 0;
    while ( $int ) {
        $sum += $int % 10;
        $int = int( $int / 10 );
    }
    return($sum);
EOF
        },
        {
            method_name => '_str2db_lines',
            documented => 0,
            description => <<EOF,
EOF
            body => <<'EOF',
    my $pre = shift;
    my $str = shift || '';

    $str =~ s/\n/\\n/gm;
    my @array = ();
    my $first = 1;
    while ($first || $str) {
        push( @array, $pre . substr($str, 0, 80 - 1 - length($pre), '') );
        $first = 0;
    }
    return(@array);
EOF
        },
        {
            method_name => 'mk_discid',
            description => <<EOF,
Calculates the FreeDB disc ID and stores it through method C<set_discid()>. Note that in the C<InfoSys::FreeDB::Connection>classes the method C<discid()> lets the FreeDB server calculate the disc ID.
EOF
            body => <<'EOF',
    my $self = shift;

    # Make sum
    my $sum = 0;
    my @track = $self->get_track();
    for ( my $i = 0; $i < scalar( @track ); $i++) {
        $sum += &_digit_sum( $track[$i]->get_offset() / 75 );
    }

    # Make ID out of sum, get_disc_length()-2 and the number of tracks.
    # And call set_discid().
    $self->set_discid( sprintf("%8x",
        ( $sum % 0xff ) << 24 |
        int( $self->get_disc_length() - 2 ) << 8 |
        scalar( @track )
    ) );
EOF
        },
        {
            method_name => 'read_array_ref',
            documented => 0,
            description => <<EOF,
EOF
            body => <<'EOF',
    my $self = shift;
    my $array = shift;

    # From http://www.freedb.org/src/latest/DBFORMAT :
    # The beginning of the first line in a database entry should consist of
    # the string "# xmcd". This string identifies the file as an xmcd format
    # CD database file. More text can appear after the "xmcd", but is
    # unnecessary.
    my $line = shift( @{$array} );
    my $line_nr = 1;
    $line =~ /$XMCD_RX/ ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$XMCD_ERR' in line " . $line_nr . ' but encountered: ' . $line);

    # Tolerate '#.*' until '# Track frame offsets:'
    while ( $line = shift( @{$array} ) ) {
        $line_nr++;
        $line =~ /$TFO_RX/ && last;
        $line =~ /^\s*#/ && next;
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$TFO_ERR' in line " . $line_nr . ' but encountered: ' . $line);
    }

    # Delete all tracks
    $self->set_track();

    # Read frame offsets
    my $track = 0;
    while ( $line = shift( @{$array} ) ) {
        $line_nr++;
        # Read the offset
        my ($offset) = $line =~ /$FO_RX/;
        defined ($offset) || last;

        # Put the offset in the correct track object
        $track++;
        require InfoSys::FreeDB::Entry::Track;
        $self->push_track( InfoSys::FreeDB::Entry::Track->new( {
            offset => $offset,
        } ) );
    }
    $track ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$FO_ERR' in line " . $line_nr . ' but encountered: ' . $line);

    # Read '# Disc length', '"# Revision', "# Submitted via' until 'DID'
    while ( $line = shift( @{$array} ) ) {
        $line_nr++;
        my ($len) = $line =~ /$DL_RX/i;
        if ( defined($len) ) {
            $self->set_disc_length($len);
            next;
        }
        my ($rev) = $line =~ /$REV_RX/i;
        if ( defined($rev) ) {
            $self->set_revision($rev);
            next;
        }
        my ($name, $vers, $comm) = $line =~ /$SUB_RX/i;
        if (defined ($name)) {
            $self->set_client_name($name);
            $self->set_client_version($vers);
            $self->set_client_comment($comm);
            next;
        }
        my ($discid) = $line =~ /$DID_RX/i;
        if (defined ($discid)) {
            $self->set_discid($discid);
            last;
        }
        ($line =~ /^\s*#/) && next;
        last;
    }
    $self->get_disc_length() ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$DL_ERR' in line " . $line_nr . ' but encountered: ' . $line);
    defined ( $self->get_revision() ) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$REV_ERR' in line " . $line_nr . ' but encountered: ' . $line);
    $self->get_client_name() ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$SUB_ERR' in line " . $line_nr . ' but encountered: ' . $line);
    $self->get_discid() ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, Expected '$DID_ERR' in line " . $line_nr . ' but encountered: ' . $line);

    # Read DTITLE, DYEAR, DGENRE, TTITLEN, EXTD, EXTTN
    # Indeed, this code is a bit forgiving
    my $DTITLE = '';
    my $DYEAR = '';
    my $DGENRE = '';
    my @TTITLEN = '';
    my $EXTD = '';
    my @EXTTN = '';
    while ( $line = shift( @{$array} ) ) {
        $line_nr++;
        my $str;
        ($str) = $line =~ /$DTITLE_RX/;
        if ( defined($str) ) {
            $DTITLE .= $str;
            next;
        }
        ($str) = $line =~ /$DYEAR_RX/;
        if ( defined($str) ) {
            $DYEAR .= $str;
            next;
        }
        ($str) = $line =~ /$DGENRE_RX/;
        if ( defined($str) ) {
            $DGENRE .= $str;
            next;
        }
        my $nr;
        ($nr, $str) = $line =~ /$TTITLEN_RX/;
        if ( defined($nr) ) {
            $TTITLEN[$nr] .= $str;
            next;
        }
        ($str) = $line =~ /$EXTD_RX/;
        if ( defined($str) ) {
            $EXTD .= $str;
            next;
        }
        ($nr, $str) = $line =~ /$EXTTN_RX/;
        if ( defined($nr) ) {
            $EXTTN[$nr] .= $str;
            next;
        }
    }
    # Set artist and title
    my ($artist, $title) = split( /\s*\/\s*/, $DTITLE, 2 );
    $title = '' if (!$title);
    $artist =~ s/\\n/\n/gm;
    $title =~ s/\\n/\n/gm;
    $self->set_artist($artist);
    $self->set_title($title);

    # DYEAR
    $DYEAR =~ s/\\n/\n/gm;
    $self->set_year($DYEAR);

    # DGENRE
    $DGENRE =~ s/\\n/\n/gm;
    $self->set_genre($DGENRE);

    # TTITLEN
    # First check if there are more TTITLE than offset lines
    scalar( @TTITLEN ) > scalar( $self->get_track() ) &&
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, More TTITLEN than frame offset lines.");
    foreach my $track ( $self->get_track() ) {
        $track->set_title( shift(@TTITLEN) || '' );
    }

    # EXTD
    $EXTD =~ s/\\n/\n/gm;
    $self->set_extd($EXTD);

    # EXTTN
    # First check if there are more EXTTN than offset lines
    scalar( @EXTTN ) > scalar( $self->get_track() ) &&
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::read, More EXTTN than frame offset lines.");
    foreach my $track ( $self->get_track() ) {
        $track->set_extt( shift(@EXTTN) || '' );
    }
EOF
        },
        {
            method_name => 'read_fh',
            documented => 0,
            description => <<EOF,
EOF
            body => <<'EOF',
    my $self = shift;
    my $fh = shift;

    my @array = ();
    while ( my $line = $fh->getline() ) {
        chomp($line);
        push( @array, $line );
    }
    return( $self->read_array_ref( \@array ) );
EOF
        },
        {
            method_name => 'write_array_ref',
            description => <<EOF,
Writes the entry to an C<ARRAY> and retuens a reference to the C<ARRAY>. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $self = shift;

    # Make an empty array
    my @array = ();

    # xmcd
    push(@array, "# xmcd");
    push(@array, "#");

    # Make maximum tracks
    my $max = scalar( $self->get_track() );

    # Track frame offsets:
    push(@array, "# Track frame offsets:");
    foreach my $track ( $self->get_track() ) {
        push( @array, "#\t" . $track->get_offset() );
    }
    push(@array, "#");

    # Disc length: N seconds
    push(@array, "# Disc length: " . $self->get_disc_length() . " seconds");
    push(@array, "#");

    # Revision: N
    push (@array, "# Revision: " . ( $self->get_revision() || '0') );
    push (@array, "#");

    # Submitted via: client_name client_version optional_comments
    my $str = ($self->get_client_name() || 'none') . ' ';
    $str .= ($self->get_client_version() || '0');
    $str .= ' ' . $self->get_client_comment() if ( $self->get_client_comment() );
    push( @array, sprintf ("%.79s", "# Submitted via: " . $str) );
    push(@array, "#");

    # DISCID
    $self->get_discid() ||
        $self->mk_discid();
    push( @array, "DISCID=" . ( $self->get_discid() ) );

    # DTITLE (Artist / Title)
    push( @array, &_str2db_lines( 'DTITLE=',
        ($self->get_artist() || '') . ' / ' . ($self->get_title() || '') ) );

    # DYEAR
    push( @array, &_str2db_lines( 'DYEAR=', $self->get_year() ) );

    # DGENRE
    push( @array, &_str2db_lines( 'DGENRE=', $self->get_genre() ) );

    # TTITLEN
    my $i = 0;
    foreach my $track ( $self->get_track() ) {
        if ( defined($track) ) {
            push( @array,
                &_str2db_lines( "TTITLE$i=",  $track->get_title() || '' ) );
        }
        else {
            push( @array, &_str2db_lines( "TTITLE$i=",  '' ) );
        }
        $i++;
    }

    # EXTD
    push( @array, &_str2db_lines( 'EXTD=', $self->get_extd() ) );

    # EXTTN
    $i = 0;
    foreach my $track ( $self->get_track() ) {
        if ( defined($track) ) {
            push( @array,
                &_str2db_lines( "EXTT$i=",  $track->get_extt() || '' ) );
        }
        else {
            push( @array, &_str2db_lines( "EXTT$i=",  '' ) );
        }
        $i++;
    }

    # PLAYORDER
    push(@array, "PLAYORDER=");

    # Return array reference
    return( \@array );
EOF
        },
        {
            method_name => 'write_fh',
            parameter_description => 'FILE_HANDLE',
            description => <<EOF,
Writes the entry to the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $self = shift;
    my $fh = shift;

    foreach my $line ( @{ $self->write_array_ref() } ) {
        $fh->print( "$line\n" );
    }
EOF
        },
        {
            method_name => 'write_fn',
            parameter_description => 'FILE',
            description => <<EOF,
Writes the entry to the specified file. C<FILE> is file name. On error an exception C<Error::Simple> is thrown.
EOF
            body => <<'EOF',
    my $self = shift;
    my $fn = shift;


    my $fh = IO::File->new( $fn, 'w' );
    defined($fh) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::write_fn, Failed to open file '$fn' for writing.");
    $self->write_fh($fh);
EOF
        },
    ],
    use_opt => [
        {
            dependency_name => 'IO::File',
        },
    ],
    sym_opt => [
        {
            symbol_name => '$CDPARA_TOTAL_RX',
            assignment => <<'EOF',
'^\s*TOTAL\s+(\d+)';
EOF
        },
        {
            symbol_name => '$CDPARA_TRACK_RX',
            assignment => <<'EOF',
'^\s*(\d+)\.\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]';
EOF
        },
        {
            symbol_name => '$DGENRE_RX',
            assignment => <<'EOF',
'^\s*DGENRE\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$DID_ERR',
            assignment => <<'EOF',
'DISCID=<disc ID>';
EOF
        },
        {
            symbol_name => '$DID_RX',
            assignment => <<'EOF',
'^\s*DISCID\s*=\s*(\S+)\s*$';
EOF
        },
        {
            symbol_name => '$DL_ERR',
            assignment => <<'EOF',
'# Disc length: <length> seconds';
EOF
        },
        {
            symbol_name => '$DL_RX',
            assignment => <<'EOF',
'^\s*#\s*Disc\s+length\s*:\s*(\d+)\s+sec[ond]{0,3}s\s*$';
EOF
        },
        {
            symbol_name => '$DTITLE_RX',
            assignment => <<'EOF',
'^\s*DTITLE\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$DYEAR_RX',
            assignment => <<'EOF',
'^\s*DYEAR\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$EXTTN_RX',
            assignment => <<'EOF',
'^\s*EXTT(\d+)\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$EXTD_RX',
            assignment => <<'EOF',
'^\s*EXTD\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$FO_ERR',
            assignment => <<'EOF',
'# <number>';
EOF
        },
        {
            symbol_name => '$FO_RX',
            assignment => <<'EOF',
'^\s*#\s*(\d+)\s*$';
EOF
        },
        {
            symbol_name => '$REV_ERR',
            assignment => <<'EOF',
'# Revision: <revision>';
EOF
        },
        {
            symbol_name => '$REV_RX',
            assignment => <<'EOF',
'^\s*#\s*Revision\s*:\s*(\d+)\s*';
EOF
        },
        {
            symbol_name => '$SUB_ERR',
            assignment => <<'EOF',
'# Submitted via: <client_name> <client_version> <optional_comments>';
EOF
        },
        {
            symbol_name => '$SUB_RX',
            assignment => <<'EOF',
'^\s*#\s*Submitted\s+via\s*:\s*(\S+)\s+(\S+)\s*(.*)\s*$';
EOF
        },
        {
            symbol_name => '$TTITLEN_RX',
            assignment => <<'EOF',
'^\s*TTITLE(\d+)\s*=(.*)$';
EOF
        },
        {
            symbol_name => '$TFO_RX',
            assignment => <<'EOF',
'^\s*#\s*Track\s+frame\s+offsets\s*:\s*$';
EOF
        },
        {
            symbol_name => '$TFO_ERR',
            assignment => <<'EOF',
'# Track frame offsets:';
EOF
        },
        {
            symbol_name => '$XMCD_ERR',
            assignment => <<'EOF',
'# xmcd';
EOF
        },
        {
            symbol_name => '$XMCD_RX',
            assignment => <<'EOF',
'^\s*#\s*xmcd';
EOF
        },
    ],
} );
