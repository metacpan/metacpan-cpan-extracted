package Games::NES::ROM::Format::UNIF;

use Moose;

extends 'Games::NES::ROM';

has '+id' => ( default => "UNIF" );

has 'revision' => ( is => 'rw', isa => 'Int', default => 7 );

has 'comments' => ( is => 'rw' );

has 'tvci' => ( is => 'rw' );

has 'controller' => ( is => 'rw' );

has 'has_vror' => ( is => 'rw', isa => 'Bool', default => 0 );

sub BUILD {
    my $self = shift;
    my $fh = $self->filehandle;

    my $id;
    $fh->read( $id, 4 );

    die 'Not a UNIF rom' if $id ne $self->id;

    my $rev;
    $fh->read( $rev, 4 );
    $self->revision( unpack( 'V', $rev ) );

    $fh->seek( 24, 1 );

    my $chunk_header;
    while( $fh->read( $chunk_header, 8 ) ) {
        my( $cid, $length ) = unpack( 'A4 V', $chunk_header );

        my $chunk;
        $fh->read( $chunk, $length );

        my @args;
        if( $cid =~ m{(CHR|PRG|CCK|PCK)(.)} ) {
            $cid = $1;
            push @args, hex($2);
        }

        my $name = "_parse_${cid}_chunk";
        if( my $sub = $self->can( $name ) ) {
            $sub->( $self, $chunk, @args );
        }
    }

    $self->clear_filehandle;
    return $self;
}

sub _parse_NAME_chunk {
    my( $self, $title ) = @_;
    $self->title( unpack( 'A*', $title ) );
}

sub _parse_PRG_chunk {
    my( $self, $prg, $id ) = @_;
    $self->prg_banks->[ $id ] = $prg;
}

sub _parse_CHR_chunk {
    my( $self, $chr, $id ) = @_;
    $self->chr_banks->[ $id ] = $chr;
}

sub _parse_READ_chunk {
    my( $self, $comments ) = @_;
    $self->comments( unpack( 'A*', $comments ) );
}

sub _parse_BATR_chunk {
    shift->has_sram( 1 );
}

sub _parse_VROR_chunk {
    shift->has_vror( 1 );
}

sub _parse_MIRR_chunk {
    my( $self, $mirroring ) = @_;
    $self->mirroring( unpack( 'C', $mirroring ) );
}

sub _parse_TVCI_chunk {
    my( $self, $tvci ) = @_;
    $self->tvci( unpack( 'C', $tvci ) );
}

sub _parse_CTRL_chunk {
    my( $self, $controller ) = @_;
    $self->controller( unpack( 'C', $controller ) );
}

sub _parse_MAPR_chunk {
    my( $self, $mapper ) = @_;
    $self->mapper( unpack( 'A*', $mapper ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Games::NES::ROM::Format::UNIF - Loads data from a ROM in UNIF format

=head1 DESCRIPTION

This module loads the details of an NES rom in UNIF format. A UNIF file is
layed out as follows:

    +----------+
    | "UNIF"   | 4 Bytes
    +----------+
    | Revision | 32-bit Word
    +----------+
    | Filler   | 24 Bytes
    +----------+
    | Chunk ID | 4 Bytes
    +----------+
    | Length   | 32-bit Word
    +----------+
    | Data     |
    +----------+
    etc...

=head1 METHODS

=head2 BUILD( )

A L<Moose> method which loads the ROM data from a file.

=head1 ATTRIBUTES

Along with the L<base attributes|Games::NES::ROM/BASE ATTRIBUTES>, the following UNIF specific attributes are
available:

=over 4

=item * id - UNIF identifier: "UNIF"

=item * revision - The revision of the UNIF spec for this file

=item * comments - A set of text comments

=item * tvci - Television standards compatability information

=item * controller - The controllers used by the cartridge

=item * has_vror - The ROM has a VRAM override

=back

=head1 SEE ALSO

=over 4

=item * Games::NES::ROM

=item * http://www.viste-family.net/mateusz/nes/html/tech/unif_cur.txt

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
