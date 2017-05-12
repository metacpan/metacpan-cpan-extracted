package CPU::Emulator::6502::Op::BRK;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x00 => {
        cycles => 7,
        code => \&brk,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::BRK - Force break

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 brk( )

Force break.

=cut

sub brk {
    my $self = shift;
    my $reg = $self->registers;
    my $mem = $self->memory;

    $self->push_stack( $self->hi_byte( $reg->{ pc } + 1 ) );
    $self->push_stack( $self->lo_byte( $reg->{ pc } + 1 ) );

    $reg->{ status } |= CPU::Emulator::6502::SET_BRK;

    $self->push_stack( $reg->{ status } );

    $reg->{ pc } = $self->make_word( $mem->[ 0xfffe ], $mem->[ 0xffff ] );
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
