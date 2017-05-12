package CPU::Emulator::6502::Op::CMP;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xC9 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&cmp,
    },
    0xC5 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&cmp,
    },
    0xD5 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&cmp,
    },
    0xCD => {
        addressing => 'absolute',
        cycles => 4,
        code => \&cmp,
    },
    0xDD => {
        addressing => 'absolute_x',
        cycles => 4,
        code => \&cmp,
    },
    0xD9 => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&cmp,
    },
    0xC1 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&cmp,
    },
    0xD1 => {
        addressing => 'indirect_y',
        cycles => 5,
        code => \&cmp,
    },
};


=head1 NAME

CPU::Emulator::6502::Op::CMP - Compare accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 cmp( $addr )

Compare the accumulator with C<$addr>.

=cut

sub cmp {
    my $self = shift;
    my $reg = $self->registers;

    my $temp = $reg->{ acc } - $self->memory->[ shift ];
    $reg->{ status } &= CPU::Emulator::6502::CLEAR_SZC;
    $self->set_nz( $temp );
    $reg->{ status } |= CPU::Emulator::6502::SET_CARRY if $temp < 0x100;
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
