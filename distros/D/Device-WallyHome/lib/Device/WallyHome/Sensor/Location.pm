package Device::WallyHome::Sensor::Location;
use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

our $VERSION = '0.21.3';


#== ATTRIBUTES =================================================================

has 'id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_id',
);

has 'placeId' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_placeId',
);

has 'sensorId' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_sensorId',
);
has 'room' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_room',
);
has 'appliance' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    writer   => '_appliance',
);
has 'floor' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    writer   => '_floor',
);
has 'functionalType' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    writer   => '_functionalType',
);
has 'created' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_created',
);
has 'updated' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_updated',
);


__PACKAGE__->meta->make_immutable;

1;
