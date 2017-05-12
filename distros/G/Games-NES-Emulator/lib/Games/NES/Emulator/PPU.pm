package Games::NES::Emulator::PPU;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Games::NES::Emulator::PPU::Memory;

__PACKAGE__->mk_accessors( qw( registers timers VRAM SPRRAM palette draw ) );

my @registers = qw( control1 control2 status SPRRAM_addr VRAM_IO VRAM_addr VRAM_temp_addr );
my @times = qw( sprite_0_pixel sprite_0_scanline other_irq other_pixel current_ppu_cycle );
my @draw = qw( x_pixel_offset );

=head1 NAME

Games::NES::Emulator::PPU - NES Picture Processing Unit

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 init( )

=cut

sub init {
    my $self = shift;
    $self->SPRRAM( [ ( 0 ) x ( 0xFF + 1 ) ] );
    $self->VRAM( Games::NES::Emulator::PPU::Memory->new )->init;

    $self->timers( {} );
    $self->timers->{ other_irq } = 0;

    $self->palette( [
        0x808080, 0x003DA6, 0x0012B0, 0x440096, 0xA1005E, 0xC70028, 0xBA0600, 0x8C1700,
        0x5C2F00, 0x104500, 0x054A00, 0x00472E, 0x004166, 0x000000, 0x050505, 0x050505,
        0xC7C7C7, 0x0077FF, 0x2155FF, 0x8237FA, 0xEB2FB5, 0xFF2950, 0xFF2000, 0xD63200,
        0xC46200, 0x358000, 0x058F00, 0x008A55, 0x0099CC, 0x212121, 0x090909, 0x090909,
        0xFFFFFF, 0x0FD7FF, 0x69A2FF, 0xD480FF, 0xFF45F3, 0xFF618B, 0xFF8833, 0xFF9C12,
        0xFABC20, 0x9FE30E, 0x2BF035, 0x0CF0A4, 0x05FBFF, 0x5E5E5E, 0x0D0D0D, 0x0D0D0D, 
        0xFFFFFF, 0xA6FCFF, 0xB3ECFF, 0xDAABEB, 0xFFA8F9, 0xFFABB3, 0xFFD2B0, 0xFFEFA6,
        0xFFF79C, 0xD7E895, 0xA6EDAF, 0xA2F2DA, 0x99FFFC, 0xDDDDDD, 0x111111, 0x111111,    ] );
    
    $self->registers( { map { $_ => 0 } @registers } );
    $self->registers->{ status } = 0x80;
    $self->draw( { map { $_ => 0 } @draw } );
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
