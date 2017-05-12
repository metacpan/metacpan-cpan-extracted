package Games::NES::Emulator::PPU::Memory;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( memory palette name_table increment ) );

=head1 NAME

Games::NES::Emulator::PPU::Memory - NES VRAM

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 init()

=cut

sub init {
    my( $self ) = @_;
    $self->memory( [ (0) x ( 0x2000 + 1 ) ] );
    $self->palette( [ (0) x ( 0x20 + 1 ) ] );
    $self->name_table( [
        map { [ (0) x (0x400 + 1) ] } ( 0..3 )
    ] );
    $self->increment( 1 );
}

=head2 read( $addr, $spu_read )

=cut

sub read {
}

=head2 write( $addr => $data, $cpu_read )

=cut

sub write {
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Games::NES::Emulator::PPU>

=back

=cut

1;
