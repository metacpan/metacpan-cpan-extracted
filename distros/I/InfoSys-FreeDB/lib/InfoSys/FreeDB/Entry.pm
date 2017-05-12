package InfoSys::FreeDB::Entry;

use 5.006;
use strict;
use warnings;
use AutoLoader qw(AUTOLOAD);
use Error qw(:try);
use IO::File;

our $CDPARA_TOTAL_RX = '^\s*TOTAL\s+(\d+)';

our $CDPARA_TRACK_RX = '^\s*(\d+)\.\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]\s*(\d+)\s*\[\d+[:.]\d+[:.]\d+\]';

our $DGENRE_RX = '^\s*DGENRE\s*=(.*)$';

our $DID_ERR = 'DISCID=<disc ID>';

our $DID_RX = '^\s*DISCID\s*=\s*(\S+)\s*$';

our $DL_ERR = '# Disc length: <length> seconds';

our $DL_RX = '^\s*#\s*Disc\s+length\s*:\s*(\d+)';

our $DTITLE_RX = '^\s*DTITLE\s*=(.*)$';

our $DYEAR_RX = '^\s*DYEAR\s*=(.*)$';

our $EXTD_RX = '^\s*EXTD\s*=(.*)$';

our $EXTTN_RX = '^\s*EXTT(\d+)\s*=(.*)$';

our $FO_ERR = '# <number>';

our $FO_RX = '^\s*#\s*(\d+)\s*$';

our $REV_ERR = '# Revision: <revision>';

our $REV_RX = '^\s*#\s*Revision\s*:\s*(\d+)\s*';

our $SUB_ERR = '# Submitted via: <client_name> <client_version> <optional_comments>';

our $SUB_RX = '^\s*#\s*Submitted\s+via\s*:\s*(\S+)\s+(\S+)\s*(.*)\s*$';

our $TFO_ERR = '# Track frame offsets:';

our $TFO_RX = '^\s*#\s*Track\s+frame\s+offsets\s*:\s*$';

our $TTITLEN_RX = '^\s*TTITLE(\d+)\s*=(.*)$';

our $XMCD_ERR = '# xmcd';

our $XMCD_RX = '^\s*#\s*xmcd';

# Used by _value_is_allowed
our %ALLOW_ISA = (
    'track' => [ 'InfoSys::FreeDB::Entry::Track' ],
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

InfoSys::FreeDB::Entry - FreeDB entry

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

FreeDB entry

=head1 DESCRIPTION

C<InfoSys::FreeDB::Entry> contains information on FreeDB entries.

=head1 CONSTRUCTOR

=over

=item new( [ OPT_HASH_REF ] )

Creates a new C<InfoSys::FreeDB::Entry> object. C<OPT_HASH_REF> is a hash reference used to pass initialization options. On error an exception C<Error::Simple> is thrown.

Options for C<OPT_HASH_REF> may include:

=over

=item B<C<artist>>

Passed to L<set_artist()>.

=item B<C<client_comment>>

Passed to L<set_client_comment()>.

=item B<C<client_name>>

Passed to L<set_client_name()>.

=item B<C<client_version>>

Passed to L<set_client_version()>.

=item B<C<disc_length>>

Passed to L<set_disc_length()>.

=item B<C<discid>>

Passed to L<set_discid()>.

=item B<C<extd>>

Passed to L<set_extd()>.

=item B<C<genre>>

Passed to L<set_genre()>.

=item B<C<revision>>

Passed to L<set_revision()>.

=item B<C<title>>

Passed to L<set_title()>.

=item B<C<track>>

Passed to L<set_track()>. Must be an C<ARRAY> reference.

=item B<C<year>>

Passed to L<set_year()>.

=back

=item new_from_array_ref(ARRAY_REF)

Creates a new C<InfoSys::FreeDB::Entry> object from the specified array reference. C<ARRAY_REF> is an array reference containing the lines of the entry file. On error an exception C<Error::Simple> is thrown.

=item new_from_cdparanoia([ DEVICE ])

Creates a new C<InfoSys::FreeDB::Entry> object using C<cdparanoia>. If specified, C<DEVICE> is used as CD-Rom device name. Otherwise the default C<cdparanoia> CD-Rom device is used. On error an exception C<Error::Simple> is thrown.

=item new_from_fh(FILE_HANDLE)

Creates a new C<InfoSys::FreeDB::Entry> object from the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=item new_from_fn(FILE)

Creates a new C<InfoSys::FreeDB::Entry> object from the specified file. C<FILE> is a file name. On error an exception C<Error::Simple> is thrown.

=back

=head1 METHODS

=over

=item exists_track(ARRAY)

Returns the count of items in C<ARRAY> that are in the entry track list.

=item get_artist()

Returns the entry artist.

=item get_client_comment()

Returns the entry client comment.

=item get_client_name()

Returns the entry client name.

=item get_client_version()

Returns the entry client version.

=item get_disc_length()

Returns the entry disc length.

=item get_discid()

Returns the entry discid.

=item get_extd()

Returns the entry extd.

=item get_genre()

Returns the entry genre.

=item get_revision()

Returns the entry revision.

=item get_title()

Returns the entry title.

=item get_track( [ INDEX_ARRAY ] )

Returns an C<ARRAY> containing the entry track list. C<INDEX_ARRAY> is an optional list of indexes which when specified causes only the indexed elements in the ordered list to be returned. If not specified, all elements are returned.

=item get_year()

Returns the entry year.

=item mk_discid()

Calculates the FreeDB disc ID and stores it through method C<set_discid()>. Note that in the C<InfoSys::FreeDB::Connection>classes the method C<discid()> lets the FreeDB server calculate the disc ID.

=item pop_track()

Pop and return an element off the entry track list. On error an exception C<Error::Simple> is thrown.

=item push_track(ARRAY)

Push additional values on the entry track list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Entry::Track

=back

=back

=item set_artist(VALUE)

Set the entry artist. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_client_comment(VALUE)

Set the entry client comment. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_client_name(VALUE)

Set the entry client name. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_client_version(VALUE)

Set the entry client version. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_disc_length(VALUE)

Set the entry disc length. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_discid(VALUE)

Set the entry discid. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_extd(VALUE)

Set the entry extd. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_genre(VALUE)

Set the entry genre. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_idx_track( INDEX, VALUE )

Set value in the entry track list. C<INDEX> is the integer index which is greater than or equal to C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Entry::Track

=back

=back

=item set_num_track( NUMBER, VALUE )

Set value in the entry track list. C<NUMBER> is the integer index which is greater than C<0>. C<VALUE> is the value.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Entry::Track

=back

=back

=item set_revision(VALUE)

Set the entry revision. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_title(VALUE)

Set the entry title. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item set_track(ARRAY)

Set the entry track list absolutely. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Entry::Track

=back

=back

=item set_year(VALUE)

Set the entry year. C<VALUE> is the value. On error an exception C<Error::Simple> is thrown.

=item shift_track()

Shift and return an element off the entry track list. On error an exception C<Error::Simple> is thrown.

=item unshift_track(ARRAY)

Unshift additional values on the entry track list. C<ARRAY> is the list value. On error an exception C<Error::Simple> is thrown.

=over

=item The values in C<ARRAY> must be a (sub)class of:

=over

=item InfoSys::FreeDB::Entry::Track

=back

=back

=item write_array_ref()

Writes the entry to an C<ARRAY> and retuens a reference to the C<ARRAY>. On error an exception C<Error::Simple> is thrown.

=item write_fh(FILE_HANDLE)

Writes the entry to the specified file handle. C<FILE_HANDLE> is a C<IO::Handle> object. On error an exception C<Error::Simple> is thrown.

=item write_fn(FILE)

Writes the entry to the specified file. C<FILE> is file name. On error an exception C<Error::Simple> is thrown.

=back

=head1 SEE ALSO

L<InfoSys::FreeDB>,
L<InfoSys::FreeDB::Connection>,
L<InfoSys::FreeDB::Connection::CDDBP>,
L<InfoSys::FreeDB::Connection::HTTP>,
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
Last update: November 2003

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

sub new_from_array_ref {
    my $class = shift;
    my $array_ref = shift;

    # Create an empty object
    my $self = $class->new();

    # Read from the file array reference
    $self->read_array_ref($array_ref);

    # Return $self
    return($self);
}

sub new_from_cdparanoia {
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
}

sub new_from_fh {
    my $class = shift;
    my $fh = shift;

    # Create an empty object
    my $self = $class->new();

    # Read from the file handle
    $self->read_fh($fh);

    # Return $self
    return($self);
}

sub new_from_fn {
    my $class = shift;
    my $file = shift;

    # Open file for reading
    my $fh = IO::File->new( $file, 'r');
    defined($fh) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::new_from_fn, failed to open file '$file' for reading.");

    # Call new_from_fh
    return( $class->new_from_fh( $fh) );
}

sub _initialize {
    my $self = shift;
    my $opt = defined($_[0]) ? shift : {};

    # Check $opt
    ref($opt) eq 'HASH' || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::_initialize, first argument must be 'HASH' reference.");

    # artist, SINGLE
    exists( $opt->{artist} ) && $self->set_artist( $opt->{artist} );

    # client_comment, SINGLE
    exists( $opt->{client_comment} ) && $self->set_client_comment( $opt->{client_comment} );

    # client_name, SINGLE
    exists( $opt->{client_name} ) && $self->set_client_name( $opt->{client_name} );

    # client_version, SINGLE
    exists( $opt->{client_version} ) && $self->set_client_version( $opt->{client_version} );

    # disc_length, SINGLE
    exists( $opt->{disc_length} ) && $self->set_disc_length( $opt->{disc_length} );

    # discid, SINGLE
    exists( $opt->{discid} ) && $self->set_discid( $opt->{discid} );

    # extd, SINGLE
    exists( $opt->{extd} ) && $self->set_extd( $opt->{extd} );

    # genre, SINGLE
    exists( $opt->{genre} ) && $self->set_genre( $opt->{genre} );

    # revision, SINGLE
    exists( $opt->{revision} ) && $self->set_revision( $opt->{revision} );

    # title, SINGLE
    exists( $opt->{title} ) && $self->set_title( $opt->{title} );

    # track, MULTI
    if ( exists( $opt->{track} ) ) {
        ref( $opt->{track} ) eq 'ARRAY' || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::_initialize, specified value for option 'track' must be an 'ARRAY' reference.");
        $self->set_track( @{ $opt->{track} } );
    }
    else {
        $self->set_track();
    }

    # year, SINGLE
    exists( $opt->{year} ) && $self->set_year( $opt->{year} );

    # Return $self
    return($self);
}

sub _digit_sum {
    my $int = int(shift);

    my $sum = 0;
    while ( $int ) {
        $sum += $int % 10;
        $int = int( $int / 10 );
    }
    return($sum);
}

sub _str2db_lines {
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

sub exists_track {
    my $self = shift;

    # Count occurrences
    my $count = 0;
    foreach my $val1 (@_) {
        foreach my $val2 ( @{ $self->{InfoSys_FreeDB_Entry}{track} } ) {
            ( $val1 eq $val2 ) && $count ++;
        }
    }
    return($count);
}

sub get_artist {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{artist} );
}

sub get_client_comment {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{client_comment} );
}

sub get_client_name {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{client_name} );
}

sub get_client_version {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{client_version} );
}

sub get_disc_length {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{disc_length} );
}

sub get_discid {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{discid} );
}

sub get_extd {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{extd} );
}

sub get_genre {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{genre} );
}

sub get_revision {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{revision} );
}

sub get_title {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{title} );
}

sub get_track {
    my $self = shift;

    if ( scalar(@_) ) {
        my @ret = ();
        foreach my $i (@_) {
            push( @ret, $self->{InfoSys_FreeDB_Entry}{track}[ int($i) ] );
        }
        return(@ret);
    }
    else {
        # Return the full list
        return( @{ $self->{InfoSys_FreeDB_Entry}{track} } );
    }
}

sub get_year {
    my $self = shift;

    return( $self->{InfoSys_FreeDB_Entry}{year} );
}

sub mk_discid {
    my $self = shift;

    # Make sum
    my $sum = 0;
    my @track = $self->get_track();
    for ( my $i = 0; $i < scalar( @track ); $i++) {
        $sum += &_digit_sum( $track[$i]->get_offset() / 75 );
    }

    # Make ID out of sum, get_disc_length()-2 and the number of tracks.
    # And call set_discid().
    $self->set_discid( sprintf("%08x",
        ( $sum % 0xff ) << 24 |
        int( $self->get_disc_length() - 2 ) << 8 |
        scalar( @track )
    ) );
}

sub pop_track {
    my $self = shift;

    # Pop an element from the list
    return( pop( @{ $self->{InfoSys_FreeDB_Entry}{track} } ) );
}

sub push_track {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'track', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::push_track, one or more specified value(s) '@_' is/are not allowed.");

    # Push the list
    push( @{ $self->{InfoSys_FreeDB_Entry}{track} }, @_ );
}

sub read_array_ref {
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
        if ( ! defined ($offset) ) {
            unshift( @{$array}, $line );
            last;
        }

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
}

sub read_fh {
    my $self = shift;
    my $fh = shift;

    my @array = ();
    while ( my $line = $fh->getline() ) {
        chomp($line);
        push( @array, $line );
    }
    return( $self->read_array_ref( \@array ) );
}

sub set_artist {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'artist', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_artist, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{artist} = $val;
}

sub set_client_comment {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_comment', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_client_comment, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{client_comment} = $val;
}

sub set_client_name {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_name', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_client_name, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{client_name} = $val;
}

sub set_client_version {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'client_version', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_client_version, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{client_version} = $val;
}

sub set_disc_length {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'disc_length', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_disc_length, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{disc_length} = $val;
}

sub set_discid {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'discid', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_discid, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{discid} = $val;
}

sub set_extd {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'extd', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_extd, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{extd} = $val;
}

sub set_genre {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'genre', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_genre, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{genre} = $val;
}

sub set_idx_track {
    my $self = shift;
    my $idx = shift;
    my $val = shift;

    # Check if index is a positive integer or zero
    ( $idx == int($idx) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_idx_track, the specified index '$idx' is not an integer.");
    ( $idx >= 0 ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_idx_track, the specified index '$idx' is not a positive integer or zero.");

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'track', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_idx_track, one or more specified value(s) '@_' is/are not allowed.");

    # Set the value in the list
    $self->{InfoSys_FreeDB_Entry}{track}[$idx] = $val;
}

sub set_num_track {
    my $self = shift;
    my $num = shift;

    # Check if index is an integer
    ( $num == int($num) ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_num_track, the specified number '$num' is not an integer.");

    # Call set_idx_track
    $self->set_idx_track( $num - 1, @_ );
}

sub set_revision {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'revision', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_revision, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{revision} = $val;
}

sub set_title {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'title', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_title, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{title} = $val;
}

sub set_track {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'track', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_track, one or more specified value(s) '@_' is/are not allowed.");

    # Set the list
    @{ $self->{InfoSys_FreeDB_Entry}{track} } = @_;
}

sub set_year {
    my $self = shift;
    my $val = shift;

    # Check if isa/ref/rx/value is allowed
    &_value_is_allowed( 'year', $val ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::set_year, the specified value '$val' is not allowed.");

    # Assignment
    $self->{InfoSys_FreeDB_Entry}{year} = $val;
}

sub shift_track {
    my $self = shift;

    # Shift an element from the list
    return( shift( @{ $self->{InfoSys_FreeDB_Entry}{track} } ) );
}

sub unshift_track {
    my $self = shift;

    # Check if isas/refs/rxs/values are allowed
    &_value_is_allowed( 'track', @_ ) || throw Error::Simple("ERROR: InfoSys::FreeDB::Entry::unshift_track, one or more specified value(s) '@_' is/are not allowed.");

    # Unshift the list
    unshift( @{ $self->{InfoSys_FreeDB_Entry}{track} }, @_ );
}

sub write_array_ref {
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
}

sub write_fh {
    my $self = shift;
    my $fh = shift;

    foreach my $line ( @{ $self->write_array_ref() } ) {
        $fh->print( "$line\n" );
    }
}

sub write_fn {
    my $self = shift;
    my $fn = shift;


    my $fh = IO::File->new( $fn, 'w' );
    defined($fh) ||
        throw Error::Simple ("ERROR: InfoSys::FreeDB::Entry::write_fn, Failed to open file '$fn' for writing.");
    $self->write_fh($fh);
}

