package CPU::Emulator::6502::Op::ASL;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x0A => {
        cycles => 2,
        code => \&asl_accumulator,
    },
    0x06 => {
        addressing => 'zero_page',
        cycles => 5,
        code => \&asl,
    },
    0x16 => {
        addressing => 'zero_page_x',
        cycles => 6,
        code => \&asl,
    },
    0x0E => {
        addressing => 'absolute',
        cycles => 6,
        code => \&asl,
    },
    0x1E => {
        addressing => 'absolute_x',
        cycles => 7,
        code => \&asl,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::ASL - Shift left

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 asl_accumulator( )

Shifts the accumulator left.

=cut

sub asl_accumulator {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_CARRY;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $reg->{ acc } & 0x80;

    $reg->{ acc } = ( $reg->{ acc } << 1 ) & 0xff;

    $self->set_nz( $reg->{ acc } );
}

=head2 asl( $addr )

Shift data at C<$addr> left.

=cut

sub asl {
    my $self = shift;
    my $addr = shift;
    my $reg = $self->registers;

    my $temp = $self->memory->[ $addr ];

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_CARRY;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp & 0x80;

    $temp = ( $temp << 1 ) & 0xff;

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
