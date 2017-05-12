package CPU::Emulator::6502::Op::RTI;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x40 => {
        cycles => 6,
        code => \&rti,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::RTI - Return from BRK/IRQ/NMI

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 rti( )

Return from BRK/IRQ/NMI.

=cut

sub rti {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ status } = $self->pop_stack;
    my $lo = $self->pop_stack;
    my $hi = $self->pop_stack;
    $reg->{ pc } = $self->make_word( $lo, $hi );
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
