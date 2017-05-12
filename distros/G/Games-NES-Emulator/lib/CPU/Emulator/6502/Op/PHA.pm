package CPU::Emulator::6502::Op::PHA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x48 => {
        cycles => 3,
        code   => \&pha,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::PHA - Push accumulator on the stack

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 pha( )

Pushes the accumulator onto the stack

=cut

sub pha {
    my $self = shift;
    my $reg = $self->registers;

    $self->push_stack( $reg->{ acc } );
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
