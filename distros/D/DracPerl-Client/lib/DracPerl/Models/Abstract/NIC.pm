package DracPerl::Models::Abstract::NIC;
use XML::Rabbit;

has_xpath_value 'id'                    => './InstanceID';
has_xpath_value 'name'                  => './ProductName';
has_xpath_value 'iscsi_mac_address'     => './PermanentiSCSIMACAddress';
has_xpath_value 'permanent_mac_address' => './PermanentMACAddress';
has_xpath_value 'current_mac_address'   => './CurrentMACAddress';

finalize_class();

1;

=head1 NAME

DracPerl::Models::Abstract::NIC - Network Interface Card

=head1 ATTRIBUTES

=head2 id

Dell ID for this NIC
eg : 'NIC.Embedded.2-1'

=head2 name

Model of the network card
(Sometimes along with the MAC Address)
eg : 'Broadcom NetXtreme II Gigabit Ethernet - FF:FF:FF:FF:FF:FF'

=head2 iscsi_mac_address

To be documented

eg : '00:00:00:00:00:00'

=head2 permanent_mac_address

The permanent, manufacturer given MAC Address :
eg : 'FF:FF:FF:FF:FF:FF'

=head2 current_mac_address

The current MAC address used on the network.
eg : 'FF:FF:FF:FF:FF:FF'

=cut