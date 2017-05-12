# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 40;

BEGIN { use_ok( 'GSM::ARFCN' ); }

my $ga;
$ga = GSM::ARFCN->new;
isa_ok($ga, 'GSM::ARFCN');
is($ga->channel(24), 24, "channel");
is($ga->ful, 894.8, "ful");
is($ga->fdl, 939.8, "fdl");
is($ga->band, "GSM-900", "band");
is($ga->cs, 0.2, "cs");
is($ga->fs, 45, "fs");
is($ga->bpi, "GSM-1900", "bpi");

$ga = GSM::ARFCN->new(24);
isa_ok($ga, 'GSM::ARFCN');
is($ga->channel, 24, "channel");
is($ga->ful, 894.8, "ful");
is($ga->fdl, 939.8, "fdl");
is($ga->band, "GSM-900", "band");
is($ga->cs, 0.2, "cs");
is($ga->fs, 45, "fs");
is($ga->bpi, "GSM-1900", "bpi");

$ga = GSM::ARFCN->new(channel=>24);
isa_ok($ga, 'GSM::ARFCN');
is($ga->channel, 24, "channel");
is($ga->ful, 894.8, "ful");
is($ga->fdl, 939.8, "fdl");
is($ga->band, "GSM-900", "band");
is($ga->cs, 0.2, "cs");
is($ga->fs, 45, "fs");
is($ga->bpi, "GSM-1900", "bpi");

$ga = GSM::ARFCN->new(channel=>24, bpi=>"GSM-1800");
isa_ok($ga, 'GSM::ARFCN');
is($ga->channel, 24, "channel");
is($ga->ful, 894.8, "ful");
is($ga->fdl, 939.8, "fdl");
is($ga->band, "GSM-900", "band");
is($ga->cs, 0.2, "cs");
is($ga->fs, 45, "fs");
is($ga->bpi, "GSM-1800", "bpi");

$ga = GSM::ARFCN->new(channel=>900);
isa_ok($ga, 'GSM::ARFCN');
is($ga->channel, 900, "channel");
is($ga->ful, undef, "ful");
is($ga->fdl, undef, "fdl");
is($ga->band, "", "band");
is($ga->cs, undef, "cs");
is($ga->fs, undef, "fs");

