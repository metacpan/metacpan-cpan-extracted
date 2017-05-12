#!/usr/bin/perl
# $Id: WhoisLookups.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::WhoisLookups;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $whois = $domain_obj->whois_lookup;

    is ( $whois->starttime, '', 'startscan');
    is ( $whois->starttimestr, '', 'startscanstr');
    is ( $whois->endtime, '', 'endscan');
    is ( $whois->endtimestr, '', 'endscanstr');
    is ( $whois->elapsedtime, '', 'elasp');
}
1;
