package CPU::Emulator::6502::Op::BVC;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x50 => {
        cycles => 2,
        code   => \&bvc,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::BVC - Branch on overflow clear

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 bvc( )

Branches if the overflow flag is clear.

=cut

sub bvc {
    my $self = shift;
    my $reg = $self->registers;

    $self->branch_if( !($reg->{status} & CPU::Emulator::6502::SET_OVERFLOW) );
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
