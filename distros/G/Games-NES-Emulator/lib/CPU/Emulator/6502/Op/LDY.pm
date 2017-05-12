package CPU::Emulator::6502::Op::LDY;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xA0 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&ldy,
    },
    0xA4 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&ldy,
    },
    0xB4 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&ldy,
    },
    0xAC => {
        addressing => 'absolute',
        cycles => 4,
        code => \&ldy,
    },
    0xBC => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&ldy,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::LDY - Load Y register from memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 ldy( $addr )

Loads the Y register from C<$addr>.

=cut

sub ldy {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ y } = $self->RAM_read( shift ) & 0xff;
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
