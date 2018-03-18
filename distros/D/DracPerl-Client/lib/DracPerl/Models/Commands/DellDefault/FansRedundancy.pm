package DracPerl::Models::Commands::DellDefault::FansRedundancy;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 256]/discreteSensorList/sensor' =>
    'DracPerl::Models::Abstract::DiscreteSensor';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::FansRedundancy - Return the status of all redundancy policy for fans

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::DiscreteSensor>
(Where each DiscreteSensor is a fan redundancy policy)

=cut