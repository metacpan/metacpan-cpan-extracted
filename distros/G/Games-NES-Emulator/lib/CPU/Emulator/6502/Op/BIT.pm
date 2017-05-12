package CPU::Emulator::6502::Op::BIT;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x24 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&bit,
    },
    0x2C => {
        addressing => 'absolute',
        cycles => 4,
        code => \&bit,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::BIT - Bit test

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 zero_page( )

=head2 absolute( )

=head2 bit( $addr )

Bit test with C<$addr>.

=cut

sub bit {
    my $self = shift;
    my $reg = $self->registers;

    my $temp = $self->RAM_read( shift );

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SOZ;
    $self->set_nz( $temp );
    $reg->{ status } |= CPU::Emulator::6502::SET_OVERFLOW if $temp & 0x40;
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
