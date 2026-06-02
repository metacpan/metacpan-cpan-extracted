package TestConnectivity;

use strict;
use warnings;

use Net::Ping;

# TCP/443 works for non-root users; ICMP would need privileges.
sub have_connection {
    my $p = Net::Ping->new('tcp', 1);
    $p->port_number(443);
    return $p->ping('api.opencagedata.com') ? 1 : 0;
}

1;
