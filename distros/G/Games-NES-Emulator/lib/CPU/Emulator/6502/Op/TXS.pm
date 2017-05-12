package CPU::Emulator::6502::Op::TXS;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x9A => {
        cycles => 2,
        code   => \&txs,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::TXS - Transfer the X register to the stack pointer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 txs( )

Transfers the X registers to the stack pointer.

=cut

sub txs {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ sp } = $reg->{ x };
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
