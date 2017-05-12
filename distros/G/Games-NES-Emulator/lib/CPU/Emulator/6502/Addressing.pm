package CPU::Emulator::6502::Addressing;

use strict;
use warnings;

=head1 NAME

CPU::Emulator::6502::Addressing - Handle different addressing rules

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 immediate( )

Immediate addressing; immediately following the op.

=cut

sub immediate {
    my $self = shift;
    my $reg  = $self->registers;

    return $reg->{ pc }++;
}

=head2 zero_page( )

Zero Page addressing. Address $00nn.

=cut

sub zero_page {
    my $self = shift;
    my $reg  = $self->registers;

    return $self->memory->[ $reg->{ pc }++ ];
}

=head2 zero_page_x( )

Zero Page addressing, X indexed. $00nn + X.

=cut

sub zero_page_x {
    my $self = shift;
    my $reg  = $self->registers;

    return ( $self->memory->[ $reg->{ pc }++ ] + $reg->{ x } ) & 0xff;
}

=head2 zero_page_y( )

Zero Page addressing, Y indexed. $00nn + Y.

=cut

sub zero_page_y {
    my $self = shift;
    my $reg  = $self->registers;

    return ( $self->memory->[ $reg->{ pc }++ ] + $reg->{ y } ) & 0xff;
}

=head2 indirect( )

Indirect Addressing. Special for JMP.

=cut

sub indirect {
    my $self = shift;
    my $reg  = $self->registers;
    my $mem  = $self->memory;

    my $lo = $mem->[ $reg->{ pc }++ ];
    my $hi = $mem->[ $reg->{ pc }++ ];
    my $temp = $self->make_word( $lo, $hi );
    my $pcl = $mem->[ $temp ];
    $lo++;
    $temp = $self->make_word( $lo, $hi );
    my $pch = $mem->[ $temp ];

    return $self->make_word( $pcl, $pch );
}

=head2 absolute( )

Absolute addressing. Fetches the next two memory slots and combines them into a
16-bit word.

=cut

sub absolute {
    my $self = shift;
    my $reg  = $self->registers;
    my $mem  = $self->memory;

    return $self->make_word( $mem->[ $reg->{ pc }++ ], $mem->[ $reg->{ pc }++ ] );
}

=head2 absolute_x( )

Absolute addressing, X indexed. Fetches the next two memory slots and combines them into a
16-bit word, then adds X.

=cut

sub absolute_x {
    my $self = shift;
    my $reg  = $self->registers;
    my $mem  = $self->memory;

    return $self->make_word( $mem->[ $reg->{ pc }++ ], $mem->[ $reg->{ pc }++ ] ) + $reg->{ x };

}

=head2 absolute_y( )

Absolute addressing, Y indexed. Fetches the next two memory slots and combines them into a
16-bit word, then adds Y.

=cut

sub absolute_y {
    my $self = shift;
    my $mem  = $self->memory;
    my $reg  = $self->registers;

    return $self->make_word( $mem->[ $reg->{ pc }++ ], $mem->[ $reg->{ pc }++ ] ) + $reg->{ y };
}

=head2 indirect_x( )

Indirect addressing, X indexed.

=cut

sub indirect_x {
    my $self = shift;
    my $mem  = $self->memory;
    my $reg  = $self->registers;

    my $hi = ( $self->memory->[ $reg->{ pc }++ ] + $reg->{ x } ) & 0xFF;
    return $self->make_word( $self->memory->[ $hi ], $self->memory->[ $hi + 1 ] );
}

=head2 indirect_y( )

Indirect addressing, Y indexed.

=cut

sub indirect_y {
    my $self = shift;
    my $mem  = $self->memory;
    my $reg  = $self->registers;

    my $hi = ( $self->memory->[ $reg->{ pc }++ ] + $reg->{ y } ) & 0xFF;
    return $self->make_word( $self->memory->[ $hi ], $self->memory->[ $hi + 1 ] );
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

=back

=cut

1;
