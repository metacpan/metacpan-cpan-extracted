package CPU::Emulator::6502::Op::BNE;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xd0 => {
        cycles => 2,
        code   => \&bne,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::BNE - Branch on result not zero

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 bne( )

Branches when the result is not zero.

=cut

sub bne {
    my $self = shift;
    my $reg = $self->registers;

    $self->branch_if( !($reg->{status} & CPU::Emulator::6502::SET_ZERO) );
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
