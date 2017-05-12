package Games::NES::Emulator::Mapper;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Scalar::Util ();

__PACKAGE__->mk_accessors( qw( context chr_map prg_map ) );

=head1 NAME

Games::NES::Emulator::Mapper - Base class for mappers

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 init( )

=cut

sub init {
    my $self = shift;
    my $emu = shift;
    Scalar::Util::weaken( $emu );

    $self->context( $emu );

    $self->_init_maps;
    $self->_init_memory;
}

sub _init_maps {
    my $self = shift;
    $self->prg_map( {
        8  => [ (-1) x 4 ],
        16 => [ (-1) x 2 ],
        32 => [ -1 ],
    } );
    $self->chr_map( {
        1 => [ (-1) x 8 ],
        2 => [ (-1) x 4 ],
        4 => [ (-1) x 2 ],
        8 => [ -1 ],
    } );
}

sub _init_memory {
    my $self = shift;
    my $rom  = $self->context->rom;

    my $prgs = $rom->PRG_count;
    if( $prgs > 0 ) {
        if( $prgs == 1 ) {
            $self->swap_prg_16k( 0x8000, 0 );
            $self->swap_prg_16k( 0xC000, 0 );
        }
        else {
            $self->swap_prg_32k( 0 );
        }
    }

    if( $rom->CHR_count > 0 ) {
        $self->swap_chr_8k( 0 );
    }
}

=head2 read( $address )

Reads $address from the CPU's memory.

=cut

sub read {
    my( $self, $addr ) = @_;
    return $self->context->cpu->memory->[ $addr ];
}

=head2 write( $address => $data )

The base mapper doesn't actually do any writes.

=cut

sub write {
}

=head2 swap_prg_8k( $offset, $bank )

Swap an 8K bank of PRGROM into the CPU's memory.

=cut

sub swap_prg_8k {
    my( $self, $offset, $bank ) = @_;
    my $slot = ($offset & 0x4000) >> 14;
    my $map_8k = $self->prg_map->{ 8 };

    if( $map_8k->[ $slot ] != $bank ) {
        my $c = $self->context;
        my $bank_offset = 0;
        my $prg_bank = $bank >> 1;

        $bank_offset = 0x2000 if $bank == 1;
        splice( @{ $c->cpu->memory }, $bank_offset, 0x2000, unpack( 'C*', substr( $c->rom->PRG_banks->[ $prg_bank ], $bank_offset, 0x2000 ) ) );

        $map_8k->[ $slot ] = $bank;
    }

}

=head2 swap_prg_16k( $offset, $bank )

Swap a 16K bank of PRGROM into the CPU's memory.

=cut

sub swap_prg_16k {
    my( $self, $offset, $bank ) = @_;
    my $slot = ($offset & 0x4000) >> 14;
    my $map_16k = $self->prg_map->{ 16 };
    my $map_8k = $self->prg_map->{ 8 };

    if( $map_16k->[ $slot ] != $bank ) {
        my $c = $self->context;
        splice( @{ $c->cpu->memory }, $offset, 0x4000, unpack( 'C*', $c->rom->PRG_banks->[ $bank ] ) );
        $map_16k->[ $slot ] = $bank;
    }

    my $eb = $offset == 0x8000 ? 0 : 2;
    $map_8k->[ $eb ] = $bank << 1;
    $map_8k->[ $eb + 1 ] = ( $bank << 1 ) + 1;
}

=head2 swap_prg_32k( $bank )

Swap a 32K bank of PRGROM into the CPU's memory.

=cut

sub swap_prg_32k {
    my( $self, $bank ) = @_;
    my $map_8k = $self->prg_map->{ 8 };
    my $map_32k = $self->prg_map->{ 32 };

    if( !$map_32k->[ 0 ] || $map_32k->[ 0 ] != $bank ) {
        $map_32k->[ 0 ] = $bank;
        $bank <<= 1;
        my $c = $self->context;

        splice( @{ $c->cpu->memory }, 0x8000, 0x4000, unpack( 'C*', $c->rom->PRG_banks->[ $bank ] ) );
        splice( @{ $c->cpu->memory }, 0xC000, 0x4000, unpack( 'C*', $c->rom->PRG_banks->[ $bank + 1 ] ) );
    }

    my $b = $bank << 2;
    $map_8k = [ map { $b + $_ } (0..3) ];
}

=head2 swap_chr_1k( $offset, $bank )

Swap a 1k bank of CHRROM into the PPU's memory

=cut

sub swap_chr_1k {
    my( $self, $offset, $bank ) = @_;

    my $r_bank = $bank >> 3;
    my $bank_offset = ( $bank & 0x07 ) * 0x400;
    my $c = $self->context;

    if( $offset < 0x2000 ) {
        my $map_1k = $self->chr_map->{ 1 };
        my $slot = ( $offset & 0x1C00 ) >> 10;
        if( $map_1k->[ $slot ] != $bank ) {            
            splice( @{ $c->ppu->VRAM->memory }, $offset, 0x400, unpack( 'C*', substr( $c->rom->CHR_banks->[ $r_bank ], $bank_offset, 0x400 ) ) );

            $map_1k->[ $slot ] = $bank;
        }
        
    }
    else { # name table swap
        my $nt = ( $offset & 0xc00 ) >> 10;
        splice( @{ $c->ppu->VRAM->name_table->[ $nt ] }, 0, 0x400, unpack( 'C*', substr( $c->rom->CHR_banks->[ $r_bank ], $bank_offset, 0x400 ) ) );
    }
}

=head2 swap_chr_2k( $offset, $bank )

Swap a 2k bank of CHRROM into the PPU's memory

=cut

sub swap_chr_2k {
    my( $self, $offset, $bank ) = @_;
    my $map_2k = $self->chr_map->{ 2 };
    my $slot = ( $offset & 0x1800 ) >> 11;
    if( $map_2k->[ $slot ] != $bank ) {
        my $bank_offset = ( $bank & 3 ) << 11;
        $bank >>= 2;

        my $c = $self->context;
        splice( @{ $c->ppu->VRAM->memory }, $offset, 0x800, unpack( 'C*', substr( $c->rom->CHR_banks->[ $bank ], $bank_offset, 0x800 ) ) );

        $map_2k->[ $slot ] = $bank;
    }
}

=head2 swap_chr_4k( $offset, $bank )

Swap a 4k bank of CHRROM into the PPU's memory

=cut

sub swap_chr_4k {
    my( $self, $offset, $bank ) = @_;
    my $map_4k = $self->chr_map->{ 4 };
    my $slot = ( $offset & 0x1000 ) >> 12;

    if( $map_4k->[ $slot ] != $bank ) {
        my $bank_offset = 0;
        $bank_offset = 0x1000 if $bank & 1;
        $bank >>= 1;

        my $c = $self->context;
        splice( @{ $c->ppu->VRAM }, $offset, 0x1000, unpack( 'C*', substr( $c->rom->CHR_banks->[ $bank ], $bank_offset, 0x1000 ) ) );

        $map_4k->[ $slot ] = $bank;
    }
}

=head2 swap_chr_8k( $bank )

Swap an 8k bank of CHRROM into the PPU's memory

=cut

sub swap_chr_8k {
    my( $self, $bank ) = @_;
    my $map_8k = $self->chr_map->{ 8 };
    
    if( $map_8k->[ 0 ] != $bank  ) {
        my $c = $self->context;
        splice( @{ $c->ppu->VRAM->memory }, 0, 0x2000, unpack( 'C*', $c->rom->CHR_banks->[ $bank ] ) );
        $map_8k->[ 0 ] = $bank;
    }
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Games::NES::Emulator>

=back

=cut

1;
