use Test2::V0 -no_srand;

use HTTP::Request;
use HTTP::Message::Signature;
use Plack::Request;

subtest "base from headers" => sub {

    my $res = HTTP::Request->new(
        GET => 'http://example.com/robots.txt',
        [
            'Signature-Input' =>
'sig1=("@authority" "signature-agent");created=1794878989;expires=1794879049;keyid="VGVzdERhdGE=";alg="ed25519";tag="web-bot-auth"',
            'Signature-Agent' => '"https://example.com"',
            'Signature'       => 'sig1=:NEZha2U0RGF0YTQ=:',
        ]
    );

    ok my $sig = HTTP::Message::Signature->new( message => $res );

    ok my $base = $sig->_generate_signature_base('sig1'), '_generate_signature_base';

    is $base, "\"\@authority\": example.com
\"signature-agent\": \"https://example.com\"
\"\@signature-params\": (\"\@authority\" \"signature-agent\");created=1794878989;expires=1794879049;keyid=\"VGVzdERhdGE=\";alg=\"ed25519\";tag=\"web-bot-auth\"";

};

subtest "base from PSGI" => sub {

    my $env = {
        METHOD               => 'GET',
        PATH_INFO            => '/robots.txt',
        HTTP_HOST            => 'www.example.net',
        HTTP_SIGNATURE_AGENT => '"https://example.com"',
        HTTP_SIGNATURE_INPUT =>
'sig1=("@authority" "signature-agent");created=1794878989;expires=1794879049;keyid="VGVzdERhdGE=";alg="ed25519";tag="web-bot-auth"',
        HTTP_SIGNATURE => 'sig1=:NEZha2U0RGF0YTQ=:',
    };

    ok my $sig = HTTP::Message::Signature->new( message => $env );

    isa_ok $sig->message, 'Plack::Request';

    ok my $base = $sig->_generate_signature_base('sig1'), '_generate_signature_base';

    is $base, "\"\@authority\": www.example.net
\"signature-agent\": \"https://example.com\"
\"\@signature-params\": (\"\@authority\" \"signature-agent\");created=1794878989;expires=1794879049;keyid=\"VGVzdERhdGE=\";alg=\"ed25519\";tag=\"web-bot-auth\"";

};

done_testing;
