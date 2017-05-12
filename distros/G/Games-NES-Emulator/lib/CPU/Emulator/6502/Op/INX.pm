package CPU::Emulator::6502::Op::INX;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0xE8 => {
        cycles => 2,
        code => \&inx,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::INX - Increment the X registers

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 inx( )

Increments the X register by 1.

=cut

sub inx {
    my $self = shift;
    my $reg = $self->registers;

    $reg->{ x } = ( $reg->{ x } + 1 ) & 0xff;
    $self->set_nz( $reg->{ x } );
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
