package Device::WallyHome::Sensor::State;
use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

our $VERSION = '0.21.3';


#== ATTRIBUTES =================================================================

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_name',
);

has 'value' => (
    is       => 'ro',
    isa      => 'Maybe[Num]',
    required => 1,
    writer   => '_min',
);

has 'at' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_max',
);


__PACKAGE__->meta->make_immutable;

1;
