package CPU::Emulator::6502::Op::ROR;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x6A => {
        cycles => 2,
        code => \&ror_accumulator,
    },
    0x66 => {
        addressing => 'zero_page',
        cycles => 5,
        code => \&ror,
    },
    0x76 => {
        addressing => 'zero_page_x',
        cycles => 6,
        code => \&ror,
    },
    0x6E => {
        addressing => 'absolute',
        cycles => 6,
        code => \&ror,
    },
    0x7E => {
        addressing => 'absolute_x',
        cycles => 7,
        code => \&ror,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::ROR - Rotate right through carry

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 ror_accumulator( $addr )

Rotate left through carry with accumulator.

=cut

sub ror_accumulator {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ acc } |= 0x100 if $reg->{ status } & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_CARRY;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $reg->{ acc } & 1;

    $reg->{ acc } = $reg->{ acc } >> 1;

    $self->set_nz( $reg->{ acc } );
}

=head2 ror( $addr )

Rotate left through carry with C<$addr>.

=cut

sub ror {
    my $self = shift;
    my $addr = shift;
    my $reg = $self->registers;

    my $temp = $self->memory->[ $addr ];
    $temp |= 0x100 if $reg->{ status } & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_CARRY;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp & 1;

    $temp = $temp >> 1;

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
