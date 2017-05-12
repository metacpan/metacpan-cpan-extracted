#!/usr/bin/perl
# $Id: WildCard.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::WildCard;

use base 't::Test';
use Test::More;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $wc = $domain_obj->wildcard;

    is ( $wc->bool, 0, 'has wild card?');
    is ( $wc->starttime, '1220494203', 'startscan');
    is ( $wc->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscawctr');
    is ( $wc->endtime, '1220494203', 'endscan');
    is ( $wc->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscawctr');
    is ( $wc->elapsedtime, '0', 'elasp');

    my $session2 = $self->{parser2}->get_session();

    my $domainscandetails2 = $session2->domainscandetails;
    my @domains2 = @{ $domainscandetails2->domains } ;
    my $domain_obj2 = $domains2[0];

    my $wc2 = $domain_obj2->wildcard;

    is ( $wc2->bool, 1, 'has wild card?');

}
1;
