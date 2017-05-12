package CPU::Emulator::6502::Op::LSR;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x4A => {
        cycles => 2,
        code => \&lsr_accumulator,
    },
    0x46 => {
        addressing => 'zero_page',
        cycles => 5,
        code => \&lsr,
    },
    0x56 => {
        addressing => 'zero_page_x',
        cycles => 6,
        code => \&lsr,
    },
    0x4E => {
        addressing => 'absolute',
        cycles => 6,
        code => \&lsr,
    },
    0x5E => {
        addressing => 'absolute_x',
        cycles => 7,
        code => \&lsr,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::LSR - Shift right

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 lsr_accumulator( )

Shift the accumulator right.

=cut

sub lsr_accumulator {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $reg->{ acc } & 1;

    $reg->{ acc } >>= 1;

    $reg->{ status } |= CPU::Emulator::6502::SET_ZERO if $reg->{ acc } == 0;
}

=head2 lsr( $addr )

Shift data at C<$addr> right.

=cut
    
sub lsr {
    my $self = shift;
    my $addr = shift;
    my $reg = $self->registers;

    my $temp = $self->memory->[ $addr ];

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp & 1;

    $temp >>= 1;

    $reg->{ status } |= CPU::Emulator::6502::SET_ZERO if $temp == 0;

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
