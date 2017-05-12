package GlbDNS::Resolver::ShowLocation;
use strict;
use warnings;
use List::Util qw(shuffle);
use Net::DNS::RR::TXT;
use Geo::IP;
my $gi = Geo::IP->open_type( GEOIP_CITY_EDITION_REV1, GEOIP_STANDARD);

sub new {
    my $class = shift;
    return bless {}, $class
}

sub request {
    my ($self, $glbdns, $qname, $qclass, $qtype, $peerhost, $query) = @_;
    $qname = lc($qname);
    if ($qname =~/glbdns-show-calling-location/) {
	my @ans;
	my $record = $gi->record_by_addr($peerhost);
	return ("NOERROR", [
                    Net::DNS::RR::TXT->new({
                        name => "$qname",
                        ttl  => 1,
                        class => "IN",
                        type  => "TXT",
                        txtdata => "LAT: " . $record->latitude . " LON: " . $record->longitude . "  CITY: " . $record->city})
                ], [], [],{ aa => 1});
    }
    return ();
}

1;
