package GlbDNS::Resolver::ShowServer;
use strict;
use warnings;
use List::Util qw(shuffle);

sub new {
    my $class = shift;
    return bless {}, $class
}

sub request {
    my ($self, $glbdns, $qname, $qclass, $qtype, $peerhost, $query) = @_;
    $qname = lc($qname);

    if ($qname =~/glbdns-show-calling-server/) {

	return ("NOERROR", [
                    Net::DNS::RR::A->new({
                        name => "$qname",
                        ttl  => 1,
                        class => "IN",
                        type  => "A",
                        address => $peerhost,
			rdlength => 0, })
                ], [], [],{ aa => 1});
    }
    return ();
}

1;
