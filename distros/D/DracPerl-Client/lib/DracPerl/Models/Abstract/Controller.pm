package DracPerl::Models::Abstract::Controller;
use XML::Rabbit;

has_xpath_value 'id'               => './InstanceID';
has_xpath_value 'name'             => './ProductName';
has_xpath_value 'firmware_version' => './ControllerFirmwareVersion';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::Controller - Information about a RAID controller

=head1 ATTRIBUTES

=head2 id

The DELL ID for this controller. 

eg : 'RAID.Slot.4-1'

=head2 name

Name/Model of this RAID Controller

eg : 'PERC H700 Integrated'

=head2 firmware_version

The Firmware Version of this RAID Controller

=cut