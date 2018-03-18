package DracPerl::Models::Abstract::PowerSupplySensor;
use XML::Rabbit;

has_xpath_value 'location'      => './location';
has_xpath_value 'input_wattage' => './inputWattage';
has_xpath_value 'max_wattage'   => './maxWattage';
has_xpath_value 'fw_version'    => './fwVersion';
has_xpath_value 'status'        => './sensorStatus';
has_xpath_value 'online_status' => './onlineStatus';
has_xpath_value 'type'          => './type';

finalize_class();

1;


=head1 NAME

DracPerl::Models::Abstract::PowerSupplySensor - Return information about a power supply

=head1 ATTRIBUTES

=head2 location

Which Power Supply slot this sensor is for

eg : 'PS 1 '

=head2 input_wattage

Watts in input of the power supply

eg : '972'

=head2 max_wattage

The maximum output wattage of the power supply

eg : '750'

=head2 fw_version

The firmware version of the power supply

eg : 'Z1.0A.03'

=head2 status

Current health status of the power supply

'Normal'/ 'Critical'

=head2 online_status

Info message on the current health

eg : 'Present'

=head2 type

The current type of the power supply

eg : 'AC'

=cut