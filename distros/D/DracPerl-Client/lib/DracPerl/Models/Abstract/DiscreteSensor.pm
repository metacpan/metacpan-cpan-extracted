package DracPerl::Models::Abstract::DiscreteSensor;
use XML::Rabbit;

has_xpath_value 'name'    => './name';
has_xpath_value 'reading' => './reading';
has_xpath_value 'status'  => './sensorStatus';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::DiscreteSensor - A sensor returning arbitrary data

=head1 SYNOPSIS

DiscreteSensor are often plain english representating a state.
For example : Voltage correct, No chassis intrusion, good fan redundancy

=head1 ATTRIBUTES

=head2 name

The name of the sensor
eg : 'CPU1 0.75 VTT PG'
eg : 'system board Intrusion'

=head2 reading

The current state of the sensor. 
eg : 'Good'
eg : 'Chassis is closed'

=head2 status

The current status of the sensor : 

'Normal' or 'Critical'

=cut