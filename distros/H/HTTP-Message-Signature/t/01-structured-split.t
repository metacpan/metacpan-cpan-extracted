use Test2::V0;

use HTTP::Message::Signature;

*ssplit = \&HTTP::Message::Signature::_structured_split;

is [ ssplit( ';', 'a;b;c') ], [ "a", "b", "c" ];

is [ ssplit( ';', '"a;b";c;d') ], [ '"a;b"', "c", "d" ];

is [ ssplit( ';', '("a" "b";c=d);f;g') ], [ '("a" "b";c=d)', "f", "g" ];

is [ ssplit( ';', 't=("a" "b";c=d);f;g') ], [ 't=("a" "b";c=d)', "f", "g" ];

is [ ssplit( ';', 't=("a" "b";c="d");f;g') ], [ 't=("a" "b";c="d")', "f", "g" ];

is [ ssplit( ';', "sig2=(\"\@authority\" \"signature-agent\";key=\"agent2\");created=1735689600;keyid=\"poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U\";tag=\"web-bot-auth\"" ) ], [

    'sig2=("@authority" "signature-agent";key="agent2")',
    'created=1735689600',
    'keyid="poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U"',
    'tag="web-bot-auth"',
    ];

is [ ssplit( ';', '"signature-agent";key="agent1"') ], [ '"signature-agent"', 'key="agent1"' ];


done_testing;
