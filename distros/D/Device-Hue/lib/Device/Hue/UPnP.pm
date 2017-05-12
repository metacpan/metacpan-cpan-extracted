package Device::Hue::UPnP;
{
  $Device::Hue::UPnP::VERSION = '0.4';
}

use strict;
use warnings;

use Carp;
use IO::Select;
use IO::Socket::Multicast;

sub upnp
{
	my $addr = '239.255.255.250';
	my $port = 1900;

	my $sock = IO::Socket::Multicast->new(
		'LocalPort'	=> $port,
		'ReuseAddr'	=> 1,
	) or croack();

	$sock->mcast_add($addr);
	$sock->mcast_loopback(0);

	my $sel = new IO::Select;

        $sel->add($sock);

       my $q = <<EOT;
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
ST: urn:schemas-upnp-org:device:basic:1
MX: 0

EOT

	$q =~ s/\n/\r\n/g;

	$sock->mcast_send($q, $addr . ':' . $port);

	my %devices;

	while (1) {

		my @ready = $sel->can_read(2);
		last unless scalar @ready;

		my $data;
		$sock->recv($data, 4096);

		# dirty hack
		if ($data =~ /uuid:2f402f80-da50-11e1-9b23/m) {
			
			if ($data =~ m'LOCATION: http://([\d\.]+):80/description.xml'm) {
				$devices{$1} = 1;
			}
		}
	}

	return [keys %devices];
}

1;

=pod

=head1 NAME

Device::Hue::UPnP

=head1 VERSION

version 0.4

=head1 AUTHOR

Alessandro Zummo <a.zummo@towertech.it>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alessandro Zummo.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

__END__
HTTP/1.1 200 OK
CACHE-CONTROL: max-age=100
EXT:
LOCATION: http://192.168.2.4:80/description.xml
SERVER: FreeRTOS/6.0.5, UPnP/1.0, IpBridge/0.1
ST: upnp:rootdevice
USN: uuid:2f402f80-da50-11e1-9b23-00171809c4a1::upnp:rootdevice
