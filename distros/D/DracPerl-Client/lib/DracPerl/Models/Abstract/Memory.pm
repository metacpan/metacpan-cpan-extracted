package DracPerl::Models::Abstract::Memory;
use XML::Rabbit;

has_xpath_value 'id'          => './InstanceID';
has_xpath_value 'part_number' => './PartNumber';
has_xpath_value 'model'       => './Model';
has_xpath_value 'size'        => './Size';
has_xpath_value 'speed'       => './Speed';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::Memory - Information about a memory stick

=head1 ATTRIBUTES

=head2 id

Dell ID for this memory stick
eg : 'DIMM.Socket.B3'

=head2 part_number

The exact model/part number for this memory stick

=head2 model

The type of memory

eg : 'DDR3 DIMM'

=head2 speed

Speed of this memory

eg : '1333 MHz'

=head2 size

eg : '4096 MB'

=cut