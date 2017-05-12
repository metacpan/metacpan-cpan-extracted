use strict;
use warnings;
use Test::More;
use GeoHash;


my $gh = GeoHash->new;


subtest 'bad' => sub {
    my @list = $gh->merge(qw/
        a2b
        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse czc 2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psy c2b25psz
        z
    /);
    is_deeply(\@list, [qw/
        2b25psf a2b
        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psy c2b25psz
        czc z
    /]);
};

subtest 'simple ok' => sub {
    my @list = sort $gh->merge(qw/
        a2b
        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse czc 2b25psf c2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psn c2b25psp c2b25psq c2b25psr c2b25pss c2b25pst c2b25psu c2b25psv c2b25psw c2b25psx
        c2b25psy c2b25psz
        z
    /);
    is_deeply(\@list, [qw/ 2b25psf a2b c2b25ps czc z /]);
};

subtest 'nest ok' => sub {
    my @list = sort $gh->merge(qw/
        c2b0 c2b1      c2b3 c2b4 c2b5 c2b6 c2b7 c2b8 c2b9
        c2bb c2bc c2bd c2be c2bf c2bg c2bh c2bj c2bk c2bm
        c2bn c2bp c2bq c2br c2bs c2bt c2bu c2bv c2bw c2bx
        c2by c2bz

        c2b20 c2b21 c2b22 c2b23 c2b24       c2b26 c2b27 c2b28 c2b29
        c2b2b c2b2c c2b2d c2b2e c2b2f c2b2g c2b2h c2b2j c2b2k c2b2m
        c2b2n c2b2p c2b2q c2b2r c2b2s c2b2t c2b2u c2b2v c2b2w c2b2x
        c2b2y c2b2z

        c2b250 c2b251 c2b252 c2b253 c2b254 c2b255 c2b256 c2b257 c2b258 c2b259
        c2b25b c2b25c c2b25d c2b25e c2b25f c2b25g c2b25h c2b25j c2b25k c2b25m
        c2b25n        c2b25q c2b25r c2b25s c2b25t c2b25u c2b25v c2b25w c2b25x
        c2b25y c2b25z

        c2b25p0 c2b25p1 c2b25p2 c2b25p3 c2b25p4 c2b25p5 c2b25p6 c2b25p7 c2b25p8 c2b25p9
        c2b25pb c2b25pc c2b25pd c2b25pe c2b25pf c2b25pg c2b25ph c2b25pj c2b25pk c2b25pm
        c2b25pn c2b25pp c2b25pq c2b25pr         c2b25pt c2b25pu c2b25pv c2b25pw c2b25px
        c2b25py c2b25pz

        c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
        c2b25psb c2b25psc c2b25psd c2b25pse c2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
        c2b25psn c2b25psp c2b25psq c2b25psr c2b25pss c2b25pst c2b25psu c2b25psv c2b25psw c2b25psx
        c2b25psy c2b25psz
    /);
    is_deeply(\@list, [qw/ c2b /]);
};

done_testing;
