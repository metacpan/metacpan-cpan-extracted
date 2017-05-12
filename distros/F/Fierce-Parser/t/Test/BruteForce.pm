#!/usr/bin/perl
# $Id: BruteForce.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::BruteForce;

use base 't::Test';
use Test::More;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $bf = $domain_obj->bruteforce;

    is ( $bf->starttime, '1220494203', 'startscan');
    is ( $bf->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');
    is ( $bf->endtime, '1220494203', 'endscan');
    is ( $bf->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $bf->elapsedtime, '0', 'elasp');

    my $session2 = $self->{parser2}->get_session();
    
    $domainscandetails = $session2->domainscandetails;
    @domains = @{ $domainscandetails->domains } ;
    $domain_obj = $domains[0];

    $bf = $domain_obj->bruteforce;

    my @nodes = @{$bf->nodes};
    my $node1 = $nodes[0];
    my $node2 = $nodes[1];
    my $node3 = $nodes[2];
    my $node4 = $nodes[3];
    is ( $node1->hostname, 'imap.test2.com' , 'node1 hostname: imap.test2.com');
    is ( $node2->hostname, 'www.test2.com' , 'node2 hostname: www.test2.com');
    is ( $node3->hostname, 'mail.test2.com' , 'node3 hostname: mail.test2.com');
    is ( $node4->hostname, 'files.test2.com' , 'node4 hostname: files.test2.com');

    is ( $node1->ip, '100.91.9.5' , 'node1 ip');
    is ( $node2->ip, '100.91.9.5' , 'node2 ip');
    is ( $node3->ip, '100.91.9.5' , 'node3 ip');
    is ( $node4->ip, '100.91.9.5' , 'node4 ip');
}
1;
