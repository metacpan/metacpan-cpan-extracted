package CPU::Emulator::6502::Op::JMP;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x4C => {
        addressing => 'absolute',
        cycles => 3,
        code => \&jmp,
    },
    0x6C => {
        addressing => 'indirect',
        cycles => 5,
        code => \&jmp,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::JMP - Jump

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 jmp( $addr )

Jump to C<$addr>.

=cut

sub jmp {
    my $self = shift;
    $self->registers->{ pc } = shift;
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
