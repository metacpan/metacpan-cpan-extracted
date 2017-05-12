package Device::WallyHome::Place;
use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

use List::Util qw(first);

our $VERSION = '0.21.3';

with 'Device::WallyHome::Role::Creator';
with 'Device::WallyHome::Role::REST';
with 'Device::WallyHome::Role::Validator';


#== ATTRIBUTES =================================================================

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_id',
);

has 'accountId' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_accountId',
);

has 'label' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
    writer   => '_label',
);

has 'fullAddress' => (
    is       => 'ro',
    isa      => 'Maybe[HashRef]',
    required => 1,
    writer   => '_fullAddress',
);

has 'address' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
    writer   => '_address',
);

has 'suspended' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    writer   => '_suspended',
);

has 'buzzerEnabled' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    writer   => '_buzzerEnabled',
);

has 'sensorIds' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    writer   => '_sensorIds',
);

has 'nestAdjustments' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    writer   => '_nestAdjustments',
);

has 'nestEnabled' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    writer   => '_nestEnabled',
);

has 'rapidResponseSupport' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    writer   => '_rapidResponseSupport',
);

has 'sensors' => (
    is => 'lazy',
);


#== ATTRIBUTE BUILDERS =========================================================

sub _build_sensors {
    my ($self) = @_;

    my $newSensorIds     = [];
    my $sensorObjectList = [];

    my $sensorList = $self->request({
        uri => 'places/' . $self->id() . '/sensors'
    });

    foreach my $sensorData (@$sensorList) {
        my $sensor = $self->loadSensorFromApiResponseData($sensorData);

        push @$sensorObjectList, $sensor;

        push @$newSensorIds, $sensor->snid();
    }

    $self->_sensorIds($newSensorIds);

    return $sensorObjectList;
}


#== PUBLIC METHODS =============================================================

sub getSensorBySnid {
    my ($self, $snid) = @_;

    $self->_checkRequiredScalarParam($snid, 'snid');

    return first { $_->snid() eq $snid } @{ $self->sensors() };
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Device::WallyHome::Place - WallyHome REST API Interface - Place

=head1 SYNOPSIS

    # A Device::WallyHome::Place will always be instantiated from a base Device::WallyHome object.
    use Device::WallyHome;

    my $wally = Device::WallyHome->new(
        token => 'f4379e51-222f-4def-8ee1-edf0b15be3b8',
    );

    my $place = $wally->getPlaceById('qyWIClYakQX8TQxtFv1ypN6c');

    # Get a list (ArrayRef) of all sensors
    my $sensors = $place->sensors();

    # Get a single Device::WallyHome::Sensor object by Sensor ID (snid)
    my $sensor = $place->getSensorBySnid();

=head1 DESCRIPTION

B<Device::WallyHome::Place> represents a child class of the L<Device::WallyHome>
Perl5 interface for the WallyHome REST API.

Device::WallyHome::Place objects are returned from various methods via
a parent L<Device::WallyHome> object and are not intended to be instantiated
directly.


=head2 Methods

=over

=item B<sensors>

    my $sensors = $place->sensors();

Returns a list of all sensors associated with the given place.  Each
sensor returned is a L<Device::WallyHome::Sensor> object.

=item B<getSensorBySnid>

    my $sensor = $place->getSensorById('90-7a-f1-ff-ff-ff');

Returns a single L<Device::WallyHome::Sensor> object matching the passed
sensor identifier (snid).  If no matching sensor is found, C<undef> will
be returned.

=back


=head1 EXAMPLES

    # Iterate through a list of sensors, printing the identifier and current temperature for each
    foreach my $sensor (@$sensors) {
        printf("%s - %0.2f\n", $sensor->snid(), $sensor->state('TEMP')->value());
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
