package DracPerl::Models::Abstract::VideoCard;
use XML::Rabbit;

has_xpath_value 'id'           => './InstanceID';
has_xpath_value 'description'  => './Description';
has_xpath_value 'manufacturer' => './Manufacturer';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::VideoCard - Return information about a video card

=head1 ATTRIBUTES

=head2 id

Dell ID for this video card : 

eg : 'Video.Embedded.1-1'

=head2 description

Name of the video card

NOTE: The below example is NOT a typo, this is actually returned by iDRAC on a
PowerEdge R510.
Therefore, as this example shows, data might not be accurate
eg : 'PowerEdge R510 BCM5716 Gigabit Ethernet'

=head2 manufacturer

Manufacturer of the video card

eg : ' Matrox Electronics Systems Ltd.'

=cut