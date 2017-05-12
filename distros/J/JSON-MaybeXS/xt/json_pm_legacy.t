use warnings;
use strict;
use Test::More;

# some tests to check JSON::PP versus JSON::MaybeXS for legacy methods

unless ( eval { require JSON; 1 }) {
    plan skip_all => 'No JSON';
}

use JSON::MaybeXS qw/:legacy/;
use Encode;
use utf8;

my @hovercraft = (
    'My hovercraft is full of eels',
    'Automjeti im është plot me ngjala',
    'حَوّامتي مُمْتِلئة بِأَنْقَلَيْسون',
    ' Маё судна на паветранай падушцы поўна вуграмі',
    '我的氣墊船裝滿了鱔魚 ',
    'Il mio hovercraft/aeroscivolante è pieno di anguille',
    'សុទ្ធតែឣន្ចងពេញទូកហាះយើង ។',
    "Tá m'árthach foluaineach lán d'eascanna."
);

foreach my $h (@hovercraft) {
    $h = '["' . $h . '"]';
    my $j_perl = JSON::from_json($h);
    my $j_json = JSON::to_json($j_perl);

    my $h_enc = Encode::encode_utf8($h);
    my $j_perl_enc = JSON::from_json($h_enc);
    my $j_json_enc = JSON::to_json($j_perl_enc);

    my $jm_perl = from_json($h);
    my $jm_json = to_json($jm_perl);

    my $jm_perl_enc = from_json($h_enc);
    my $jm_json_enc = to_json($jm_perl_enc);

    is_deeply($j_perl, $jm_perl);
    is_deeply($j_perl_enc, $jm_perl_enc);
    is ($j_json, $jm_json);
    is ($j_json_enc, $jm_json_enc);
}

done_testing();
