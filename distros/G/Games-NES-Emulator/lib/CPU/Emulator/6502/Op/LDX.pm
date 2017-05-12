package CPU::Emulator::6502::Op::LDX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xA2 => {
        addressing => 'immediate',
        cycles => 2,
        code => \&ldx,
    },
    0xA6 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&ldx,
    },
    0xB6 => {
        addressing => 'zero_page_y',
        cycles => 4,
        code => \&ldx,
    },
    0xAE => {
        addressing => 'absolute',
        cycles => 4,
        code => \&ldx,
    },
    0xBE => {
        addressing => 'absolute_y',
        cycles => 4,
        code => \&ldx,
    },
};


=head1 NAME

CPU::Emulator::6502::Op::LDX - Load X register from memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 ldx( $addr )

Loads the X register from C<$addr>.

=cut

sub ldx {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ x } = $self->RAM_read( shift ) & 0xff;
    $self->set_nz( $reg->{ x } );
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
