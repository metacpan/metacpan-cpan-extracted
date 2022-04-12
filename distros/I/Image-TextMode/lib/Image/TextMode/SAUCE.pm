package Image::TextMode::SAUCE;

use Moo;
use Types::Standard qw( Int Str ArrayRef Bool );

# some SAUCE constants
my $SAUCE_ID      = 'SAUCE';
my $SAUCE_VERSION = '00';
my $SAUCE_FILLER  = "\0" x 22;
my $COMNT_ID      = 'COMNT';

=head1 NAME

Image::TextMode::SAUCE - Create, manipulate and save SAUCE metadata

=head1 DESCRIPTION

This module reads and writes SAUCE metadata. SAUCE metadata is a 128-byte
record stored after an EOF char at the end of a given file.

=head1 ACCESSORS

=over 4

=item * sauce_id - identified at the start of the record (default: SAUCE)

=item * version - sauce version (default: 00)

=item * title - title of the work

=item * author - author name

=item * group - group affiliation

=item * date - YYYYMMDD date (default: today's date)

=item * filesize - the size of the file, less sauce info

=item * datatype_id - numeric identifier for the data type

=item * filetype_id - numeric identifier for the file sub-type

=item * tinfo1 - first slot of filetype-specific info

=item * tinfo2 - second slot of filetype-specific info

=item * tinfo3 - third slot of filetype-specific info

=item * tinfo4 - fourth slot of filetype-specific info

=item * comment_count - number of comments stored before the sauce record

=item * flags_id - datatype specific flags

=item * filler - 22 spaces to fill in the remaining bytes

=item * comment_id - identifier for comments section (default: COMNT)

=item * comments - array ref of comment lines

=item * has_sauce - undef before read; after read: true if file has sauce record

=back

=cut

has 'sauce_id' => ( is => 'rw', isa => Str, default => sub { $SAUCE_ID } );

has 'version' =>
    ( is => 'rw', isa => Str, default => sub { $SAUCE_VERSION } );

has 'title' => ( is => 'rw', isa => Str, default => sub { '' } );

has 'author' => ( is => 'rw', isa => Str, default => sub { '' } );

has 'group' => ( is => 'rw', isa => Str, default => sub { '' } );

has 'date' => (
    is      => 'rw',
    isa     => Str,
    default => sub {
        my @t = ( localtime )[ 5, 4, 3 ];
        return sprintf '%4d%02d%02d', 1900 + $t[ 0 ], $t[ 1 ] + 1, $t[ 2 ];
    }
);

has 'filesize' => ( is => 'rw', isa => Int, default => 0 );

has 'filetype_id' => ( is => 'rw', isa => Int, default => 0 );

has 'datatype_id' => ( is => 'rw', isa => Int, default => 0 );

has 'tinfo1' => ( is => 'rw', isa => Int, default => 0 );

has 'tinfo2' => ( is => 'rw', isa => Int, default => 0 );

has 'tinfo3' => ( is => 'rw', isa => Int, default => 0 );

has 'tinfo4' => ( is => 'rw', isa => Int, default => 0 );

has 'comment_count' => ( is => 'rw', isa => Int, default => 0 );

has 'flags_id' => ( is => 'rw', isa => Int, default => 0 );

has 'filler' =>
    ( is => 'rw', isa => Str, default => sub { $SAUCE_FILLER } );

has 'comment_id' =>
    ( is => 'rw', isa => Str, default => sub { $COMNT_ID } );

has 'comments' => ( is => 'rw', isa => ArrayRef, default => sub { [] } );

has 'has_sauce' => ( is => 'rw', isa => Bool );

# define datatypes and filetypes as per SAUCE specs
my @datatypes
    = qw(None Character Graphics Vector Sound BinaryText XBin Archive Executable);
my $filetypes = {
    None => {
        filetypes => [ 'Undefined' ],
        flags     => [ 'None' ]
    },
    Character => {
        filetypes =>
            [ qw( ASCII ANSi ANSiMation RIP PCBoard Avatar HTML Source TundraDraw ) ],
        flags => [ ( 'ANSiFlags' ) x 3, ( 'None' ) x 6 ],
        tinfo => [
            ( { tinfo1 => 'Width', tinfo2 => 'Height' } ) x 3,
            { tinfo1 => 'Width', tinfo2 => 'Height', tinfo3 => 'Colors' },
            ( { tinfo1 => 'Width', tinfo2 => 'Height' } ) x 2,
            ( {} ) x 2,
            { tinfo1 => 'Width', tinfo2 => 'Height' }
        ]
    },
    Bitmap => {
        filetypes => [
            qw( GIF PCX LBM/IFF TGA FLI FLC BMP GL DL WPG PNG JPG MPG AVI )
        ],
        flags => [ ( 'None' ) x 14 ],
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
        flags     => [ ( 'None' ) x 4 ],
    },
    Audio => {
        filetypes => [
            qw( MOD 669 STM S3M MTM FAR ULT AMF DMF OKT ROL CMF MIDI SADT VOC WAV SMP8 SMP8S SMP16 SMP16S PATCH8 PATCH16 XM HSC IT )
        ],
        flags => [ ( 'None' ) x 20 ],
        tinfo => [ ( {} ) x 16, ( { tinfo1 => 'Sampling Rate' } ) x 4 ]
    },
    BinaryText => {
        filetypes => [ qw( Undefined ) ],
        flags     => [ 'ANSiFlags' ],
    },
    XBin => {
        filetypes => [ qw( Undefined ) ],
        flags     => [ 'None' ],
        tinfo     => [ { tinfo1 => 'Width', tinfo2 => 'Height' }, ]
    },
    Archive => {
        filetypes => [ qw( ZIP ARJ LZH ARC TAR ZOO RAR UC2 PAK SQZ ) ],
        flags     => [ ( 'None' ) x 10 ],
    },
    Executable => {
        filetypes => [ qw( Undefined ) ],
        flags     => [ 'None' ],
    }
};

# vars for use with pack() and unpack()
my $sauce_template = 'A5 A2 A35 A20 A20 A8 V C C v v v v C C Z22';
my @sauce_fields
    = qw( sauce_id version title author group date filesize datatype_id filetype_id tinfo1 tinfo2 tinfo3 tinfo4 comment_count flags_id filler );
my $comnt_template = 'A5 A64';
my @comnt_fields   = qw( comment_id comments );

=head1 METHODS

=head2 new( %args )

Creates a new SAUCE metadata instance.

=head2 read( $fh )

Read the sauce record from C<$fh>.

=cut

sub read {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ( $self, $fh ) = @_;

    my $buffer;
    my %info;

    seek( $fh, 0, 2 );
    return if tell $fh < 128;

    seek( $fh, -128, 2 );
    my $size = read( $fh, $buffer, 128 );

    # Check for "SAUCE00" header
    if ( substr( $buffer, 0, 7 ) ne "$SAUCE_ID$SAUCE_VERSION" ) {
        $self->has_sauce( 0 );
        return;
    }

    @info{ @sauce_fields } = unpack( $sauce_template, $buffer );

    # Do we have any comments?
    my $comment_count = $info{ comment_count };

    $self->$_( $info{ $_ } ) for keys %info;
    $self->has_sauce( 1 );

    if ( $comment_count > 0 ) {
        seek( $fh, -128 - 5 - $comment_count * 64, 2 );
        read( $fh, $buffer, 5 + $comment_count * 64 );

        if ( substr( $buffer, 0, 5 ) eq $COMNT_ID ) {
            my $template
                = $comnt_template
                . ( split( / /s, $comnt_template ) )[ 1 ]
                x ( $comment_count - 1 );
            my ( $id, @comments ) = unpack( $template, $buffer );
            $self->comment_id( $id );
            $self->comments( \@comments );
        }
    }
}

=head2 write( $fh )

Write the sauce record to C<$fh>.

=cut

sub write {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ( $self, $fh ) = @_;

    seek( $fh, 0, 2 );
    print $fh chr( 26 );

    # comments...
    my $comments = scalar @{ $self->comments };
    if ( $comments ) {
        print $fh pack(
            $comnt_template
                . (
                ( split( / /s, $comnt_template ) )[ 1 ] x ( $comments - 1 )
                ),
            $self->comment_id,
            @{ $self->comments }
        );
    }

    # SAUCE...
    my @template = split( / /s, $sauce_template );
    for ( 0 .. $#sauce_fields ) {
        my $field = $sauce_fields[ $_ ];
        my $value = ( $field ne 'comments' ) ? $self->$field : $comments;
        print $fh pack( $template[ $_ ], $value );
    }

}

=head2 record_size( )

Return the size of the SAUCE record in bytes.

=cut

sub record_size {
    my $self = shift;

    return 0 unless $self->has_sauce;

    my $size = 128;

    if( $self->comment_count ) {
        $size += 5 + ( 64 * $self->comment_count );
    }

    return $size;
}

=head2 datatype( )

The string name of the data represented in datatype_id.

=cut

sub datatype {
    return $datatypes[ $_[ 0 ]->datatype_id || 0 ];
}

=head2 filetype( )

The string name of the data represented in filetype_id.

=cut

sub filetype {
    # Filetype for "BinaryText" (id: 5) is used to encode the image width
    if( $_[ 0 ]->datatype_id == 5 ) {
        return 'Undefined';
    }

    return $filetypes->{ $_[ 0 ]->datatype }->{ filetypes }
        ->[ $_[ 0 ]->filetype_id || 0 ];
}

=head2 flags( )

The string name of the data represented in flags_id.

=cut

sub flags {
    return $filetypes->{ $_[ 0 ]->datatype }->{ flags }
        ->[ $_[ 0 ]->filetype_id ];
}

=head2 tinfo1_name( )

The string name of the data represented in tinfo1.

=cut

sub tinfo1_name {
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo1 };
}

=head2 tinfo2_name( )

The string name of the data represented in tinfo2.

=cut

sub tinfo2_name {
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo2 };
}

=head2 tinfo3_name( )

The string name of the data represented in tinfo3.

=cut

sub tinfo3_name {
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo3 };
}

=head2 tinfo4_name( )

The string name of the data represented in tinfo4.

=cut

sub tinfo4_name {
    return $filetypes->{ $_[ 0 ]->datatype }->{ tinfo }
        ->[ $_[ 0 ]->filetype_id ]->{ tinfo4 };
}

=head2 tinfos( )

An alias for filler() to match the SAUCE 00.5 specification. The value may be 
a font name for ASCII, ANSI, ANSiMation, and BinaryText files. 

=cut

sub tinfos {
    shift->filler( @_ );
}

=head2 parse_ansiflags( )

For filetypes that support it, extract the metadata embeded in the flags. 
Currently, those fields are:

=over 4

=item * blink_mode

=item * 9th_bit

=item * dos_aspect

=back

=cut

sub parse_ansiflags {
    my $self  = shift;
    my $flags = {};

    my $dt = $self->datatype_id;
    my $ft = $self->filetype_id;
    return $flags unless $dt == 5 || ( $dt == 1 && $ft <= 2 );

    my $fid = $self->flags_id;
    $flags->{ 'blink_mode' } = ($fid & 1) ^ 1;
    $flags->{ '9th_bit' } = ($fid & 6) == 4;
    $flags->{ 'dos_aspect' } = ($fid & 24) == 8; 

    return $flags;
}

=head1 SEE ALSO

=over 4

=item * http://www.acid.org/info/sauce/sauce.htm

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
