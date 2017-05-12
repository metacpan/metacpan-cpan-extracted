package CPU::Emulator::6502::Op::CLV;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xB8 => {
        cycles => 2,
        code => \&clv
    }
};

=head1 NAME

CPU::Emulator::6502::Op::CLV - Clear overflow flag

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 clv( )

Clears the overflow flag.

=cut

sub clv {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ status } &= CPU::Emulator::6502::CLEAR_OVERFLOW;
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
