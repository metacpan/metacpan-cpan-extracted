# -*- perl -*-

use Test::More tests => 90;

BEGIN { use_ok( 'GSM::ARFCN' ); }

my $ga;
$ga = GSM::ARFCN->new;
isa_ok($ga, 'GSM::ARFCN');
is($ga->bpi, "GSM-1900", "bpi");

is($ga->channel(0), 0, "channel");
is($ga->ful, 890, "ful");
is($ga->fdl, 935, "fdl");
is($ga->band, "EGSM-900", "band");

is($ga->channel(1), 1, "channel");
is($ga->ful, 890.2, "ful");
is($ga->fdl, 935.2, "fdl");
is($ga->band, "GSM-900", "band");

is($ga->channel(124), 124, "channel");
is($ga->ful, 914.8, "ful");
is($ga->fdl, 959.8, "fdl");
is($ga->band, "GSM-900", "band");

is($ga->channel(128), 128, "channel");
is($ga->ful, 824.2, "ful");
is($ga->fdl, 869.2, "fdl");
is($ga->band, "GSM-850", "band");

is($ga->channel(251), 251, "channel");
is($ga->ful, 848.8, "ful");
is($ga->fdl, 893.8, "fdl");
is($ga->band, "GSM-850", "band");

is($ga->channel(259), 259, "channel");
is($ga->ful, 450.6, "ful");
is($ga->fdl, 460.6, "fdl");
is($ga->band, "GSM-450", "band");

is($ga->channel(293), 293, "channel");
is($ga->ful, 457.4, "ful");
is($ga->fdl, 467.4, "fdl");
is($ga->band, "GSM-450", "band");

is($ga->channel(306), 306, "channel");
is($ga->ful, 479.0, "ful");
is($ga->fdl, 489.0, "fdl");
is($ga->band, "GSM-480", "band");

is($ga->channel(340), 340, "channel");
is($ga->ful, 485.8, "ful");
is($ga->fdl, 495.8, "fdl");
is($ga->band, "GSM-480", "band");

is($ga->channel(438), 438, "channel");
is($ga->ful, 747.2, "ful");
is($ga->fdl, 777.2, "fdl");
is($ga->band, "GSM-750", "band");

is($ga->channel(511), 511, "channel");
is($ga->ful, 761.8, "ful");
is($ga->fdl, 791.8, "fdl");
is($ga->band, "GSM-750", "band");

is($ga->channel(512), 512, "channel");
is($ga->ful, 1850.2, "ful");
is($ga->fdl, 1930.2, "fdl");
is($ga->band, "GSM-1900", "band");

is($ga->channel(810), 810, "channel");
is($ga->ful, 1909.8, "ful");
is($ga->fdl, 1989.8, "fdl");
is($ga->band, "GSM-1900", "band");

is($ga->channel(811), 811, "channel");
is($ga->ful, 1770.0, "ful");
is($ga->fdl, 1865.0, "fdl");
is($ga->band, "GSM-1800", "band");

is($ga->channel(885), 885, "channel");
is($ga->ful, 1784.8, "ful");
is($ga->fdl, 1879.8, "fdl");
is($ga->band, "GSM-1800", "band");

is($ga->channel(955), 955, "channel");
is($ga->ful, 876.2, "ful");
is($ga->fdl, 921.2, "fdl");
is($ga->band, "RGSM-900", "band");

is($ga->channel(974), 974, "channel");
is($ga->ful, 880.0, "ful");
is($ga->fdl, 925.0, "fdl");
is($ga->band, "RGSM-900", "band");

is($ga->channel(975), 975, "channel");
is($ga->ful, 880.2, "ful");
is($ga->fdl, 925.2, "fdl");
is($ga->band, "EGSM-900", "band");

is($ga->channel(1023), 1023, "channel");
is($ga->ful, 889.8, "ful");
is($ga->fdl, 934.8, "fdl");
is($ga->band, "EGSM-900", "band");

is($ga->bpi, "GSM-1900", "bpi");
is($ga->bpi("GSM-1800"), "GSM-1800", "bpi");
is($ga->channel(512), 512, "channel");
is($ga->ful, 1710.2, "ful");
is($ga->fdl, 1805.2, "fdl");
is($ga->band, "GSM-1800", "band");

is($ga->channel(810), 810, "channel");
is($ga->ful, 1769.8, "ful");
is($ga->fdl, 1864.8, "fdl");
is($ga->band, "GSM-1800", "band");

is($ga->bpi, "GSM-1800", "bpi");
