#!/usr/bin/perl
# $Id: ReverseLookups.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::ReverseLookups;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $reverse = $domain_obj->reverse_lookups;

    is ( $reverse->starttime, '1220494203', 'startscan');
    is ( $reverse->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');
    is ( $reverse->endtime, '1220494203', 'endscan');
    is ( $reverse->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $reverse->elapsedtime, '0', 'elasp');
}
1;
