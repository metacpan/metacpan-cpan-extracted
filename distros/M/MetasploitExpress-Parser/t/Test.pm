#!/usr/bin/perl
# $Id$
package t::Test;
use MetasploitExpress::Parser;
use MetasploitExpress::Parser::Session;
use MetasploitExpress::Parser::Host;
use MetasploitExpress::Parser::Report;
use MetasploitExpress::Parser::Service;
use MetasploitExpress::Parser::Task;
use MetasploitExpress::Parser::Event;
use MetasploitExpress::Parser::ScanDetails;

use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;

    if ( -r 't/test1.xml') {
        $self->{parser1} = MetasploitExpress::Parser->parse_file('t/test1.xml');
    }
    else {
        $self->{parser1} = MetasploitExpress::Parser->parse_file('test1.xml');
    }
}
1;
