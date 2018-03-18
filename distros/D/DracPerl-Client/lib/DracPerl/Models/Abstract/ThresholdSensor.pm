package DracPerl::Models::Abstract::ThresholdSensor;
use XML::Rabbit;

has_xpath_value 'name'        => './name';
has_xpath_value 'reading'     => './reading';
has_xpath_value 'units'       => './units';
has_xpath_value 'status'      => './sensorStatus';
has_xpath_value 'min_warning' => './minWarning';
has_xpath_value 'max_warning' => './maxWarning';
has_xpath_value 'min_failure' => './minFailure';
has_xpath_value 'max_failure' => './maxFailure';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::ThresholdSensor - Sensors that can trigger warnings

=head1 ATTRIBUTES

=head2 name

Name of the sensor

=head2 reading

Current integer value of the sensor

eg : '1888'

=head2 units

The unit of the sensor

eg : 'RPM'

=head2 min_failure

The minimum reading value that will trigger an iDRAC failure
'N/A' if not set

=head2 max_failure

The maxium reading value that will trigger an iDRAC failure
'N/A' if not set

=head2 max_warning

The maxium reading value that will trigger an iDRAC warning
'N/A' if not set

=head2 min_warning

The minimum reading value that will trigger an iDRAC warning
'N/A' if not set

=head2 status

Current status of the sensor.
'Normal' / 'Critical'

=cut