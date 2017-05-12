#!/usr/bin/perl
# $Id: Parser.pm 297 2009-11-16 04:37:07Z jabra $
package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    is ( $session1->options, ' -dns thisisjustfortestingfierce.com -format xml -output result.xml', 'options');
    is ( $session1->startscan, '1220494203', 'startscan');
    is ( $session1->startscanstr, 'Wed Sep  3 22:10:03 2008', 'startscanstr');

    is ( $session1->endscan, '1220494203', 'endscan');
    is ( $session1->endscanstr, 'Wed Sep  3 22:10:03 2008', 'endscanstr');
    is ( $session1->elapsedtime, '0', 'elapsedtime');
    is ( $session1->fversion, '2.0', 'fversion');
    is ( $session1->xmlversion, '1.0', 'xmlversion');
    
    my $domain_obj = $self->{parser1}->get_node('thisisjustfortestingfierce.com');
    is ( defined($domain_obj), 1, 'is defined for valid domain');
    is ( $domain_obj->domain, 'thisisjustfortestingfierce.com', 'domain');
    
    $domain_obj = $self->{parser1}->get_node('NOTVALID');
    is ( !defined($domain_obj), 1, 'is an invalid domain');
    
    my @nodes = $self->{parser1}->get_all_nodes();

    is (scalar(@nodes) == 1, 1, 'node list check');
    foreach(@nodes){
        is (ref($_), 'Fierce::Parser::Domain');
    }

}
1;
