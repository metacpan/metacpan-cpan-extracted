package File::SAUCE;

=head1 NAME

File::SAUCE - A library to manipulate SAUCE metadata

=head1 SYNOPSIS

    use File::SAUCE;

    # Read the data...
    # file, handle or string
    my $sauce = File::SAUCE->new( file => 'myansi.ans' );

    # Does the file have a SAUCE record?
    print $sauce->has_sauce ? "has SAUCE" : "does not have SAUCE";

    # Print the metadata...
    $sauce->print;

    # Get a value...
    my $title = $sauce->title;

    # Set a value...
    $sauce->title( 'ANSi is 1337' );

    # Get the SAUCE record as a string...
    my $output = $sauce->as_string;

    # Write the data...
    # file, handle or string
    $sauce->write( file => 'myansi.ans' );

    # Clear the in-memory data...
    $sauce->clear;

    # Read the data...
    # file, handle or string
    $sauce->read( file => 'myansi.ans' );

    # Remove the data...
    # file, handle or string
    $sauce->remove( file => 'myansi.ans' );

=head1 DESCRIPTION

SAUCE stands for Standard Architecture for Universal Comment Extentions. It is used as metadata
to describe the file to which it is associated. It's most common use has been with the ANSI and
ASCII "art scene."

A file containing a SAUCE record looks like this:

    +----------------+
    | FILE Data      |
    +----------------+
    | EOF Marker     |
    +----------------+
    | SAUCE Comments |
    +----------------+
    | SAUCE Record   |
    +----------------+

The SAUCE Comments block holds up to 255 comment lines, each 64 characters wide. It looks like this:

    +----------------+------+------+---------+-------------+
    | Field          | Size | Type | Default | set / get   |
    +----------------+------+------+---------+-------------+
    | ID             | 5    | Char | COMNT   | commment_id |
    +----------------+------+------+---------+-------------+
    | Comment Line 1 | 64   | Char |         | comments*   |
    +----------------+------+------+---------+-------------+
    | ...                                                  |
    +----------------+------+------+---------+-------------+
    | Comment Line X | 64   | Char |         | comments    |
    +----------------+------+------+---------+-------------+

* Comments are stored as an array ref

And lastly, the SAUCE Record. It is exactly 128 bytes long:

    +----------------+------+------+---------+-------------+
    | Field          | Size | Type | Default | set / get   |
    +----------------+------+------+---------+-------------+
    | ID             | 5    | Char | SAUCE   | sauce_id    |
    +----------------+------+------+---------+-------------+
    | SAUCE Version  | 2    | Char | 00      | version     |
    +----------------+------+------+---------+-------------+
    | Title          | 35   | Char |         | title       |
    +----------------+------+------+---------+-------------+
    | Author         | 20   | Char |         | author      |
    +----------------+------+------+---------+-------------+
    | Group          | 20   | Char |         | group       |
    +----------------+------+------+---------+-------------+
    | Date           | 8    | Char |         | date        |
    +----------------+------+------+---------+-------------+
    | FileSize       | 4    | Long |         | filesize    |
    +----------------+------+------+---------+-------------+
    | DataType       | 1    | Byte |         | datatype_id |
    +----------------+------+------+---------+-------------+
    | FileType       | 1    | Byte |         | filetype_id |
    +----------------+------+------+---------+-------------+
    | TInfo1         | 2    | Word |         | tinfo1      |
    +----------------+------+------+---------+-------------+
    | TInfo2         | 2    | Word |         | tinfo2      |
    +----------------+------+------+---------+-------------+
    | TInfo3         | 2    | Word |         | tinfo3      |
    +----------------+------+------+---------+-------------+
    | TInfo4         | 2    | Word |         | tinfo4      |
    +----------------+------+------+---------+-------------+
    | Comments       | 1    | Byte |         | comments    |
    +----------------+------+------+---------+-------------+
    | Flags          | 1    | Byte |         | flags_id    |
    +----------------+------+------+---------+-------------+
    | Filler         | 22   | Byte |         | filler      |
    +----------------+------+------+---------+-------------+

For more information see ACiD.org's SAUCE page at http://www.acid.org/info/sauce/sauce.htm

=head1 WARNING

From the SAUCE documenation:

    SAUCE was initially created for supporting only the ANSi
    & RIP screens. Since both ANSi and RIP are in effect
    text-based and have no other form of control but the
    End-Of-File marker, SAUCE should never interfere with the
    workings of a program using either ANSi or RIP. If it does,
    the program is not functionning the way it should. This is
    NOT true for the other types of files however. Adding SAUCE
    to some of the other filetypes supported in the SAUCE
    specifications may have serious consequences on the proper
    functionning of programs using those files, In the worst
    case, they'll simply refuse the file, stating it is invalid.

The author(s) of this software take no resposibility for loss of data!

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=cut

use strict;
use warnings;
use Carp;
use FileHandle;
use IO::String;
use Time::Piece;

use base qw( Class::Accessor );

our $VERSION = '0.25';

# some SAUCE constants
use constant SAUCE_ID      => 'SAUCE';
use constant SAUCE_VERSION => '00';
use constant SAUCE_FILLER  => ' ' x 22;
use constant COMNT_ID      => 'COMNT';

# vars for use with pack() and unpack()
my $sauce_template = 'A5 A2 A35 A20 A20 A8 V C C v v v v C C A22';
my @sauce_fields
    = qw( sauce_id version title author group date filesize datatype_id filetype_id tinfo1 tinfo2 tinfo3 tinfo4 comments flags_id filler );
my $comnt_template = 'A5 A64';
my @comnt_fields   = qw( comment_id comments );
my $date_format    = '%Y%m%d';

__PACKAGE__->mk_accessors( @sauce_fields, $comnt_fields[ 0 ], 'has_sauce' );

# define datatypes and filetypes as per SAUCE specs
my @datatypes
    = qw(None Character Graphics Vector Sound BinaryText XBin Archive Executable);
my $filetypes = {
    None => {
        filetypes => [ qw( Undefined ) ],
        flags     => { 0 => 'None' }
    },
    Character => {
        filetypes =>
            [ qw( ASCII ANSi ANSiMation RIP PCBoard Avatar HTML Source ) ],
        flags => { 0 => 'None', 1 => 'iCE Color' },
        tinfo => [
            ( { tinfo1 => 'Width', tinfo2 => 'Height' } ) x 3,
            { tinfo1 => 'Width', tinfo2 => 'Height', tinfo3 => 'Colors' },
            ( { tinfo1 => 'Width', tinfo2 => 'Height' } ) x 2
        ]
    },
    Graphics => {
        filetypes => [
            qw( GIF PCX LBM/IFF TGA FLI FLC BMP GL DL WPG PNG JPG MPG AVI )
        ],
        flags => { 0 => 'None' },
        tinfo => [
            (   {   tinfo1 => 'Width',
                    tinfo2 => 'Height',
                    tinfo3 => 'Bits Per Pixel'
                }
            ) x 14
        ]
    },
    Vector => {
        filetypes => [ qw( DXF DWG WPG 3DS ) ],
        flags     => { 0 => 'None' }
    },
    Sound => {
        filetypes => [
            qw( MOD 669 STM S3M MTM FAR ULT AMF DMF OKT ROL CMF MIDI SADT VOC WAV SMP8 SMP8S SMP16 SMP16S PATCH8 PATCH16 XM HSC IT )
        ],
        flags => { 0 => 'None' },
        tinfo => [ ( {} ) x 16, ( { tinfo1 => 'Sampling Rate' } ) x 4 ]
    },
    BinaryText => {
        filetypes => [ qw( Undefined ) ],
        flags     => { 0 => 'None', 1 => 'iCE Color' }
    },
    XBin => {
        filetypes => [ qw( Undefined ) ],
        flags     => { 0 => 'None' },
        tinfo     => [ { tinfo1 => 'Width', tinfo2 => 'Height' }, ]
    },
    Archive => {
        filetypes => [ qw( ZIP ARJ LZH ARC TAR ZOO RAR UC2 PAK SQZ ) ],
        flags     => { 0 => 'None' }
    },
    Executable => {
        filetypes => [ qw( Undefined ) ],
        flags     => { 0 => 'None' }
    }
};

=head1 PUBLIC METHODS

=head2 new( [ %OPTIONS ] )

Creates a new File::SAUCE object. All arguments are optional. You can pass one
of two groups of options (as a hash). If you wish to read a SAUCE record from
a source, you can pass a file, handle or string.

    my $sauce = File::SAUCE->new( file   => 'filename.ext' );
    my $sauce = File::SAUCE->new( handle => \*FILEHANDLE );
    my $sauce = File::SAUCE->new( string => $string );

If you want to create a new record with certain metadata values, just pass them
in as a hash.

    my $sauce = File::SAUCE->new(
        author => 'Me',
        title  => 'My Work',
        group  => 'My Group'
    );

=cut

sub new {
    my $class   = shift;
    my $self    = {};
    my %options = @_;

    bless $self, $class;

    $self->clear;

    if (   exists $options{ file }
        or exists $options{ string }
        or exists $options{ handle } )
    {
        $self->read( @_ );
    }
    else {
        $self->set( $_ => $options{ $_ } ) for keys %options;
        $self->date( $options{ date } ) if exists $options{ date };
    }

    return $self;
}

=head2 clear( )

Resets the in-memory SAUCE data to the default information.

=cut

sub clear {
    my $self = shift;
    my $date = localtime;

    # Set empty/default SAUCE and COMMENT values
    $self->set( $_ => '' ) for @sauce_fields[ 2 .. 4 ];
    $self->set( $_ => 0 ) for @sauce_fields[ 6 .. 13, 14 ];
    $self->sauce_id( SAUCE_ID );
    $self->version( SAUCE_VERSION );
    $self->filler( SAUCE_FILLER );
    $self->comment_id( COMNT_ID );
    $self->date( $date );
    $self->comments( [] );
    $self->has_sauce( undef );
}

=head2 read( %OPTIONS )

Tries to read a SAUCE record from a source. Uses the same options as C<new()>.

=cut

sub read {
    my $self    = shift;
    my %options = @_;
    my $file    = $self->_create_io_object( \%options, '<' );

    $self->clear;

    my $buffer;
    my %info;

    if ( ( $file->stat )[ 7 ] < 128 ) {
        $self->has_sauce( 0 );
        return;
    }

    $file->seek( -128, 2 );
    $file->read( $buffer, 128 );

    if ( substr( $buffer, 0, 5 ) ne SAUCE_ID ) {
        $self->has_sauce( 0 );
        return;
    }

    @info{ @sauce_fields } = unpack( $sauce_template, $buffer );

    # because trailing spaces are stripped....
    $info{ filler } = SAUCE_FILLER;

    # Do we have any comments?
    my $comments = $info{ comments };
    delete $info{ comments };

    $self->set( $_ => $info{ $_ } ) for keys %info;
    $self->has_sauce( 1 );

    if ( $comments > 0 ) {
        $file->seek( -128 - 5 - $comments * 64, 2 );
        $file->read( $buffer, 5 + $comments * 64 );

        if ( substr( $buffer, 0, 5 ) eq COMNT_ID ) {
            my $template = $comnt_template
                . ( split( / /, $comnt_template ) )[ 1 ] x ( $comments - 1 );
            my ( $id, @comments ) = unpack( $template, $buffer );
            $self->comment_id( $id );
            $self->comments( \@comments );
        }
    }
}

=head2 write( %OPTIONS )

Writes the in-memory SAUCE data to a destination. Uses the same options as
C<new>. It calls C<remove> before writing the data.

=cut

sub write {
    my $self = shift;

    $self->remove( @_ );

    my %options = @_;
    my $file = $self->_create_io_object( \%options, '>>' );

    $file->seek( 0, 2 );
    $file->print( $self->as_string );

    return ${ $file->string_ref } if ref $file eq 'IO::String';
}

=head2 remove( %OPTIONS )

Removes any SAUCE data from the destination. This module enforces spoon
(ftp://ftp.artpacks.acid.org/pub/artpacks/programs/dos/editors/spn2d161.zip)
compatibility. The following calculation is used to determine how big the file
should be after truncation:

    if( Filesize on disk - Filesize in SAUCE rec - Size of SAUCE rec ( w/ comments ) == 0 or 1 ) {
        truncate to Filesize in SAUCE rec
    }
    else {
        truncate to Filesize on disk - Size of SAUCE rec - 1 (EOF char)
    }

=cut

sub remove {
    my $self      = shift;
    my $sauce     = File::SAUCE->new( @_ );
    my $has_sauce = $sauce->has_sauce;
    my %options   = @_;

    unless ( $has_sauce ) {
        return $options{ string } if exists $options{ string };
        return;
    }

    my $file = $self->_create_io_object( \%options, '>>' );

    # remove SAUCE
    my $sizeondisk = ( $file->stat )[ 7 ];
    my $sizeinrec  = $sauce->filesize;
    my $comments   = scalar @{ $sauce->comments };
    my $saucesize  = 128 + ( $comments ? 5 + $comments * 64 : 0 );
    my $size       = $sizeondisk - $sizeinrec - $saucesize;

# for spoon compatibility
# Size on disk - size in record - SAUCE size (w/ comments) == 0 or 1 --> use size in record
    if ( $size =~ /^0|1$/ ) {
        $file->truncate( $sizeinrec ) or carp "$!";
    }

    # figure it out on our own -- spoon just balks
    else {
        $file->truncate( $sizeondisk - $saucesize - 1 ) or carp "$!";
    }

    return ${ $file->string_ref } if ref $file eq 'IO::String';
}

=head2 as_string( )

Returns the SAUCE record (including EOF char and comments) as a string.

=cut

sub as_string {
    my $self = shift;

    # Fix values incase they've been changed
    $self->sauce_id( SAUCE_ID );
    $self->version( SAUCE_VERSION );
    $self->filler( SAUCE_FILLER );
    $self->comment_id( COMNT_ID );

    # EOF marker...
    my $output = chr( 26 );

    # comments...
    my $comments = scalar @{ $self->comments };
    if ( $comments ) {
        $output .= pack(
            $comnt_template
                . (
                ( split( / /, $comnt_template ) )[ 1 ] x ( $comments - 1 )
                ),
            $self->comment_id,
            @{ $self->comments }
        );
    }

    # SAUCE...
    my @template = split( / /, $sauce_template );
    for ( 0 .. $#sauce_fields ) {
        my $field = $sauce_fields[ $_ ];
        my $value
            = ( $field ne 'comments' ) ? $self->get( $field ) : $comments;
        $output .= pack( $template[ $_ ], $value );
    }

    return $output;
}

=head2 print( )

View the SAUCE structure (including comments) in a "pretty" format.

=cut

sub print {
    my $self      = shift;
    my $width     = 10;
    my $label     = '%' . $width . 's:';
    my $has_sauce = $self->has_sauce;
    my $output;

    if ( $has_sauce == 0 ) {
        print "The file last read did not contain a SAUCE record\n";
        return;
    }

    for ( @sauce_fields ) {
        if ( /^(datatype|filetype|flags)_id$/ ) {
            $output = sprintf( "$label %s", ucfirst( $1 ), $self->get( $_ ) );
            my $value = $self->$1;
            print $output;
            print ' (' . $value . ')' if $value;
            print "\n";
        }
        elsif ( /^tinfo\d$/ ) {
            $output = sprintf( "$label %s", ucfirst( $_ ), $self->get( $_ ) );
            my $name  = $_ . '_name';
            my $value = $self->$name;
            print $output;
            print ' (' . $value . ')' if $value;
            print "\n";
        }
        elsif ( $_ eq 'date' ) {
            $output
                = sprintf( "$label %s\n", 'Date', $self->date->mdy( '/' ) );
            print $output;
        }
        elsif ( $_ eq 'comments' ) {
            $output = sprintf( "$label %s\n",
                'Comments', scalar @{ $self->comments } );
            print $output;
        }
        else {
            $output
                = sprintf( "$label %s\n", ucfirst( $_ ), $self->get( $_ ) );
            print $output;
        }
    }

    my @comments = @{ $self->comments };

    return unless @comments;

    $output = sprintf( "$label %s\n", 'Comment_id', $self->comment_id );
    $output .= sprintf( $label, 'Comments' );

    print $output;

    for ( 0 .. $#comments ) {
        $output = sprintf(
            $_ == 0 ? " %s\n" : ( ' ' x ( $width + 1 ) ) . " %s\n",
            $comments[ $_ ]
        );
        print $output;
    }
}

=head2 datatype( )

Return the string version of the file's datatype. Use datatype_id to get the integer version.

=cut

sub datatype {

    # Return the datatype name
    return $datatypes[ $_[ 0 ]->datatype_id ];
}

=head2 filetype( )

Return the string version of the file's filetype. Use filetype_id to get the integer version.

=cut

sub filetype {

    # Return the filetype name
    return $filetypes->{ $_[ 0 ]->datatype }->{ filetypes }
        ->[ $_[ 0 ]->filetype_id ];
}

=head2 flags( )

Return the string version of the file's flags. Use flags_id to get the integer version.

=cut

sub flags {

    # Return an english description of the flags
    return $filetypes->{ $_[ 0 ]->datatype }->{ flags }
        ->{ $_[ 0 ]->flags_id };
}

=head2 tinfo1_name( )

Return an english description of what this info value represents (returns undef if there isn't one)

=cut

sub tinfo1_name {

    # Return an english description of info flag (1) or blank if there is none
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo1 };
}

=head2 tinfo2_name( )

Return an english description of what this info value represents (returns undef if there isn't one)

=cut

sub tinfo2_name {

    # Return an english description of info flag (2) or blank if there is none
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo2 };
}

=head2 tinfo3_name( )

Return an english description of what this info value represents (returns undef if there isn't one)

=cut

sub tinfo3_name {

    # Return an english description of info flag (3) or blank if there is none
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo3 };
}

=head2 tinfo4_name( )

Return an english description of what this info value represents (returns undef if there isn't one)

=cut

sub tinfo4_name {

    # Return an english description of info flag (4) or blank if there is none
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo4 };
}

=head2 date( [ $date ] )

This is an overloaded date accessor. It accepts two types of dates as inputs:
a Time::Piece object or a string in the format of 'YYYYMMDD'. It always
returns a Time::Piece object.

=cut

sub date {
    my $self = shift;
    my $date = shift;

    if ( $date ) {
        $self->set( 'date', $date->strftime( $date_format ) )
            if ref( $date ) eq 'Time::Piece';
        $self->set( 'date', $date ) if $date =~ /^\d{8}$/;
    }

    return Time::Piece->strptime( $self->get( 'date' ), $date_format );
}

=head1 PRIVATE METHODS

=head2 _create_io_object( { OPTIONS }, MODE )

Generates an IO object. Uses FileHandle or IO::String.

=cut

sub _create_io_object {
    my $self    = shift;
    my %options = %{ $_[ 0 ] };
    my $perms   = $_[ 1 ];

    my $file;

    # use appropriate IO object for what we get in
    if ( exists $options{ file } ) {
        $file = FileHandle->new( $options{ file }, $perms ) or croak "$!";
    }
    elsif ( exists $options{ string } ) {
        $file = IO::String->new( $options{ string } );
    }
    elsif ( exists $options{ handle } ) {
        $file = $options{ handle };
    }
    else {
        croak(
            "No valid read type. Must be one of 'file', 'string' or 'handle'."
        );
    }

    binmode $file;
    return $file;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
