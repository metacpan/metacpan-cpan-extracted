package CPU::Emulator::6502::Op::STX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x86 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&stx,
    },
    0x96 => {
        addressing => 'zero_page_y',
        cycles => 4,
        code => \&stx,
    },
    0x8E => {
        addressing => 'absolute',
        cycles => 4,
        code => \&stx,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::STX - Store the X register in memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 stx( $addr )

Stores the X register in memory address C<$addr>.

=cut

sub stx {
    my $self = shift;
    $self->RAM_write( shift, $self->registers->{ x } );
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
