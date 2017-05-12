package CPU::Emulator::6502::Op::TAY;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xA8 => {
        cycles => 2,
        code   => \&tay
    },
};

=head1 NAME

CPU::Emulator::6502::Op::TAY - Transfer the accumulator to the Y register

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 tay( )

Does the transfer of the accumulator to the Y register.

=cut

sub tay {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ y } = $reg->{ acc };
    $self->set_nz( $reg->{ y } );
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
