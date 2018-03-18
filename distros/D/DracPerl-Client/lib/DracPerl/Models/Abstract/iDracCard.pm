package DracPerl::Models::Abstract::iDracCard;
use XML::Rabbit;

has_xpath_value 'id'               => './InstanceID';
has_xpath_value 'firmware_version' => './FirmwareVersion';
has_xpath_value 'model'            => './Model';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::iDracCard - Information about a DRAC Card

=head1 ATTRIBUTES

=head2 id

Dell ID for this DRAC Card
eg : 'iDRAC.Embedded.1'

=head2 firmware_version

DRAC Firmware Version

=head2 model

The type of iDRAC Card

eg : 'Express'

=cut