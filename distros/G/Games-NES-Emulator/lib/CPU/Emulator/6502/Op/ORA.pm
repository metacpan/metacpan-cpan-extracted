package CPU::Emulator::6502::Op::ORA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x09 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&ora,
    },
    0x05 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&ora,
    },
    0x15 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&ora,
    },
    0x0D => {
        addressing => 'absolute',
        cycles => 4,
        code => \&ora,
    },
    0x0D => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&ora,
    },
    0x19 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&ora,
    },
    0x01 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&ora,
    },
    0x11 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&ora,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::ORA - Logical OR memory with accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 ora( $addr )

Logical OR C<$addr> with the accumulator.

=cut

sub ora {
    my $self = shift;
    my $reg  = $self->registers;

    $reg->{ acc } |= $self->memory->[ shift ];
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
