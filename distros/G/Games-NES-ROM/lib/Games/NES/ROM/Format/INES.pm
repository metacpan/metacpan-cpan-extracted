package Games::NES::ROM::Format::INES;

use Moose;

extends 'Games::NES::ROM';

has '+id' => ( default => "NES\x1a" );

has 'trainer' => ( is => 'rw' );

sub BUILD {
    my $self = shift;
    my $fh = $self->filehandle;

    my $id;
    $fh->read( $id, 4 );

    die 'Not an iNES rom' if $id ne $self->id;

    my $header;
    $fh->read( $header, 12 );

    my @header_vals = unpack( 'C*', $header );

    $self->mirroring( $header_vals[ 3 ] & 1 );
    if( $header_vals[ 3 ] & 8 ) {
        $self->mirroring( 4 );
    }
    $self->has_sram( $header_vals[ 3 ] & 2 );

    if( $header_vals[ 3 ] & 4 ) {
        my $trainer;
        $fh->read( $trainer, 512 );
        $self->trainer( $trainer );
    }

    my $mapper = ( $header_vals[ 3 ] & 240 ) >> 4;
    $mapper   |= ( $header_vals[ 4 ] & 240 );

    if( $mapper != 0 and $header_vals[ 0 ] <= 2 and $header_vals[ 1 ] == 1 ) {
        $mapper = 0;
    }

    $self->mapper( $mapper );
    for( 1..$header_vals[ 0 ] ) {
        $fh->read( my $bank, 16384 );
        $self->prg_banks->[ scalar @{ $self->prg_banks } ] = $bank;
    }
    for( 1..$header_vals[ 1 ] ) {
        $fh->read( my $bank, 8192 );
        $self->chr_banks->[ scalar @{ $self->chr_banks } ] = $bank;
    }

    my $title;
    if( $fh->read( $title, 128 ) == 128 ) {
        $self->title( $title );
    }

    $self->clear_filehandle;
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Games::NES::ROM::Format::INES - Loads data from a ROM in iNES format

=head1 DESCRIPTION

This module loads the details of an NES rom in iNES format. An iNES file is
layed out as follows:

    +-----------+-----------------+---------+---------+ Header
    | NES\0x01a | [PC] [CC] F6 F7 | X X X X | X X X X | 16 Bytes
    +-----------+-----------------+---------+---------+
    |                                                 |
    |           Trainer (512 Bytes; Optional)         |
    |                                                 |
    +-------------------------------------------------+
    |                                                 |
    |           PRG Banks (PC * 16384 Bytes)          |
    |                                                 |
    +-------------------------------------------------+
    |                                                 |
    |           CHR Banks (CC * 8192 Bytes)           |
    |                                                 |
    +-------------------------------------------------+
    |                                                 |
    |           Title (128 Bytes; Optional)           |
    |                                                 |
    +-------------------------------------------------+
    
    PC: PRG bank count
    CC: CHR bank count
    F6: Various flags (Byte 6)
    F7: Various flags (Byte 7)

=head1 METHODS

=head2 BUILD( )

A L<Moose> method which loads the ROM data from a file.

=head1 ATTRIBUTES

Along with the L<base attributes|Games::NES::ROM/BASE ATTRIBUTES>, the following iNES specific attributes are
available:

=over 4

=item * id - iNES identifier: "NES\x1a"

=item * trainer - Trainer data, if available

=back

=head1 SEE ALSO

=over 4

=item * Games::NES::ROM

=item * http://wiki.nesdev.com/w/index.php/INES

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

