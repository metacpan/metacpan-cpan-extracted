use strict;
use warnings;
use Test::More;
use GeoHash;

my $gh = GeoHash->new;

my @list = $gh->split('c2b25ps');
is_deeply(\@list, [ qw/
    c2b25ps0 c2b25ps1 c2b25ps2 c2b25ps3 c2b25ps4 c2b25ps5 c2b25ps6 c2b25ps7 c2b25ps8 c2b25ps9
    c2b25psb c2b25psc c2b25psd c2b25pse c2b25psf c2b25psg c2b25psh c2b25psj c2b25psk c2b25psm
    c2b25psn c2b25psp c2b25psq c2b25psr c2b25pss c2b25pst c2b25psu c2b25psv c2b25psw c2b25psx
    c2b25psy c2b25psz
/ ]);

done_testing;
