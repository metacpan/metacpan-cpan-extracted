package CPU::Emulator::6502::Op::RTS;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x60 => {
        cycles => 6,
        code => \&rts,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::RTS - Return from subroutine

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 rts( )

Return from subroutine.

=cut

sub rts {
    my $self = shift;
    my $reg = $self->registers;

    my $lo = $self->pop_stack;
    my $hi = $self->pop_stack;

    $reg->{ pc } = $self->make_word( $lo, $hi );
    $reg->{ pc }++;
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
