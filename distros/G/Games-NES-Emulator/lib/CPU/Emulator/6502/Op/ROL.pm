package CPU::Emulator::6502::Op::ROL;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x2A => {
        cycles => 2,
        code => \&rol_accumulator,
    },
    0x26 => {
        addressing => 'zero_page',
        cycles => 5,
        code => \&rol,
    },
    0x36 => {
        addressing => 'zero_page_x',
        cycles => 6,
        code => \&rol,
    },
    0x2E => {
        addressing => 'absolute',
        cycles => 6,
        code => \&rol,
    },
    0x3E => {
        addressing => 'absolute_x',
        cycles => 7,
        code => \&rol,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::ROL - Rotate left through carry

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 rol_accumulator( )

Rotate left through carry with accumulator.

=cut

sub rol_accumulator {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ acc } = $reg->{ acc } << 1;
    $reg->{ acc } |= 0x01 if $reg->{ status } & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;

    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $reg->{ acc } > 0xff;
    $reg->{ acc } &= 0xff;

    $self->set_nz( $reg->{ acc } );
}

=head2 rol( $addr )

Rotate left through carry with C<$addr>.

=cut

sub rol {
    my $self = shift;
    my $addr = shift;
    my $reg = $self->registers;

    my $temp = $self->memory->[ $addr ];
    $temp <<= 1;
    $temp |= 0x01 if $reg->{ status } & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;

    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp > 0xff;
    $temp &= 0xff;

    $self->set_nz( $temp );
    $self->RAM_write( $addr => $temp );
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
