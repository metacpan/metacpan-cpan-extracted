package CPU::Emulator::6502::Op::AND;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x29 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&and_op,
    },
    0x25 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&and_op,
    },
    0x35 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&and_op,
    },
    0x2D => {
        addressing => 'absolute',
        cycles => 4,
        code => \&and_op,
    },
    0x3D => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&and_op,
    },
    0x39 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&and_op,
    },
    0x21 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&and_op,
    },
    0x31 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&and_op,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::AND - Logical AND memory with accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 and_op( $addr )

Does a logical AND with data at C<$addr>.

=cut

sub and_op {
    my $self = shift;
    my $reg  = $self->registers;

    $reg->{ acc } &= $self->memory->[ shift ];
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
