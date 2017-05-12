package CPU::Emulator::6502::Op::TAX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xAA => {
        cycles => 2,
        code => \&tax,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::TAX - Transfer the accumulator to the X register

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 tax( )

Transfers the accumulator to the X register.

=cut

sub tax {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ x } = $reg->{ acc };

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
