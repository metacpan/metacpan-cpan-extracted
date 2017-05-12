package CPU::Emulator::6502::Op::JSR;

use strict;
use warnings;

use constant INSTRUCTIONS => {
    0x20 => {
        addressing => 'absolute',
        cycles     => 6,
        code => \&jsr,
    }
};

=head1 NAME

CPU::Emulator::6502::Op::JSR - Jump and save the return address

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 jsr( $addr )

Save return address and jump to C<$addr>.

=cut

sub jsr {
    my $self = shift;
    my $addr = shift;
    my $reg = $self->registers;
    my $mem = $self->memory;

    $reg->{ pc }--;
    $self->push_stack( $self->hi_byte( $reg->{ pc } ) );
    $self->push_stack( $self->lo_byte( $reg->{ pc } ) );
    $reg->{ pc } = $addr;
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
