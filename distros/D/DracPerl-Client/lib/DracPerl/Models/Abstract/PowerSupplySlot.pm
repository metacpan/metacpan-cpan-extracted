package DracPerl::Models::Abstract::PowerSupplySlot;
use XML::Rabbit;

has_xpath_value 'id'               => './InstanceID';
has_xpath_value 'firmware_version' => './FirmwareVersion';
has_xpath_value 'manufacturer'     => './Manufacturer';
has_xpath_value 'part_number'      => './PartNumber';
has_xpath_value 'serial_number'    => './SerialNumber';
has_xpath_value 'model'            => './Model';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::PowerSupplySlot - Hardware info about power supply in slot

=head1 ATTRIBUTES

=head2 id

Dell ID for the power supply slot
eg : 'PSU.Slot.2'

=head2 manufacturer

Manufacturer of this power supply
eg : 'Dell'

=head2 model

The model of the power supply

Field seem to be padded to be 30 characters
eg : 'PWR SPLY,750W,RDNT,EMERSON    '

=head2 serial_number

The serial number of the PS

=head2 part_number

The exact part number of the power supply
eg : '0F613NA01'

=head2 firmware_version

The current firmware_version of the power supply
eg : 'Z1.0A.03'

=cut