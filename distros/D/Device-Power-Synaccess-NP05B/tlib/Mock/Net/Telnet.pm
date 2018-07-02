package Mock::Net::Telnet;

use strict;
use warnings;

sub new   {
    return bless(
        { opt_hr => $_[1] // {},
          pstat  => [0, 0, 0, 0, 0]
        },
        'Mock::Net::Telnet'
    );
}
sub open  { $_[0]->{addr} = $_[1]; }
sub close { delete $_[0]->{addr}; }
sub cmd  {
    my ($self, $cmd) = @_;
    return 'HW3.2 FW95 WF88' if ($cmd eq 'ver');
    return 'Goodbye!' if ($cmd eq 'logout');

    if ($cmd eq 'pshow') {
        my $header = "\rPort | Name       |Status";
        my $body   = "\r";
        for (my $i = 1; $i <= 5; $i++) {
            my $on_or_off = $self->{pstat}->[$i-1] ? 'ON' : 'OFF';
            $body .= "   $i |    Outlet$i |   $on_or_off |";
        }
        return ($header, $body);
    }
    if ($cmd =~ /^pset\s+(\d+)\s+(\d+)/ && $1 <= 5) {
        $self->{pstat}->[$1-1] = $2 ? 1 : 0;
        return ('', '');
    }
    if ($cmd eq 'sysshow') {
        return (
            "Active network info:",
            "IP-Mask-GW:192.168.1.100-255.255.0.0-192.168.1.1",
            "Static IP/Mask/Gateway : 192.168.1.100-255.255.0.0-192.168.1.1",
            "Ethernet Port is ON",
            "HTTP/Telnet Port #s: 80/23",
            "",
            "MAC Address : 00:90:c2:34:56:78",
            "Designated Source IP:",
            "0.0.0.0",
            "Outlet Status(1-On, 0-Off. Outlet 1 to 5): 0 0 0 0 0"
        );
    }
    
    return '';
}
sub print { return; }

1;
