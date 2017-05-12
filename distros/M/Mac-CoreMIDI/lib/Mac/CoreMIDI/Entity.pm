package Mac::CoreMIDI::Entity;

use 5.006;
use strict;
use warnings;

use base qw(Mac::CoreMIDI::Object);
our $VERSION = '0.03';

sub GetSources {
    my ($self) = @_;

    my $numSources = $self->GetNumberOfSources();
    my @sources = map { $self->GetSource($_) } 0..$numSources-1;

    return @sources;
}

sub GetDestinations {
    my ($self) = @_;

    my $numDestinations = $self->GetNumberOfDestinations();
    my @destination = map { $self->GetDestination($_) } 0..$numDestinations-1;

    return @destination;
}

1;

__END__

=head1 NAME

Mac::CoreMIDI::Entity - Encapsulates a CoreMIDI Entity

=head1 METHODS

=over

=item C<my $dev = $self-E<gt>GetParent()>

Returns parent device for this entity.

=item C<my @src = $self-E<gt>GetSources()>

Returns a list of source endpoints for this entity.

=item C<my $n = $self-E<gt>GetNumberOfSources()>

Returns the number of sources.

=item C<my $src = $self-E<gt>GetSource($i)>

Returns the C<$i>'th source (starting from 0).

=item C<my @dest = $self-E<gt>GetDestinations()>

Returns a list of destination endpoints for this entity.

=item C<my $n = $self-E<gt>GetNumberOfDestinations()>

Returns the number of destinations.

=item C<my $dest = $self-E<gt>GetDestination($i)>

Returns the C<$i>'th destination (starting from 0).

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