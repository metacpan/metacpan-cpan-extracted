package CPU::Emulator::6502::Op::NOP;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xEA => {
        cycles => 2,
        code => \&nop,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::NOP - No operation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 nop( )

No operation.

=cut

sub nop {
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
