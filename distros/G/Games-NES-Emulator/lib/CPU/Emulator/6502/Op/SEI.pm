package CPU::Emulator::6502::Op::SEI;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x78 => {
        cycles => 2,
        code => \&sei,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::SEI - Set the interrupt disable bit

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 sei( )

Sets the interrupt disable bit.

=cut

sub sei {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ status } |= CPU::Emulator::6502::SET_INTERRUPT;
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
