use Test2::V0 -no_srand;

use HTTP::Request;
use HTTP::Response;
use HTTP::Message::Signature;
use Plack::Request;

subtest "base from request headers" => sub {

    my $req = HTTP::Request->new(
        GET => 'http://example.com/robots.txt',
        [
            'Signature-Input' =>
'sig1=("@authority" "signature-agent");created=1794878989;expires=1794879049;keyid="VGVzdERhdGE=";alg="ed25519";tag="web-bot-auth"',
            'Signature-Agent' => '"https://example.com"',
            'Signature'       => 'sig1=:NEZha2U0RGF0YTQ=:',
        ]
    );

    ok my $sig = HTTP::Message::Signature->new( message => $req );

    ok my $base = $sig->_generate_signature_base( { label => 'sig1' } ), '_generate_signature_base';

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

    ok my $base = $sig->_generate_signature_base( { label => 'sig1' } ), '_generate_signature_base';

    is $base, "\"\@authority\": www.example.net
\"signature-agent\": \"https://example.com\"
\"\@signature-params\": (\"\@authority\" \"signature-agent\");created=1794878989;expires=1794879049;keyid=\"VGVzdERhdGE=\";alg=\"ed25519\";tag=\"web-bot-auth\"";

};

subtest "base from response headers" => sub {

    my $req = HTTP::Request->new(
        GET => "https://http-message-signatures-example.research.cloudflare.com/.well-known/http-message-signatures-directory"
    );

    my $res = HTTP::Response->new(
        200, "OK",
        [
            "content-type"   => "application/http-message-signatures-directory+json",
            "content-length" => 178,
            "signature" => "binding0=:ZhLpRMt0FEipj7HDM0U66fIt9MXio/pkXhRMp4DMkbLpCwq0GZWMYLc3jIkPQEsO5wrwfp/qNntQ4WDcnkaqBw==:",
            "signature-input" =>
'binding0=("@authority";req);created=1795807676;keyid="poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U";alg="ed25519";expires=1795807976;tag="http-message-signatures-directory"',
        ],
'{"keys":[{"kid":"poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U","kty":"OKP","crv":"Ed25519","x":"JrQLj5P_89iXES9-vFgrIy29clF9CC_oPPsw3c5D0bs","nbf":1743465600000}],"purpose":"rag"',
    );

    ok my $sig = HTTP::Message::Signature->new(
        request  => $req,
        response => $res,
    );

    ok $sig->is_response, "is_response";

    ok my $base = $sig->_generate_signature_base( { label => 'binding0' } ), '_generate_signature_base';

    is $base, "\"\@authority\";req: http-message-signatures-example.research.cloudflare.com
\"\@signature-params\": (\"\@authority\";req);created=1795807676;keyid=\"poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U\";alg=\"ed25519\";expires=1795807976;tag=\"http-message-signatures-directory\"";

    # ok $sig->verify( { request => $req, check_expires => 0 } );

};


done_testing;
