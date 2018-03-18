package DracPerl::Models::Abstract::PhysicalDisk;
use XML::Rabbit;

has_xpath_value 'id' => './InstanceID';
has_xpath_value 'manufacturer' => './Manufacturer';
has_xpath_value 'serial_number' => './SerialNumber';
has_xpath_value 'model' => './Model';
has_xpath_value 'size_in_bytes' => './SizeInBytes';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::PhysicalDisk - Info about a disk

=head1 ATTRIBUTES

=head2 id

Dell ID for this disk
eg : 'Disk.Bay.1:Enclosure.Internal.0-0:RAID.Slot.4-1'

=head2 manufacturer

Manufacturer of this disk
Coming from SMART, so not 100% acurrate.

Field seem to be padded to be 8 characters.
eg : 'SEAGATE '
eg : 'ATA     '

=head2 model

The disk model/part number as coming from SMART

Field seem to be padded to be 16 characters
eg : 'SAMSUNG         '
eg : 'ST600MP0005     '

=head2 serial_number

The serial number of the disk if available
Fields seem to be padded to be 20 characters
(Exeception is when field is 'N/A')

eg : '12345678            '

=head2 size_in_bytes

The total size of the disk in bytes. (Along with the word ' Bytes')

eg : '599550590976 Bytes'

=cut