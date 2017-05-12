#!/usr/bin/perl
# $Id$
package t::Test;
use Fierce::Parser;
use Fierce::Parser::Session;
use Fierce::Parser::Node;
use Fierce::Parser::DomainScanDetails;

use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;

    if ( -r 't/test1.xml') {
        $self->{parser1} = Fierce::Parser->parse_file('t/test1.xml');
    }
    else {
        $self->{parser1} = Fierce::Parser->parse_file('test1.xml');
    }
    if ( -r 't/test2.xml'){
        $self->{parser2} = Fierce::Parser->parse_file('t/test2.xml');
    }
    else {
        $self->{parser2} = Fierce::Parser->parse_file('test2.xml');
    }
}
1;
