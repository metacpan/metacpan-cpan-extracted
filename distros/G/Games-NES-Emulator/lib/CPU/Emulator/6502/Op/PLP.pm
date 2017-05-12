package CPU::Emulator::6502::Op::PLP;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x28 => {
        cycles => 4,
        code   => \&plp,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::PLP - Pull processor status from the stack

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 plp( )

Pulls the processor status from the stack.

=cut

sub plp {
    my $self = shift;
    my $reg = $self->registers;

    $self->{ status } = $self->pop_stack;
    $self->{ status } |= CPU::Emulator::6502::SET_UNUSED;
    $self->{ status } |= CPU::Emulator::6502::CLEAR_BRK;
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
