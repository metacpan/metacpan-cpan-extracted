#!/usr/bin/perl
# $Id: ExtBruteForce.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::ExtBruteForce;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];

    my $extbf = $domain_obj->ext_bruteforce;

    is ( $extbf->starttime, '1220494203', 'startscan');
    is ( $extbf->starttimestr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');
    is ( $extbf->endtime, '1220494203', 'endscan');
    is ( $extbf->endtimestr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $extbf->elapsedtime, '0', 'elasp');

    my $session2 = $self->{parser2}->get_session();
    $domainscandetails = $session2->domainscandetails;
    @domains = @{ $domainscandetails->domains } ;
    $domain_obj = $domains[0];

    $extbf = $domain_obj->ext_bruteforce;
    is ( $extbf->starttime, '1221528444', 'startscan');
    is ( $extbf->starttimestr, 'Mon Sep 15 21:27:24 2008', 'startscanstr');
    is ( $extbf->endtime, '1221528445', 'endscan');
    is ( $extbf->endtimestr, 'Mon Sep 15 21:27:25 2008', 'endscanstr');
    is ( $extbf->elapsedtime, '1', 'elasp');
    my @result = @{$extbf->nodes};
    my $node1 = $result[0];
    my $node2 = $result[1];
    my $node3 = $result[2];
    my $node4 = $result[3];
    my $node5 = $result[4];
    is ( $node1->hostname, 'test2.com' , 'node1 hostname: test2.com');
    is ( $node2->hostname, 'test2.co.uk' , 'node2 hostname: metasploit.net');
    is ( $node3->hostname, 'test2.org' , 'node3 hostname: metasploit.org');
    is ( $node4->hostname, 'test2.net' , 'node4 hostname: metasploit.de');

    is ( $node1->ip, '100.91.9.5' , 'node1 ip: 100.91.9.5');
    is ( $node2->ip, '100.91.9.5' , 'node2 ip: 100.91.9.5');
    is ( $node3->ip, '100.91.9.5' , 'node3 ip: 100.91.9.5');
    is ( $node4->ip, '100.91.9.5' , 'node4 ip: 100.91.9.5');

}
1;
