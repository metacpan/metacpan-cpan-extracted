use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::TimezoneOffset;

subtest 'UTC and GMT are zero' => sub {
	is(UTC, 0, 'UTC is 0');
	is(GMT, 0, 'GMT is 0');
};

subtest 'US offsets' => sub {
	is(EST,  -18000, 'EST is -18000 (-5h)');
	is(EDT,  -14400, 'EDT is -14400 (-4h)');
	is(CST,  -21600, 'CST is -21600 (-6h)');
	is(MST,  -25200, 'MST is -25200 (-7h)');
	is(PST,  -28800, 'PST is -28800 (-8h)');
	is(HST,  -36000, 'HST is -36000 (-10h)');
	is(ADT,  -10800, 'ADT is -10800 (-3h)');
	is(NST,  -12600, 'NST is -12600 (-3:30)');
	is(NDT,   -9000, 'NDT is -9000 (-2:30)');
};

subtest 'european offsets' => sub {
	is(CET,   3600,  'CET is 3600 (+1h)');
	is(CEST,  7200,  'CEST is 7200 (+2h)');
	is(EET,   7200,  'EET is 7200 (+2h)');
	is(BST,   3600,  'BST is 3600 (+1h)');
	is(MSK,  10800,  'MSK is 10800 (+3h)');
	is(AZOT, -3600,  'AZOT is -3600 (-1h)');
};

subtest 'south america offsets' => sub {
	is(BRT,  -10800, 'BRT is -10800 (-3h)');
	is(BRST,  -7200, 'BRST is -7200 (-2h)');
	is(ART,  -10800, 'ART is -10800 (-3h)');
	is(CLT,  -14400, 'CLT is -14400 (-4h)');
	is(VET,  -16200, 'VET is -16200 (-4:30)');
	is(BOT,  -14400, 'BOT is -14400 (-4h)');
	is(FNT,   -7200, 'FNT is -7200 (-2h)');
};

subtest 'africa offsets' => sub {
	is(SAST,  7200,  'SAST is 7200 (+2h)');
	is(EAT,  10800,  'EAT is 10800 (+3h)');
	is(WAT,   3600,  'WAT is 3600 (+1h)');
	is(MUT,  14400,  'MUT is 14400 (+4h)');
	is(CVT,  -3600,  'CVT is -3600 (-1h)');
};

subtest 'middle east offsets' => sub {
	is(IRST, 12600,  'IRST is 12600 (+3:30)');
	is(IRDT, 16200,  'IRDT is 16200 (+4:30)');
	is(GST,  14400,  'GST is 14400 (+4h)');
	is(AFT,  16200,  'AFT is 16200 (+4:30)');
	is(IST,  19800,  'IST is 19800 (+5:30)');
	is(NPT,  20700,  'NPT is 20700 (+5:45)');
};

subtest 'asia pacific offsets' => sub {
	is(JST,  32400, 'JST is 32400 (+9h)');
	is(KST,  32400, 'KST is 32400 (+9h)');
	is(SGT,  28800, 'SGT is 28800 (+8h)');
	is(AEST, 36000, 'AEST is 36000 (+10h)');
	is(NZST, 43200, 'NZST is 43200 (+12h)');
	is(MMT,  23400, 'MMT is 23400 (+6:30)');
	is(WITA, 28800, 'WITA is 28800 (+8h)');
	is(WIT,  32400, 'WIT is 32400 (+9h)');
};

subtest 'russia offsets' => sub {
	is(SAMT, 14400, 'SAMT is 14400 (+4h)');
	is(YEKT, 18000, 'YEKT is 18000 (+5h)');
	is(OMST, 21600, 'OMST is 21600 (+6h)');
	is(IRKT, 28800, 'IRKT is 28800 (+8h)');
	is(VLAT, 36000, 'VLAT is 36000 (+10h)');
	is(PETT, 43200, 'PETT is 43200 (+12h)');
};

subtest 'australia offsets' => sub {
	is(AWST, 28800, 'AWST is 28800 (+8h)');
	is(ACST, 34200, 'ACST is 34200 (+9:30)');
	is(ACDT, 37800, 'ACDT is 37800 (+10:30)');
	is(LHST, 37800, 'LHST is 37800 (+10:30)');
};

subtest 'pacific offsets' => sub {
	is(FJT,   43200, 'FJT is 43200 (+12h)');
	is(SST,  -39600, 'SST is -39600 (-11h)');
	is(LINT,  50400, 'LINT is 50400 (+14h)');
	is(CKT,  -36000, 'CKT is -36000 (-10h)');
};

subtest 'arithmetic' => sub {
	my $utc_epoch = 1700000000;
	my $est_local = $utc_epoch + EST;
	is($est_local, $utc_epoch - 18000, 'EST offset arithmetic works');
	ok(JST > EST, 'JST > EST');
	ok(PST < UTC, 'PST < UTC');
};

subtest 'meta accessor' => sub {
	my $meta = Offset();
	ok($meta->count >= 100, 'at least 100 offsets');
	ok($meta->valid(0),      '0 is valid');
	ok($meta->valid(-28800), '-28800 is valid');
	ok($meta->valid(32400),  '32400 is valid');
	ok(!$meta->valid(99999), '99999 is not valid');
};

done_testing;
