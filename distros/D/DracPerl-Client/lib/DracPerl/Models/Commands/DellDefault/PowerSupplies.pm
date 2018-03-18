package DracPerl::Models::Commands::DellDefault::PowerSupplies;
use XML::Rabbit::Root;

has_xpath_object_list 'list' =>
    '/root/sensortype[./sensorid = 8]/psSensorList/sensor' =>
    'DracPerl::Models::Abstract::PowerSupplySensor';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Commands::DellDefault::PowerSupplies - Return the status of all power supplies

=head1 ATTRIBUTES

=head2 list

An array of L<DracPerl::Models::Abstract::PowerSupplySensor>

=cut