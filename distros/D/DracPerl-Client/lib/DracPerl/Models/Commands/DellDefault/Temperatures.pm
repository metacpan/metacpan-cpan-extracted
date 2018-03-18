package DracPerl::Models::Commands::DellDefault::Temperatures;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 1]/thresholdSensorList/sensor' =>
    'DracPerl::Models::Abstract::ThresholdSensor';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::Temperatures - Return the reading of all temperature sensors

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::ThresholdSensor>
(Where each ThresholdSensor is a temperature sensor)

=cut