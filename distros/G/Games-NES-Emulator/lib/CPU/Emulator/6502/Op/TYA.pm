package CPU::Emulator::6502::Op::TYA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x98 => {
        cycles => 2,
        code   => \&tya,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::TYA - Transfer the Y register to the accumulator

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 tya( )

Transfers the Y register to the accumulator.

=cut

sub tya {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ acc } = $reg->{ y };
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
