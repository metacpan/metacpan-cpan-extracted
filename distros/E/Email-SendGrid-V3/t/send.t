#!/usr/bin/perl

use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Exception;

use Email::SendGrid::V3;

subtest 'Send tests' => sub {
    plan tests => 2;

    no strict 'refs';
    no warnings 'redefine';
    local *{'HTTP::Tiny::_request'} = sub {
        my ($self, $method, $url, $args) = @_;

        my $request = { headers => {} };

        # https://github.com/chansen/p5-http-tiny/blob/ce7583b7ea85abf69282f89746248c3a5e1e961a/lib/HTTP/Tiny.pm#L815
        if ( defined $args->{content} ) {
            if (ref $args->{content} eq 'CODE') {
                $request->{headers}{'content-type'} ||= "application/octet-stream";
                $request->{headers}{'transfer-encoding'} = 'chunked'
                    unless $request->{headers}{'content-length'}
                        || $request->{headers}{'transfer-encoding'};
                $request->{cb} = $args->{content};
            }
            elsif ( length $args->{content} ) {
                my $content = $args->{content};
                if ( $] ge '5.008' ) {
                    utf8::downgrade($content, 1)
                        or die(qq/Wide character in request message body\n/);
                }
                $request->{headers}{'content-type'} ||= "application/octet-stream";
                $request->{headers}{'content-length'} = length $content
                    unless $request->{headers}{'content-length'}
                        || $request->{headers}{'transfer-encoding'};
                $request->{cb} = sub { substr $content, 0, length $content, '' };
            }
            $request->{trailer_cb} = $args->{trailer_callback}
                if ref $args->{trailer_callback} eq 'CODE';
        }

        return {
            url => 'https://api.sendgrid.com/v3/mail/send',
            content => '',
            reason => 'Accepted',
            status => '202',
            success => 1,
            headers => {},
        };
    };

    subtest 'utf8' => sub {
        my $sg = Email::SendGrid::V3->new(api_key => 'XYZ123');
        my $message = $sg->from('nobody@example.com')
                         ->subject('A test message for you')
                         ->add_content('text/plain', 'こちらはテスト文言 sent with SendGrid.')
                         ->add_envelope(
                            to => [ 'somebody@example.com' ],
                         );

        is($message->send->{status}, '202', 'utf8 message structure ok');
    };

    subtest 'no utf8' => sub {
        my $sg = Email::SendGrid::V3->new(api_key => 'XYZ123');
        my $message = $sg->from('nobody@example.com')
                         ->subject('A test message for you')
                         ->add_content('text/plain', 'This is a test message sent sent with SendGrid.')
                         ->add_envelope(
                            to => [ 'somebody@example.com' ],
                         );

        is($message->send->{status}, '202', 'no utf8 message structure ok');
    };
};

done_testing;
