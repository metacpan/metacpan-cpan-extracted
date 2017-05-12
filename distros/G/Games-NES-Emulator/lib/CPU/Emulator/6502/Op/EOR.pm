package CPU::Emulator::6502::Op::EOR;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x49 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&eor,
    },
    0x45 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&eor,
    },
    0x55 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&eor,
    },
    0x4D => {
        addressing => 'absolute',
        cycles => 4,
        code => \&eor,
    },
    0x5D => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&eor,
    },
    0x59 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&eor,
    },
    0x41 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&eor,
    },
    0x51 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&eor,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::EOR - Exclusive OR memory with accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 eor( $addr )

Exclusive OR C<$addr> with the accumulator.

=cut

sub eor {
    my $self = shift;
    my $reg  = $self->registers;

    $reg->{ acc } ^= $self->memory->[ shift ];
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
