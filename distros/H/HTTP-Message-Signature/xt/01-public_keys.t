use Test2::V0 -no_srand;
use Test2::Require::Internet qw( http-message-signatures-example.research.cloudflare.com 443 );

use HTTP::Request;
use HTTP::Message::Signature;

subtest "keys from quoted agent (live)" => sub {

    my $req = HTTP::Request->new(
        GET => 'http://example.com/robots.txt',
        [
            'Signature-Agent' => '"https://http-message-signatures-example.research.cloudflare.com"',
        ]
    );

    ok my $sig = HTTP::Message::Signature->new( message => $req, verify_public_keys => 1 );

    ok my $keys = $sig->public_keys, "public_keys";

};

done_testing;
