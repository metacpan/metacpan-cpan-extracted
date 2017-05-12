package CPU::Emulator::6502::Op::LDA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xA9 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&lda,
    },
    0xA5 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&lda,
    },
    0xB5 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&lda,
    },
    0xAD => {
        addressing => 'absolute',
        cycles => 4,
        code => \&lda,
    },
    0xBD => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&lda,
    },
    0xB9 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&lda,
    },
    0xA1 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&lda,
    },
    0xB1 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&lda,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::LDA - Load accumulator from memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 lda( $addr )

Loads the accumulator from C<$addr>.

=cut

sub lda {
    my $self = shift;
    my $reg = $self->registers;
    $reg->{ acc } = $self->RAM_read( shift ) & 0xff;
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
