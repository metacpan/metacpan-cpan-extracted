package DracPerl::Models::Commands::DellDefault::Batteries;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 41]/discreteSensorList/sensor' =>
    'DracPerl::Models::Abstract::DiscreteSensor';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::Batteries - Return the status of all batteries present on the system

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::DiscreteSensor>
(Where each DiscreteSensor is a battery)

=cut