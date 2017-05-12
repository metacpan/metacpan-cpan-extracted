package Mac::CoreMIDI::Device;

use 5.006;
use strict;
use warnings;

use base qw(Mac::CoreMIDI::Object);
our $VERSION = '0.03';

sub GetEntities {
    my ($self) = @_;

    my $numEntities = $self->GetNumberOfEntities();
    my @entities = map { $self->GetEntity($_) } 0..$numEntities-1;

    return @entities;
}

1;

__END__

=head1 NAME

Mac::CoreMIDI::Device - Encapsulates a CoreMIDI Device

=head1 METHODS

=over

=item C<my @ent = $self-E<gt>GetEntities()>

Returns a list of all entities for this device.

=item C<my $n = $self-E<gt>GetNumberOfEntities()>

Returns the number of entities.

=item C<my $dev = $self-E<gt>GetEntity($i)>

Returns the C<$i>'th entity (starting from 0).

=back

=head1 SEE ALSO

L<Mac::CoreMIDI>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 Christian Renz, E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut