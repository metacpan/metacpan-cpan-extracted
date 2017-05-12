#!/usr/bin/perl
# $Id: Domain.pm 45 2009-03-03 03:58:29Z jabra $
package t::Test::Domain;

use base 't::Test';
use Test::More;
use Fierce::Parser;
use Fierce::Parser::Session;
use Fierce::Parser::Node;
use Fierce::Parser::DomainScanDetails;

use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();
    my $domainscandetails = $session1->domainscandetails;
    my @domains = @{ $domainscandetails->domains } ;
    my $domain_obj = $domains[0];
    is ( $domain_obj->domain, 'thisisjustfortestingfierce.com', 'domain');
}
1;
