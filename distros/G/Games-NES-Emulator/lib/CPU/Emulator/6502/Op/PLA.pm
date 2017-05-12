package CPU::Emulator::6502::Op::PLA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x68 => {
        cycles => 4,
        code => \&pla,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::PLA - Pull accumulator from the stack

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 pla( )

Pulls the accumulator from the stack.

=cut

sub pla {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ acc } = $self->pop_stack;
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
