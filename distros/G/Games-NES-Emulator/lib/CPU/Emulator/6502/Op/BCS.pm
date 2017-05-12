package CPU::Emulator::6502::Op::BCS;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xB0 => {
        cycles => 2,
        code   => \&bcs,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::BCS - Branch on carry set

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 bcs( )

=cut

sub bcs {
    my $self = shift;
    my $reg = $self->registers;

    $self->branch_if( $reg->{status} & CPU::Emulator::6502::SET_CARRY );
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
