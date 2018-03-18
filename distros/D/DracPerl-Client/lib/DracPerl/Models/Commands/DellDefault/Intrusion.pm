package DracPerl::Models::Commands::DellDefault::Intrusion;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 5]/discreteSensorList/sensor' =>
    'DracPerl::Models::Abstract::DiscreteSensor';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::Intrusion - Return the status of intrusion sensors

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::DiscreteSensor>
(Where each DiscreteSensor is an intrusion sensor)

'reading' will be an english description of the sensor : 
eg 'Chassis is closed'

=cut