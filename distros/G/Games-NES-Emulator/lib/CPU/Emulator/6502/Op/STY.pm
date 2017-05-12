package CPU::Emulator::6502::Op::STY;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x84 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&sty,
    },
    0x94 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&sty,
    },
    0x8c => {
        addressing => 'absolute',
        cycles => 4,
        code => \&sty,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::STY - Store the Y register in memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 sty( $addr )

Stores the Y register in memory address C<$addr>.

=cut

sub sty {
    my $self = shift;
    $self->RAM_write( shift, $self->registers->{ y } );
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
