package CPU::Emulator::6502::Op::TSX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xBA => {
        cycles => 2,
        code   => \&tsx,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::TSX - Transfer the stack pointer to the X register

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 tsx( )

Transfers the stack pointer to the X register.

=cut

sub tsx {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ x } = $reg->{ sp };
    $self->set_nz( $reg->{ x } );
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
