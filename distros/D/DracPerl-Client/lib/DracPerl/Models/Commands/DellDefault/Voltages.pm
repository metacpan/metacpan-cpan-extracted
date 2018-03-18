package DracPerl::Models::Commands::DellDefault::Voltages;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 2]/discreteSensorList/sensor' =>
    'DracPerl::Models::Abstract::DiscreteSensor';

finalize_class();

1;


=head1 NAME

DracPerl::Models::Commands::DellDefault::Temperatures - Return the reading of all voltages sensors

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::DiscreteSensor>
(Where each DiscreteSensor is a voltage sensor)

=cut