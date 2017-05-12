package CPU::Emulator::6502::Op::ADC;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x69 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&adc,
    },
    0x65 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&adc,
    },
    0x75 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&adc,
    },
    0x6D => {
        addressing => 'absolute',
        cycles => 4,
        code => \&adc,
    },
    0x7D => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&adc,
    },
    0x79 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&adc,
    },
    0x61 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&adc,
    },
    0x71 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&adc,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::ADC - Add memory to accumulator with carry

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 adc( $addr )

Adds data at C<$addr> to the accumulator

=cut

sub adc {
    my $self = shift;
    my $mem  = $self->memory;
    my $reg  = $self->registers;

    my $val  = $mem->[ shift ];
    my $temp = $reg->{ acc } + $val;
    $temp += 1 if $reg->status & CPU::Emulator::6502::SET_CARRY;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_ZOCS;
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $self->temp > 0xFF;

    if( !( ( $reg->{ acc } ^ $val ) & 0x80 ) && ( ( $reg->{ acc } ^ $temp ) & 0x80 ) ) {
        $reg->{ status } |= CPU::Emulator::6502::SET_OVERFLOW;
    }

    $reg->{ acc } = $self->temp & 0xFF;

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
