package Device::WallyHome;
use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

use List::Util qw(first);

our $VERSION = '0.21.3';

with 'Device::WallyHome::Role::Creator';
with 'Device::WallyHome::Role::REST';
with 'Device::WallyHome::Role::Validator';


#== ATTRIBUTES =================================================================

has 'places' => (
    is => 'lazy',
);


#== ATTRIBUTE BUILDERS =========================================================

sub _build_places {
    my ($self) = @_;

    my $placeList = $self->request({
        uri => 'places',
    });

    my $placeObjectList = [];

    foreach my $placeData (@$placeList) {
        push @$placeObjectList, $self->loadPlaceFromApiResponseData($placeData);
    }

    return $placeObjectList;
}


#== PUBLIC METHODS =============================================================

sub getPlaceById {
    my ($self, $placeId) = @_;

    $self->_checkRequiredScalarParam($placeId, 'placeId');

    return first { $_->id() eq $placeId } @{ $self->places() };
}

sub getPlaceByLabel {
    my ($self, $label) = @_;

    $self->_checkRequiredScalarParam($label, 'label');

    return first { $_->label() eq $label } @{ $self->places() };
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Device::WallyHome - WallyHome Device/Sensor REST API Interface

=head1 SYNOPSIS

    use Device::WallyHome;

    # Instantiate a new Device::WallyHome object, replace Token with actual Security Token
    my $wally = Device::WallyHome->new(
        token => 'f4379e51-222f-4def-8ee1-edf0b15be3b8',
    );

    # Retrieve a list (ArrayRef) of all places associated with your account
    my $places = $wally->places();

    # Load a new place via its unique identifier
    my $place = $wally->getPlaceById('qyWIClYakQX8TQxtFv1ypN6c');

    # Load a new place via its friendly label
    my $home = $wally->getPlaceByLabel('Home');

    # Retrieve a list (ArrayRef) of all Sensors associated with a place
    my $sensors = $home->sensors();

=head1 DESCRIPTION

B<Device::WallyHome> is the Perl5 interface into the WallyHome REST API.

WallyHome is a home sensing solution that detects and alerts you of water leaks,
changes in temperature and humidity, as well as when doors and windows open.
The WallyHome REST API provides an interface into the places and sensors
associated with a WallyHome account.

Device::WallyHome provides an object oriented interface wrapped around
the WallyHome REST API, designed to simplify integration for any associated
scripting needs.

The only information to get started with Device::WallyHome is the
Security Token that can be generated from the Account Settings page
within your WallyHome account.


=head2 Constructor

=over

=item B<new>

    use Device::WallyHome;

    my $wally = Device::WallyHome->new(
        token => 'f4379e51-222f-4def-8ee1-edf0b15be3b8',
    );

=over

=item token

The Security Token for your WallyHome account can be found or generated
from within the Account Settings page.  This security token is all that
is needed to successfully connect to the WallyHome REST API.


=back

=back


=head2 Methods

=over

=item B<places>

    my $places = $wally->places();

Returns a list of all places assoiated with the given WallyHome account.
Each place will be returned as a L<Device::WallyHome::Place> object.  If
no places are found, an empty list will be returned.

=item B<getPlaceById>

    my $place = $device->getPlaceById('qyWIClYakQX8TQxtFv1ypN6c');

Returns a single L<Device::WallyHome::Place> object matching the passed
place identifier.  If no matching place is found, C<undef> will be
returned.

=item B<getPlaceByLabel>

    my $home = $device->getPlaceByLabel('Home');

Returns a single L<Device::WallyHome::Place> object matching the passed
place label.  If no matching place is found, C<undef> will be
returned.

=back


=head1 EXAMPLES

=head2 Basic Examples

    # Iterate through a list of places, printing the identifier and label for each, typically only a single place
    foreach my $place (@$places) {
        printf("%s - %s\n", $place->id(), $place->label());
    }

    # Iterate through a list of sensors, printing the identifier (snid) and label for each
    foreach my $sensor (@$sensors) {
        printf("%s - %s\n", $sensor->snid(), $sensor->location()->room());
    }

=head2 Checking Sensor Data

    # Determine if Relative Humidity is within specified thresholds
    my $state     = $sensor->state('RH');
    my $threshold = $sensor->threshold('RH');

    my $currentValue = $state->value();
    my $min          = $threshold->min() // 0;
    my $max          = $threshold->max() // 999;

    if ($currentValue < $min || $currentValue > $max) {
        print "Danger, Will Robinson!\n";
    }

=head1 AUTHOR

Chris Hamilton


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Hamilton.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.


=head1 BUG REPORTING, ENHANCEMENT/FEATURE REQUESTS

Please report bugs or enhancement requests on GitHub directly at
L<https://github.com/cjhamil/Device-WallyHome/issues>

=cut
