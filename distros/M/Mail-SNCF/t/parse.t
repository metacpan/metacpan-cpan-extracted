#!perl -T

use Test::More tests => 2;

use Mail::SNCF;

my $file = "t/sncf";

my $sncf = Mail::SNCF->parse($file);

ok(defined $sncf, "Mail::SNCF->parse(file) returns something");
ok($sncf->isa('Mail::SNCF'), "with the right class");

