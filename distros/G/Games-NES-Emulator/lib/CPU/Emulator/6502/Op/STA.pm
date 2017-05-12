package CPU::Emulator::6502::Op::STA;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x80 => {
        addressing => 'zero_page',
        cycles => 3,
        code => \&sta,
    },
    0x95 => {
        addressing => 'zero_page_x',
        cycles => 4,
        code => \&sta,
    },
    0x8D => {
        addressing => 'absolute',
        cycles => 4,
        code => \&sta,
    },
    0x9D => {
        addressing => 'absolute_x',
        cycles => 5,
        code => \&sta,
    },
    0x99 => {
        addressing => 'absolute_y',
        cycles => 5,
        code => \&sta,
    },
    0x81 => {
        addressing => 'indirect_x',
        cycles => 6,
        code => \&sta,
    },
    0x91 => {
        addressing => 'indirect_y',
        cycles => 6,
        code => \&sta,
    },
};

=head1 NAME

CPU::Emulator::6502::Op::STA - Store accumulator in memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 sta( $addr )

Stores the accumulator in memory address C<$addr>.

=cut

sub sta {
    my $self = shift;
    $self->RAM_write( shift, $self->registers->{ acc } );
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
