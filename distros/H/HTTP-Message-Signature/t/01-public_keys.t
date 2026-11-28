use Test2::V0 -no_srand;
use Test2::Tools::Warnings qw/warning no_warnings/;

use HTTP::Request;
use HTTP::Message::Signature;
use JSON qw( encode_json );

subtest "max_keys" => sub {

    my $res = HTTP::Request->new( GET => 'http://example.com/robots.txt' );

    my @keys = map {
        {
            "kty" => "OKP",
            "crv" => "Ed25519",
            "kid" => "test-key-ed25519-" . $_,
            "d"   => "n4Ni-HpISpVObnQMW0wOhCKROaIKqKtW_2ZYb2p9KcU",
            "x"   => "JrQLj5P_89iXES9-vFgrIy29clF9CC_oPPsw3c5D0bs"
        },
    } ( 1 .. 10 );

    my $json = encode_json( { keys => \@keys } );

    ok(
        no_warnings {
            my $sig = HTTP::Message::Signature->new( message => $res, public_keys_json => $json );
            ok $sig->public_keys, "got public_keys";
            is scalar( $sig->public_keys->{keys}->@* ), 10, "got all 10 keys";
            ok $sig->max_keys >= 10, "max_keys";
        },
        "keys not truncated"
    );

    like(
        warning {
            my $sig = HTTP::Message::Signature->new( message => $res, public_keys_json => $json, max_keys => 5 );
            ok $sig->public_keys, "got public_keys";
            is scalar( $sig->public_keys->{keys}->@* ), $sig->max_keys, "number of keys <= max_keys";
            is $sig->max_keys => 5 , "max_keys";
        },
        qr/public_keys truncated to the first 5 keys/,
        "not truncated"
    );

};

done_testing;
