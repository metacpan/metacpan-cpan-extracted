#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Exception;

use Email::SendGrid::V3;
use JSON;

subtest 'Payload tests' => sub {
    plan tests => 2;

    my $sg = Email::SendGrid::V3->new;

    my $message = $sg->from('nobody@example.com')
                     ->subject('A test message for you')
                     ->add_content('text/plain', 'This is a test message sent with SendGrid.')
                     ->add_envelope(
                        to => [ 'somebody@example.com' ],
                     );

    my $expected = {
        from => { email => 'nobody@example.com' },
        subject => 'A test message for you',
        personalizations => [
            { to => [ { email => 'somebody@example.com' } ] },
        ],
        content => [ {
            type => 'text/plain',
            value => 'This is a test message sent with SendGrid.',
        } ],
    };

    my $expected_json = JSON->new->canonical->encode($expected);

    is($message->_payload, $expected_json, "Basic message structure ok");

    $message->add_envelope( to => 'bill@example.com' );
    $message->add_envelope( to => { email => 'jack@example.com' } );
    $message->add_envelope( to => [ 'tom@example.com', { email => 'larry@example.com', name => 'Larry' } ] );

    $expected->{personalizations} = [
        { to => [ {email => 'somebody@example.com'} ] },
        { to => [ {email => 'bill@example.com'} ] },
        { to => [ {email => 'jack@example.com'} ] },
        { to => [ {email => 'tom@example.com'},
                  {email => 'larry@example.com', name => 'Larry' } ] },
    ];

    $expected_json = JSON->new->canonical->encode($expected);

    is($message->_payload, $expected_json, "Additional recipients handled correctly");
};

done_testing;
