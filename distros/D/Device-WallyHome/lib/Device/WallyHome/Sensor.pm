package Device::WallyHome::Sensor;
use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

our $VERSION = '0.21.3';

with 'Device::WallyHome::Role::Creator';
with 'Device::WallyHome::Role::REST';
with 'Device::WallyHome::Role::Validator';


#== ATTRIBUTES =================================================================

has 'snid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_snid',
);

has 'offline' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    writer   => '_offline',
);

has 'paired' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_paired',
);

has 'updated' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_updated',
);

has 'alarmed' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_alarmed',
);

has 'signalStrength' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    writer   => '_signalStrength',
);

has 'recentSignalStrength' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    writer   => '_recentSignalStrength',
);

has 'hardwareType' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_hardwareType',
);

has 'location' => (
    is       => 'ro',
    isa      => 'Device::WallyHome::Sensor::Location',
    required => 1,
    writer   => '_location',
);

has 'thresholds' => (
    is => 'lazy',
);

has 'thresholdsByName' => (
    is       => 'ro',
    isa      => 'HashRef[Device::WallyHome::Sensor::Threshold]',
    required => 1,
    writer   => '_thresholds',
);

has 'states' => (
    is => 'lazy',
);

has 'statesByName' => (
    is       => 'ro',
    isa      => 'HashRef[Device::WallyHome::Sensor::State]',
    required => 1,
    writer   => '_state',
);

has 'activities' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    writer   => '_activities',
);


#== ATTRIBUTE BUILDERS =========================================================

sub _build_thresholds {
    my ($self) = @_;

    return [map { $self->thresholdsByName()->{$_} } sort keys %{ $self->thresholdsByName() }];
}

sub _build_states {
    my ($self) = @_;

    return [map { $self->statesByName()->{$_} } sort keys %{ $self->statesByName() }];
}

#== PUBLIC METHODS =============================================================

sub threshold {
    my ($self, $name) = @_;

    $self->_checkRequiredScalarParam($name, 'name');

    return $self->thresholdsByName->{$name} // undef;
}

sub state {
    my ($self, $name) = @_;

    $self->_checkRequiredScalarParam($name, 'name');

    return $self->statesByName->{$name} // undef;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Device::WallyHome::Sensor - WallyHome REST API Interface - Sensor

=head1 SYNOPSIS

    # A Device::WallyHome::Sensor will always be instantiated from a parent Device::WallyHome::Place object.
    use Device::WallyHome;

    my $wally = Device::WallyHome->new(
        token => 'f4379e51-222f-4def-8ee1-edf0b15be3b8',
    );

    my $place = $wally->getPlaceById('qyWIClYakQX8TQxtFv1ypN6c');

    my $sensor = $place->getSensorBySnid('90-7a-f1-ff-ff-ff');

    # Get sensor thresholds
    my $temperatureMin      = $sensor->threshold('TEMP')->min();
    my $temperatureMax      = $sensor->threshold('TEMP')->max();
    my $relativeHumidityMin = $sensor->threshold('RH')->min();
    my $relativeHumidityMax = $sensor->threshold('RH')->max();

    # Check sensor values
    my $currentTemperature      = $sensor->state('TEMP')->value();
    my $currentRelativeHumidity = $sensor->state('RH')->value();
    my $currentLeak             = $sensor->state('LEAK')->value();

=head1 DESCRIPTION

B<Device::WallyHome::Sensor> represents a child class of the L<Device::WallyHome>
Perl5 interface for the WallyHome REST API.

Device::WallyHome::Sensor objects are returned from various methods via
a parent L<Device::WallyHome::Place> object and are not intended to be instantiated
directly.


=head2 Methods

=over

=item B<thresholds>

    my $thresholds = $sensor->thresholds();

Returns a list of all thresholds associated with the given sensor.  Each
threshold returned is a L<Device::WallyHome::Threshold> object.

=item B<threshold (thresholdAbbreviation)>

    my $threshold = $sensor->threshold('TEMP');

Returns a single L<Device::WallyHome::Threshold> object matching the passed
threshold name.  The threshold name must be a valid value from the following list:

=over

=item B<RH> Relative Humidity

=item B<TEMP> Temperature

=back

=back

=over

=item B<states>

    my $states = $sensor->states();

Returns a list of all states associated with the given sensor.  Each
state returned is a L<Device::WallyHome::State> object.

=item B<state (stateAbbreviation)>

    my $state = $sensor->state('TEMP');

Returns a single L<Device::WallyHome::State> object matching the passed
state name.  The state name must be a valid value from the following list:

=over

=item B<RH> Relative Humidity

=item B<TEMP> Temperature

=item B<LEAK> Water Leak

=item B<SENSOR> Sensor

=item B<COND> Condition

=back

=back


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
