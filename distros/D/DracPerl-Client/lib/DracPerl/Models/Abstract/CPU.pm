package DracPerl::Models::Abstract::CPU;
use XML::Rabbit;

has_xpath_value 'id'           => './InstanceID';
has_xpath_value 'model'        => './Model';
has_xpath_value 'manufacturer' => './Manufacturer';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::CPU - Information about a CPU

=head1 ATTRIBUTES

=head2 id

The DELL ID for this CPU. 

eg : 'CPU.Socket.1'

=head2 model

The full model name, along with the frequency

eg : 'Intel(R) Xeon(R) CPU E5530 @ 2.40GHz'

=head2 manufacturer

The manufacturer of the cpu

eg : 'Intel'

=cut