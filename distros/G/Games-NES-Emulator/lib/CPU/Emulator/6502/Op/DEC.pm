package CPU::Emulator::6502::Op::DEC;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xC6 => {
        addressing => 'zero_page',
        cycles => 5,
        code => \&dec,
    },
    0xD6 => {
        addressing => 'zero_page_x',
        cycles => 6,
        code => \&dec,
    },
    0xCE => {
        addressing => 'absolute',
        cycles => 6,
        code => \&dec,
    },
    0xDE => {
        addressing => 'absolute_x',
        cycles => 7,
        code => \&dec,
    },
};


=head1 NAME

CPU::Emulator::6502::Op::DEC - Decrement by one

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 dec( $addr )

Decrements the value at C<$addr> by 1.

=cut

sub dec {
    my $self = shift;
    my $reg  = $self->registers;

    my $temp = $self->memory->[ shift ];
    $temp--;
    $self->RAM_write( $temp );
    $self->set_nz( $temp );
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
