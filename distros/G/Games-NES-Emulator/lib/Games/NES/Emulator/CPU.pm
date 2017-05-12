package Games::NES::Emulator::CPU;

use strict;
use warnings;

use base qw( CPU::Emulator::6502 );

use Scalar::Util ();

__PACKAGE__->mk_accessors( 'context' );

=head1 NAME

Games::NES::Emulator::CPU - NES Central Processing Unit

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 init()

=cut

sub init {
    my $self = shift;
    my $emu = shift;
    Scalar::Util::weaken( $emu );

    $self->SUPER::init( @_ );
    $self->context( $emu );
    $self->interrupt_line( 0 );

    $self->memory( [ ( 0 ) x ( 0xFFFF + 1 ) ] );

    my $reg = $self->registers;
    $reg->{ pc } = 0x8000;
    $reg->{ sp } = 0xFF;

    $self->toggle( 1 );
    $self->cycle_counter( 0 );
    $self->frame_counter( 0 );
}

=head2 RAM_read( $addr )

=cut

sub RAM_read {
    my( $self, $addr ) = @_;
    my $c = $self->context;
    my $block = $addr >> 13;

    if( $block == 0 ) {
        return $self->SUPER::RAM_read( $addr & 0x7FF );
    }
    elsif( $block == 1 ) {
        my $ppu_addr = ( $addr & 0x7 ) + 0x2000;
        my $ppu = $c->ppu;
        my $reg = $ppu->registers;

        if( $ppu_addr == 0x2002 ) {
            $self->toggle( 1 );
            my $val = $reg->{ status };
            $reg->{ status } &= 0x7f;
            return $val;
        }
        elsif( $ppu_addr == 0x2007 ) {
            return $ppu->VRAM->read( $reg->{ VRAM_addr }, 1 );
        }
    }
    elsif( $block == 2 ) {
        if( ( $addr & 0x3F40 ) == 0 ) {
            if( $addr == 0x4016 ) {
                return $c->inputs->[ 0 ]->poll;
            }
            elsif( $addr == 0x4017 ) {
                return $c->inputs->[ 1 ]->poll;
            }

            return $c->apu->read( $addr );
        }

        return $c->mapper->read( $addr );
    }
    elsif( $block == 3 ) {
        return $self->SUPER::RAM_read( $addr );
    }
    else {
        return $c->mapper->read( $addr );
    }
}

=head2 RAM_write( $addr => $data )

=cut

sub RAM_write {
    my( $self, $addr, $data ) = @_;
    my $c = $self->context;
    my $block = $addr >> 13;

    # TODO other cases
    if( $block == 0 ) {
        return $self->SUPER::RAM_write( ( $addr & 0x7FF ) => $data );
    }
    elsif( $block == 1 ) {
        my $ppu_addr = ( $addr & 0x7 ) + 0x2000;
        my $ppu = $c->ppu;
        my $reg = $ppu->registers;

        if( $ppu_addr == 0x2000 ) {
            $reg->{ control1 } = $data;
            $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0xF3FF) | ( $data & 0x3 ) << 10;		

            $ppu->VRAM->increment( $data & 0x04 ? 32 : 1 );
        }
        elsif( $ppu_addr == 0x2001 ) {
            $reg->{ control2 } = $data;
        }
        elsif( $ppu_addr == 0x2002 ) {
        }
        elsif( $ppu_addr == 0x2003 ) {
            $reg->{ SPRRAM_addr } = $data;
        }
        elsif( $ppu_addr == 0x2004 ) {
            $ppu->SPRRAM->[ $reg->{ SPRRAM_addr } ] = $data;
        }
        elsif( $ppu_addr == 0x2005 ) {
            if( $self->toggle ) {
                $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0xffe0 ) | ( ( $data & 0xf8 ) >> 3 );
                $ppu->draw->{ x_pixel_offset } = $data & 0x7;
            }
            else {
                $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0xfc1f ) | ( ( $data & 0xf8 ) << 2 );
                $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0x8fff ) | ( ( $data & 0x7 ) << 12 );
            }
            $self->toggle( !$self->toggle );
        }
        elsif( $ppu_addr == 0x2006 ) {
            if( $self->toggle ) {
                $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0xc0ff ) | ( ( $data & 0x3f ) << 8 );
				$reg->{ VRAM_temp_addr } &= 0x3fff;
            }
            else {
                $reg->{ VRAM_temp_addr } = ( $reg->{ VRAM_temp_addr } & 0xff00 ) | $data;
                $reg->{ VRAM_addr } = $reg->{ VRAM_temp_addr };
            }
            $self->toggle( !$self->toggle );
        }
        elsif( $ppu_addr == 0x2007 ) {
            $ppu->VRAM->write( $reg->{ VRAM_addr }, $data, 1 );
        }

        return;
    }
    elsif( $block == 2 ) {
    }
    elsif( $block == 3 ) {
        $self->SUPER::RAM_write( $addr => $data );
        return $c->mapper->write( $addr => $data );
    }
    else {
        return $c->mapper->write( $addr => $data );
    }

}

=head2 DMAT_transfer( $page )

=cut

sub DMAT_transfer {
    my( $self, $page ) = @_;
    my $addr = $page * 0x100;

    my $ram = $self->context->ppu->SPRRAM;

    @$ram = map { $self->RAM_read( $addr + $_ ) } 0..0xFF;

    $self->cycle_counter( $self->cycle_counter + 512 );
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<CPU::Emulator::6502>

=item * L<Games::NES::Emulator>

=back

=cut

1;
