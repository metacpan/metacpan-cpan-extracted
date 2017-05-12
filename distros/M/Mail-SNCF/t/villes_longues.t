#!perl -T

use Test::More tests => 1;

use Mail::SNCF;

my $file = "t/villes_longues";

my $sncf = Mail::SNCF->parse($file);

ok($sncf->isa('Mail::SNCF'), "Works with long city names");

