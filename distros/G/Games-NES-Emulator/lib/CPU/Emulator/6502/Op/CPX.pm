package CPU::Emulator::6502::Op::CPX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xE0 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&cpx
    },
    0xE4 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&cpx
    },
    0xEC => {
        addressing => 'absolute',
        cycles => 4,
        code => \&cpx
    }
};

=head1 NAME

CPU::Emulator::6502::Op::CPX - Compare the X register

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 cpx( $addr )

Compares the X register to the data held at $addr.

=cut

sub cpx {
    my $self = shift;
    my $reg = $self->registers;
    
    my $temp = $reg->{ x } - $self->memory->[ shift ];
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
