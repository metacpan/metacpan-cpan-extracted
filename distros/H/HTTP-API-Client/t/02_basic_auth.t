=head1 NAME

02_basic_auth.t - username/password produce a correctly base64-encoded
Basic Authorization header

=cut

use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);
use HTTP::API::Client;

my $api = HTTP::API::Client->new(
    username => "tester",
    password => "password",
);

my $expected = encode_base64('tester:password');

like $api->get('/testing', {}, {}, {test_request_object => 1})->as_string, qr/$expected/;

done_testing;
