use strict;
use warnings;

use IO::File;

use Farly;
use Farly::ASA::Filter;
use Test::Simple tests => 2;

my $config = q{
hostname test_fw
name 192.168.10.0 net1
name 192.168.10.1 server1
banner motd a banner
interface Vlan2
 nameif outside
 security-level 0
 ip address 10.2.19.8 255.255.255.248 standby 10.2.19.9
 speed 100
 duplex full
object network test_fw_2
 host 192.168.5.219
object network internal_net
 subnet 10.1.2.0 255.255.255.0
object network citrix_net
 subnet 192.168.2.0 255.255.255.0
object network test_net1_range
 range 10.1.2.13 10.1.2.28
object service citrix
 service tcp destination eq 1494
 object service web_https
 service tcp source gt 1024 destination eq 443
object-group service NFS
 service-object 6 source eq 2046
 service-object 17 source eq 2046
object-group protocol layer4
 protocol-object tcp
 protocol-object udp
object-group network test_srv
 network-object host server1
object-group service web tcp
 port-object eq www
 port-object eq https 
object-group network test_net
 group-object test_srv
 network-object host 10.1.2.3
object-group network test_net
 description test network
 network-object 10.20.16.0 255.255.240.0
object-group service NFS
 service-object 6 destination eq 2046
object-group network customerX
 network-object 172.16.0.0 255.255.240.0
object-group service high_ports tcp-udp
 port-object range 1024 65535
object-group service www tcp
 group-object web
object-group network citrix_servers
 network-object host 192.168.2.1
 network-object host 192.168.2.2
 network-object host 192.168.2.3
object-group icmp-type ping
 icmp-object echo
 icmp-object echo-reply
access-list outside-in extended permit tcp object-group customerX range 1024 65535 host server1 eq 80
access-list outside-in extended permit tcp host server1 eq 1024 any eq 80
access-list outside-in extended permit tcp object-group customerX object-group high_ports host server1 eq 80
access-list outside-in extended permit object-group layer4 object-group customerX object-group high_ports host server1 eq 8080
access-list outside-in extended permit object citrix any object-group citrix_servers
access-list outside-in extended permit object-group layer4 object-group customerX object-group high_ports net1 255.255.255.0 eq 50234
access-list outside-in extended permit udp any range 1024 65535 host 192.168.10.1 gt 32768
access-list outside-in extended permit object citrix object internal_net object citrix_net
access-list outside-in extended permit icmp any any object-group ping
access-group outside-in in interface outside
logging enable
logging timestamp
logging buffered warnings
telnet timeout 5
ssh version 1
crypto map
tunnel-group
};

my $expected =  q{hostname test_fw
name 192.168.10.0 net1
name 192.168.10.1 server1
interface Vlan2
 nameif outside
 security-level 0
 ip address 10.2.19.8 255.255.255.248 standby 10.2.19.9
object network test_fw_2
 host 192.168.5.219
object network internal_net
 subnet 10.1.2.0 255.255.255.0
object network citrix_net
 subnet 192.168.2.0 255.255.255.0
object network test_net1_range
 range 10.1.2.13 10.1.2.28
object service citrix
 service tcp destination eq 1494
object service citrix
 service tcp source gt 1024 destination eq 443
object-group service NFS
 service-object 6 source eq 2046
object-group service NFS
 service-object 17 source eq 2046
object-group protocol layer4
 protocol-object tcp
object-group protocol layer4
 protocol-object udp
object-group network test_srv
 network-object host server1
object-group service web tcp
 port-object eq www
object-group service web tcp
 port-object eq https 
object-group network test_net
 group-object test_srv
object-group network test_net
 network-object host 10.1.2.3
object-group network test_net
 description test network
object-group network test_net
 network-object 10.20.16.0 255.255.240.0
object-group service NFS
 service-object 6 destination eq 2046
object-group network customerX
 network-object 172.16.0.0 255.255.240.0
object-group service high_ports tcp-udp
 port-object range 1024 65535
object-group service www tcp
 group-object web
object-group network citrix_servers
 network-object host 192.168.2.1
object-group network citrix_servers
 network-object host 192.168.2.2
object-group network citrix_servers
 network-object host 192.168.2.3
object-group icmp-type ping
 icmp-object echo
object-group icmp-type ping
 icmp-object echo-reply
access-list outside-in line 1 extended permit tcp OG_NETWORK customerX range 1024 65535 host server1 eq 80
access-list outside-in line 2 extended permit tcp host server1 eq 1024 any eq 80
access-list outside-in line 3 extended permit tcp OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 80
access-list outside-in line 4 extended permit OG_PROTOCOL layer4 OG_NETWORK customerX OG_SERVICE high_ports host server1 eq 8080
access-list outside-in line 5 extended permit object citrix any OG_NETWORK citrix_servers
access-list outside-in line 6 extended permit OG_PROTOCOL layer4 OG_NETWORK customerX OG_SERVICE high_ports net1 255.255.255.0 eq 50234
access-list outside-in line 7 extended permit udp any range 1024 65535 host 192.168.10.1 gt 32768
access-list outside-in line 8 extended permit object citrix object internal_net object citrix_net
access-list outside-in line 9 extended permit icmp any any OG_ICMP-TYPE ping
access-group outside-in in interface outside};

open(my $fh, '<', \$config) or die "Could not open string for reading";
bless $fh, 'IO::File';

my $filter = Farly::ASA::Filter->new();
$filter->set_file($fh);

my @array = $filter->run();

my $actual;
foreach my $line (@array) {
	$actual .= $line;
}
chomp $actual;

ok( $filter->isa('Farly::ASA::Filter'), "new" );

ok( $actual eq $expected , "filter");
