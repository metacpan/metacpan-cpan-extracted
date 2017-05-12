package CPU::Emulator::6502::Op::SBC;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xE9 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&sbc,
    },
    0xE5 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&sbc,
    },
    0xF5 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&sbc,
    },
    0xED => {
        addressing => 'absolute',
        cycles => 4,
        code => \&sbc,
    },
    0xFD => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&sbc,
    },
    0xF9 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&sbc,
    },
    0xE1 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&sbc,
    },
    0xF1 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&sbc,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::SBC - Subtract memory from accumulator with borrow

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 sbc( $addr )

Subtract C<$addr> from the accumulator with borrow.

=cut

sub sbc {
    my $self = shift;
    my $reg  = $self->registers;

    my $val = $self->memory->[ shift ];
    my $temp = $reg->{ acc } - $val;
    $temp -= 1 if !$reg->{ status } & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_ZOCS;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp < 0x100;
                                
    if( (( $reg->{ acc } ^ $val ) & 0x80) and (($reg->{acc} ^ $temp ) & 0x80) ) {
        $reg->{ status } |= CPU::Emulator::6502::SET_OVERFLOW;
    }

    $reg->{ acc } = $self->temp & 0xff; 

    $self->set_nz( $reg->{ acc } );
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
