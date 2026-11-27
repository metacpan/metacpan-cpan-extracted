use v5.24;

use Test2::V0 -no_srand;
use Test2::Tools::Exception qw( lives );

use Data::Dumper;
use JSON::MaybeXS qw( decode_json );
use HTTP::Request;
use HTTP::Message::Signature;
use Path::Tiny   qw( path );
use PerlX::Maybe qw( maybe );
use String::Util qw( unquote );

use experimental qw( signatures );

# SPDX-FileCopyrightUrl: https://github.com/cloudflare/web-bot-auth/tree/main
# SPDX-License-Identifier: Apache-2.0

# https://github.com/cloudflare/web-bot-auth/blob/main/packages/web-bot-auth/test/test_data/web_bot_auth_architecture_v2.json
my $file = path( path(__FILE__)->parent, "web_bot_auth_architecture_v2.json" );
my $data = decode_json( $file->slurp_raw );

for my $case ( $data->@* ) {

    my $key = $case->{key};

    subtest $key->{kid} => sub {

        # skip_all "unsupported algorithm" unless $key->{kty} eq "OKP" && $key->{crv} eq "Ed25519";

        my $req = HTTP::Request->new(
            GET => $case->{target_url},
            [
                "signature"           => $case->{signature},
                "signature-input"     => $case->{signature_input},
                maybe "signature-agent"     => $case->{signature_agent},
                maybe "signature-agent-key" => $case->{signature_agent_key},
            ]
        );

        ok my $sig = HTTP::Message::Signature->new(
            message => $req,
            public_keys => { keys => [ $key ] },
            require_tag => 'web-bot-auth',
        );

        ok my ($label) = $sig->signature_labels, "got label";
        ok my $input = $sig->signature_input->get($label), "got input";
        ok my $keyid = $input->params->get("keyid")->value, "got keyid";

        $key->{kid} = unquote( $keyid );

        ok lives {
            ok $sig->verify, "verify"
                or note( explain($case) );
            ok !$sig->is_expired, "not expired";
        }, "verify did not throw an exception";

    };

}

done_testing;

sub explain($data) {
    return Data::Dumper->new([$data])->Terse(1)->Dump;
}
