#!/usr/bin/env perl;

use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use Test::More;
use Test::WWW::Mechanize::PSGI;

my $ua = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            [
                '<html><head><title>Hi</title></head><body>Hello World</body></html>'
            ]
        ];
    },
);
my $logger = debug_ua($ua);

# Test::WWW::Mechanize::PSGI overrides LWP::UserAgent::simple_request(), which
# is what would normally call LWP::UserAgent::send_request().  So, the default
# handlers used by LWP::ConsoleLogger::Easy (request_send) will never fire.  In
# this case we'll just manually add an additional callback to the object which
# will fire in the request_prepare phase, which is
# LWP::UserAgent::prepare_request().  That's earlier on in the request phase,
# but still helpful.

$ua->add_handler(
    'request_prepare',
    sub { $logger->request_callback(@_) }
);

$ua->get_ok('/');

done_testing();
