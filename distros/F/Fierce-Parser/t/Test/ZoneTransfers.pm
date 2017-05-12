#!/usr/bin/perl

package t::Test::ZoneTransfers;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $zt = $domain_obj->zone_transfers;

    is ( $zt->starttime, '1220494203', 'startscan');
    is ( $zt->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');
    is ( $zt->endtime, '1220494203', 'endscan');
    is ( $zt->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $zt->elapsedtime, '0', 'elasp');
}
1;
