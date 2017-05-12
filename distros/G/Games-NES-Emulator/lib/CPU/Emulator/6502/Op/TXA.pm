package CPU::Emulator::6502::Op::TXA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x8A => {
        cycles => 2,
        code   => \&txa,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::TXA - Transfer the X register to the accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 txa( )

Transfers the X registers to the accumulator.

=cut

sub txa {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ acc } = $reg->{ x };
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
