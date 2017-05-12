package Games::NES::ROM;

use Moose;
use Module::Runtime ();
use Try::Tiny;
use FileHandle;

our $VERSION = '0.08';

has 'filename' => ( is => 'rw' );

has 'filehandle' => ( is => 'rw', isa => 'FileHandle', lazy_build => 1 );

has 'id' => ( is => 'ro' );

has 'title' => ( is => 'rw' );

has 'prg_banks' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'chr_banks' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'has_sram' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'mirroring' => ( is => 'rw', isa => 'Int', default => 0 );

has 'mapper' => ( is => 'rw' );

sub _build_filehandle {
    my $self = shift;
    my $file = $self->filename;
    my $fh   = FileHandle->new( $file, '<' );

    die "Unable to open ${file}: $!" unless defined $fh;

    binmode( $fh );
    return $fh;
}

__PACKAGE__->meta->make_immutable;

sub load {
    my( $class, $file ) = @_;

    for( qw( INES UNIF ) ) {
        my $class = 'Games::NES::ROM::Format::' . $_;
        Module::Runtime::require_module( $class );

        my $rom = try {
            $class->new( filename => $file );
        };

        return $rom if $rom;
    }

    die "${file} is not an NES rom";
}

sub prg_count {
    return scalar @{ shift->prg_banks };
}

sub chr_count {
    return scalar @{ shift->chr_banks };
}

sub sha1 {
    my $self = shift;
    require Digest::SHA1;
    return Digest::SHA1::sha1_hex( @{ $self->prg_banks }, @{ $self->chr_banks } );
}

sub crc {
    my $self = shift;
    require Digest::CRC;
    return Digest::CRC::crc32_hex( join( '', @{ $self->prg_banks }, @{ $self->chr_banks } ) );
}

sub sprite {
    my( $self, $chr, $offset ) = @_;

    die 'invalid CHR bank' if $chr > $self->chr_count - 1 or $chr < 0;
    die 'invalid sprite index' if $offset > 512 or $offset < 0;
    
    my $bank      = $self->chr_banks->[ $chr ];
    my $start     = 16 * $offset;
    my @channel_a = unpack( 'C*', substr( $bank, $start, 8 ) );
    my @channel_b = unpack( 'C*', substr( $bank, $start + 8, 8 ) );

    my $composite = '';

    for my $i ( 0..7 ) {
        for my $j ( reverse 0..7 ) {
            $composite .= pack( 'C', $self->_combine_bits( $channel_a[ $i ], $channel_b[ $i ], $j ) );
        }
    }
    
    return $composite;
}

sub _combine_bits {
    my $self = shift;
    my( $chan_a, $chan_b, $offset ) = @_;

    return ( ( $chan_a >> $offset ) & 1 ) | ( ( ( $chan_b >> $offset ) & 1 ) << 1 );
}

1;

__END__

=head1 NAME

Games::NES::ROM - View information about an NES game from a ROM file

=head1 SYNOPSIS

    use Games::NES::ROM;
    
    # Read in the ROM without having to know its format
    my $rom = Games::NES::ROM->load( 'file.nes' );

    # Specifically read in an iNES file
    $rom = Games::NES::ROM::INES->new( filename => 'file.nes' );

    # Access the details
    print 'PRG Banks: ', $rom->prg_count, "\n";
    print 'CHR Banks: ', $rom->prg_count, "\n";
    # etc...
    
    # View the SHA-1 & CRC checksums
    print 'SHA1: ', $rom->sha1, "\n";
    print ' CRC: ', $rom->crc, "\n";

=head1 DESCRIPTION

This module loads the details of an NES rom file. It is primarily meant to be
used a base class for more specific file formats. Those formats include:

=over 4

=item * L<Universal NES Image File (UNIF)|Games::NES::ROM::Format::UNIF>

=item * L<iNES|Games::NES::ROM::Format::INES>

=back

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=head1 METHODS

=head2 load( $filename )

Attemps to read the ROM structure into memory using all available file
formats until success.

=head2 prg_count( )

Returns the number of PRG banks for this ROM.

=head2 chr_count( )

Returns the number of CHR banks for this ROM.

=head2 sha1( )

Returns the SHA-1 checksum for the PRG and CHR data.

=head2 crc( )

Returns the CRC checksum for the PRG and CHR data.

=head2 sprite( $chr_bank, $index )

Returns the raw (composite) sprite in the specified 
CHR bank at the specified array index.

=head1 BASE ATTRIBUTES

The following base attributes are available for all file formats:

=over 4

=item * filename - The filename from which data was loaded

=item * id - A string found at the beginning of a file to identify the file format

=item * title - The game's title, if available 

=item * prg_banks - An arrayref of PRG bank data

=item * chr_banks - An arrayref of CHR bank data

=item * has_sram - Boolean value to determine if the ROM is battery backed

=item * mapper - A value indicating what memory mapper to use with the ROM

=item * mirroring - A value indicating what time of mirroring is used in the ROM

=back

=head2 NOTES

=over 4

=item * mapper - iNES uses integer IDs, UNIF uses string IDs

=item * mirroring - An integer ID, using the UNIF list as a basis

=back

Each file format will have an extended set of attributes specific to its data
structure. Please consult their documentation for more information.

=head1 SEE ALSO

=over 4

=item * L<Games::NES::ROM::Format::INES>

=item * L<Games::NES::ROM::Format::UNIF>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

