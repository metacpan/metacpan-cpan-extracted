package CPU::Emulator::6502::Op::CPY;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xC0 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&cpy
    },
    0xC4 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&cpy
    },
    0xCC => {
        addressing => 'absolute',
        cycles => 4,
        code => \&cpy
    }
};

=head1 NAME

CPU::Emulator::6502::Op::CPY - Compare the Y register

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 cpy( $addr )

Compares the Y register to the data held at $addr.

=cut

sub cpy {
    my $self = shift;
    my $reg = $self->registers;
    
    my $temp = $reg->{ y } - $self->memory->[ shift ];
    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;
    $self->set_nz( $temp );
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp < 0x100;
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
