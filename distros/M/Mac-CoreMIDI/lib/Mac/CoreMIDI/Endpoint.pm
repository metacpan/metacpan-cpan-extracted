package Mac::CoreMIDI::Endpoint;

use 5.006;
use strict;
use warnings;

use base qw(Mac::CoreMIDI::Object);
our $VERSION = '0.04';

sub new_destination {
    my $class = shift;
    my %args = @_;

    return undef unless ref($args{client});
    $args{name} ||= 'Mac::CoreMIDI::Endpoint (Destination)';

    my $self = _new_destination($class, $args{client}, $args{name});

    return $self;
}

sub new_source {
    my $class = shift;
    my %args = @_;

    return undef unless ref($args{client});
    $args{name} ||= 'Mac::CoreMIDI::Endpoint (Source)';

    my $self = _new_source($class, $args{client}, $args{name});

    return $self;
}

sub _DESTROY {
    _destroy(shift);
}

sub Read {
    # subclass to use this function
}

1;

__END__

=head1 NAME

Mac::CoreMIDI::Endpoint - Encapsulates a CoreMIDI Endpoint

=head1 CONSTRUCTORS

=over 4

=item C<my $ep = Mac::CoreMIDI::Endpoint->new_source(name => '...', client => $client)

Creates a new source endpoint for the given client.

=item C<my $ep = Mac::CoreMIDI::Endpoint->new_destination(name => '...', client => $client)

Creates a new destination endpoint for the given client.

=back

=head1 METHODS

=over 4

=item C<my $ent = $ep-E<gt>GetParent()>

Returns parent entity for this endpoint.

=item C<$self-E<gt>Read()>

Subclass this function to do processing on read events.

=back

=head1 SEE ALSO

L<Mac::CoreMIDI>, L<Mac::CoreMIDI::Client>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 Christian Renz, E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut