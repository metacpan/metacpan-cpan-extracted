package Device::WallyHome::Role::Creator;
use Moose::Role;
use MooseX::AttributeShortcuts;

use Data::Dumper;
use Module::Loader;

our $VERSION = '0.21.3';


#== ATTRIBUTES =================================================================

has 'callbackObject' => (
    is       => 'ro',
    weak_ref => 1,
    writer   => '_callbackObject',
);


#== PUBLIC METHODS =============================================================

sub instantiateObject {
    my ($self, $class, $params) = @_;

    $params //= {};

    my $restApiRole = 'Device::WallyHome::Role::REST';

    # Dynamically load class module
    eval {
        (my $file = $class) =~ s/::/\//g;

        require $file . '.pm';

        $class->import();

        1;
    } or do {
        die "Failed to dynamically load class module ($class): " . $@;
    };

    # Pass along REST API information
    if (
           $self->does($restApiRole)
        && $class->does($restApiRole)
    ) {
        $params->{apiHostname}  //= $self->apiHostname();
        $params->{apiUseHttps}  //= $self->apiUseHttps();
        $params->{apiVersion}   //= $self->apiVersion();
        $params->{lastApiError} //= $self->lastApiError();
        $params->{token}        //= $self->token();
        $params->{timeout}      //= $self->timeout();
    }

    if ($self->_testModeIdentifier()) {
        $params->{_testModeIdentifier} = $self->_testModeIdentifier();
    }

    # Use ourself as the callback object
    $params->{callbackObject} = $self;

    Module::Loader->new()->load($class);

    my $obj = $class->new(%$params);

    die "Failed to instantiate object ($class): " . Dumper($params) unless defined $obj;

    return $obj;
}

sub loadPlaceFromApiResponseData {
    my ($self, $placeData) = @_;

    my $initData = {};

    # Non-Boolean Attributes
    foreach my $attribute (qw{
        id
        accountId
        label
        fullAddress
        address
        sensorIds
        nestAdjustments
        rapidResponseSupport
    }) {
        $initData->{$attribute} = $placeData->{$attribute};
    }

    # Boolean Attributes
    foreach my $attribute (qw{
        suspended
        buzzerEnabled
        nestEnabled
    }) {
        $initData->{$attribute} = $placeData->{$attribute} ? 1 : 0;
    }

    return $self->instantiateObject('Device::WallyHome::Place', $initData);
}

sub loadSensorFromApiResponseData {
    my ($self, $sensorData) = @_;

    my $initData = {};

    # Non-Boolean Attributes
    foreach my $attribute (qw{
        snid
        paired
        updated
        signalStrength
        recentSignalStrength
        hardwareType
        activities
    }) {
        $initData->{$attribute} = $sensorData->{$attribute};
    }

    # Boolean Attributes
    foreach my $attribute (qw{
        offline
        suspended
        alarmed
    }) {
        $initData->{$attribute} = $sensorData->{$attribute} ? 1 : 0;
    }

    $initData->{location} = $self->instantiateObject('Device::WallyHome::Sensor::Location', $sensorData->{location});

    $initData->{thresholdsByName} = {};

    foreach my $thresholdDataKey (keys %{ $sensorData->{thresholds} // {} }) {
        my $thresholdHref = $sensorData->{thresholds}->{$thresholdDataKey};

        my $thresholdData = {
            max  => $thresholdHref->{max},
            min  => $thresholdHref->{min},
            name => $thresholdDataKey,
        };

        $initData->{thresholdsByName}->{$thresholdDataKey} = $self->instantiateObject('Device::WallyHome::Sensor::Threshold', $thresholdData);
    }

    $initData->{statesByName} = {};

    foreach my $stateDataKey (keys %{ $sensorData->{state} // {} }) {
        my $stateHref = $sensorData->{state}->{$stateDataKey};

        my $stateData = {
            at    => $stateHref->{at},
            name  => $stateDataKey,
            value => $stateHref->{value},
        };

        $initData->{statesByName}->{$stateDataKey} = $self->instantiateObject('Device::WallyHome::Sensor::State', $stateData);
    }

    my $sensor = $self->instantiateObject('Device::WallyHome::Sensor', $initData);
}

1;
