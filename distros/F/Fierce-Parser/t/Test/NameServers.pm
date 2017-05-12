#!/usr/bin/perl

package t::Test::NameServers;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $ns = $domain_obj->name_servers;

    is ( $ns->starttime, '1220494203', 'startscan');
    is ( $ns->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');
    is ( $ns->endtime, '1220494203', 'endscan');
    is ( $ns->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $ns->elapsedtime, '0', 'elasp');
}
1;
