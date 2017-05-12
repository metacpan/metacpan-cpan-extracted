

package GlbDNS::Resolver::Base;
use strict;
use warnings;
use List::Util qw(shuffle);

use Geo::IP;
my $gi = Geo::IP->open_type( GEOIP_CITY_EDITION_REV1, GEOIP_STANDARD);

our %known_broken_servers = (
    # opendns chicago server
    '208.69.36.11' => { lat => '41.980905', lon => '-87.906654' },
    '208.69.36.12' => { lat => '41.980905', lon => '-87.906654' },
    '208.69.36.14' => { lat => '41.980905', lon => '-87.906654' },
    );



sub new {
    my $class = shift;
    return bless {}, $class
}


sub request {
    my ($self, $glbdns, $qname, $qclass, $qtype, $peerhost, $query) = @_;
    my ($rcode, $ans, $auth, $add) = (undef, [], [], []);
    my $response_incudes_ns = 0;

    $qname = lc($qname);

    my @query = split(/\./, $qname);

    # do a direct lookup here
    # should probably be a hook
    my $host = $glbdns->{hosts}->{$qname};

    # if the host doesnt know
    # try to find something in the tree that matches

    # xxx this needs wilcard support
    unless($host) {
        my $domain = $glbdns->get_host($qname);

	# if we find something, we find out the domain and return not found
        if ($domain) {
            $domain = $glbdns->{hosts}->{$domain->{__DOMAIN__}};
            return ("NXDOMAIN", [], $domain->{SOA}, [],{ aa => 1});
        }

	# we find nothing we refuse 
        return ("REFUSED", [], [], [],{ aa => 0});
    }

    # unclear why go through get_host again here
    my $domain = $glbdns->get_host($host->{domain});



    # if it is a ANY|CNAME|A|AAAA query and we have  CNAME we resolve the CNAME
    if (($qtype eq 'ANY' || $qtype eq 'CNAME' || $qtype eq 'A' || $qtype eq 'AAAA') && $host->{CNAME}) {
        push @$ans, $self->lookup($qname, "CNAME", $host, $peerhost);
	# CNAMES are only allowed to point to one resource
        $qname = $host->{CNAME}->[0]->cname;
        $host = $glbdns->{hosts}->{$qname};
    }

    # after we resolved the CNAME, we just continue

    if ($qtype eq 'ANY' || $qtype eq 'A' || $qtype eq 'PTR') {
        push @$ans, $self->lookup($qname, $qtype, $host, $peerhost);
    }

    if ($qtype eq 'ANY' || $qtype eq 'AAAA') {
        my @answer = $self->lookup($qname, $qtype, $host, $peerhost);
        # if we get a specific AAAA query
        # and this host exists (otherwise we wouldnt have come this far
        # then we have to return to SOA in auth 0 ANS and NO ERROR
        # RFC 4074 4.1 and 4.2

	# This probably applies for more things
	# should we be returning glue?
        if($qtype eq 'AAAA' && !@answer && !@$ans) {
            return ("NOERROR", [], [@{$domain->{SOA}}], [], { aa => 1 });
        }
	if($answer[0] && $answer[0]->type eq 'CNAME') {
	    push @$ans, $answer[0];
	}
    }



    if ($qtype eq 'ANY' || $qtype eq 'NS') {
        push @$ans, @{$domain->{NS}};
        $response_incudes_ns++;
    }
    if ($qtype eq 'ANY' || $qtype eq 'SOA') {
        push @$ans, @{$domain->{SOA}};
    }

    # XXX negative MX should probably be treated like AAAA
    if ($qtype eq 'ANY' || $qtype eq 'MX') {
	if($host->{MX}) {
	    push @$ans, @{$host->{MX}};
	    foreach my $mx (@{$host->{MX}}) {
		my $mx_host = $glbdns->get_host($mx->exchange);
		push @$add, $self->lookup($mx->exchange, "A", $mx_host, $peerhost);
	    }
	}
        if($qtype eq 'MX' && !@$ans) {
            return ("NOERROR", [], [@{$domain->{SOA}}], [], { aa => 1 });
        }
    }



    $auth = $domain->{NS} unless($response_incudes_ns);
    foreach my $ns (@{$domain->{NS}}) {
        my $ns_domain = $glbdns->get_host($ns->nsdname);
        if ($ns_domain) {
            push @$add, $self->lookup($ns->nsdname, "A", $ns_domain, $peerhost);
        }
    }


    $rcode = "NOERROR";

    return ($rcode, $ans, $auth, $add, { aa => 1 });
}

sub lookup {
    my $self = shift;
    my $qname = shift;
    my $qtype = shift;
    my $host = shift;
    my $peerhost = shift;
    my @answer;

    return unless $host;

    if (my $geo = $host->{__GEO__}) {
        my ($lat, $lon) = (undef,undef);
        if (exists($known_broken_servers{$peerhost})) {
            $GblDNS::counters{"Broken|$peerhost|$qname"}++;
            $lat = $known_broken_servers{$peerhost}->{lat};
            $lon = $known_broken_servers{$peerhost}->{lon};
        } else {
            my $record = $gi->record_by_addr($peerhost);
            if($record) {
                $lat = $record->latitude;
                $lon = $record->longitude;
            }
        }
        if (defined($lat)) {
            my %distance;
            foreach my $server (keys %$geo) {

                $distance{$server} = $self->distance($geo->{$server}->{lat}, $geo->{$server}->{lon}, $lat, $lon);
            }

            my @answer;
            foreach my $server (@{[sort { $distance{$a} <=> $distance{$b} } keys %distance ]}) {
                next if ($geo->{$server}->{radius} &&
                         $geo->{$server}->{radius} < $distance{$server});
                $GlbDNS::counters{"Location|$qname|$server"}++;
                foreach my $host (@{$geo->{$server}->{hosts}}) {
                    my $key = $host->type eq 'A' ? $host->address : $host->cname;
                    push @answer, $host if (!exists $GlbDNS::status{$key} || $GlbDNS::status{$key});

                }
                if(@answer) {
                    @answer = shuffle(@answer);
                    unshift @answer, $geo->{$server}->{source}->{$qname} if($geo->{$server}->{source}->{$qname});
                    return @answer;
                }
            }
        }
        $GlbDNS::counters{Failed_geo_look}++;
    }

    if ($qtype eq 'ANY') {
        push @answer, @{$host->{A}} if $host->{A};
        push @answer, @{$host->{AAAA}} if $host->{AAAA};
        push @answer, @{$host->{CNAME}} if $host->{CNAME};
    } else {
        push @answer, @{$host->{$qtype}} if ($host->{$qtype});
    }
    my @filtered;

    foreach my $answer (@answer) {
        my $key;
        if($answer->type eq 'A') {
            $key = $answer->address;
        } elsif($answer->type eq 'CNAME') {
            $key = $answer->cname;
        } else {
            push @filtered, $answer;
            next;
        }
        push @filtered, $answer if (!exists $GlbDNS::status{$key} || $GlbDNS::status{$key});
    }
    return @filtered if(@filtered); #only return the filtered list if it contains SOMETHING
    return @answer;
}


my $pi = atan2(1,1) * 4;
my $earth_radius = 6378;

sub distance {
    my ($self, $tlat, $tlon, $slat, $slon) = @_;

    my $tlat_r = int($tlat) * ($pi/180);
    my $tlon_r = int($tlon) * ($pi/180);
    my $slat_r = int($slat) * ($pi/180);
    my $slon_r = int($slon) * ($pi/180);

#    print "$tlat $tlon => $slat $slon\n";
#    print "$tlat_r $tlon_r => $slat_r $slon_r\n";

    my $delta_lat = $slat_r - $tlat_r;
    my $delta_lon = $slon_r - $tlon_r;

    my $temp = sin($delta_lat/2.0)**2 + cos($tlat_r) * cos($slat_r) * sin($delta_lon/2.0)**2;

    return (atan2(sqrt($temp),sqrt(1-$temp)) * 12756.32);
}





1;
