#!/usr/bin/perl
# $Id: BruteForce.pm 14 2009-03-02 01:04:45Z jabra $
package t::Test::SubdomainBruteForce;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session2 = $self->{parser2}->get_session();
    my $domainscandetails = $session2->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $subdomain_bf = $domain_obj->subdomain_bruteforce;

    is ( $subdomain_bf->starttime, '1242762092', 'startscan');
    is ( $subdomain_bf->starttimestr, 'Tue May 19 15:41:32 2009', 'startscanstr');
    is ( $subdomain_bf->endtime, '1242762099', 'endscan');
    is ( $subdomain_bf->endtimestr, 'Tue May 19 15:41:39 2009', 'endscanstr');
    is ( $subdomain_bf->elapsedtime, '7', 'elasp');
    my @result = @{$subdomain_bf->nodes};
    my $node1 = $result[0];
    my $node2 = $result[1];
    is ( $node1->hostname, 'www.mail.yahoo.com' , 'www.mail.yahoo.com');
    is ( $node2->hostname, 'www.mail2.yahoo.com' , 'www.mail.yahoo.com');

}
1;
