package DracPerl::Models::Abstract::VFlash;
use XML::Rabbit;

has_xpath_value 'id'       => './InstanceID';
has_xpath_value 'capacity' => './Capacity';
has_xpath_value 'name'     => './ComponentName';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::VFlash - Return information about VFlash slot

=head1 ATTRIBUTES

=head2 id

Dell ID for this VFlash card slot : 

eg : 'Disk.vFlashCard.1'

=head2 name

Name of the vFlash card. Error message if no card is inserted : 

eg : 'No SD Card'

=head2 capacity

Capacity of the card inserted, 'N/A' if no card is inserted

=cut