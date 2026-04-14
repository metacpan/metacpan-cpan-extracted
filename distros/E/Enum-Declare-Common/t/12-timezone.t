use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Timezone;

subtest 'common US zones' => sub {
	is(UTC, 'UTC', 'UTC');
	is(EST, 'EST', 'EST');
	is(CST, 'CST', 'CST');
	is(MST, 'MST', 'MST');
	is(PST, 'PST', 'PST');
	is(HST, 'HST', 'HST');
	is(ADT, 'ADT', 'ADT');
	is(NDT, 'NDT', 'NDT');
};

subtest 'european zones' => sub {
	is(GMT,  'GMT',  'GMT');
	is(CET,  'CET',  'CET');
	is(CEST, 'CEST', 'CEST');
	is(EET,  'EET',  'EET');
	is(WET,  'WET',  'WET');
	is(MSK,  'MSK',  'MSK');
	is(AZOT, 'AZOT', 'AZOT');
};

subtest 'south america zones' => sub {
	is(BRT,  'BRT',  'BRT');
	is(BRST, 'BRST', 'BRST');
	is(ART,  'ART',  'ART');
	is(CLT,  'CLT',  'CLT');
	is(BOT,  'BOT',  'BOT');
	is(PYT,  'PYT',  'PYT');
	is(GFT,  'GFT',  'GFT');
	is(FNT,  'FNT',  'FNT');
};

subtest 'africa zones' => sub {
	is(SAST, 'SAST', 'SAST');
	is(EAT,  'EAT',  'EAT');
	is(WAT,  'WAT',  'WAT');
	is(WAST, 'WAST', 'WAST');
	is(MUT,  'MUT',  'MUT');
	is(CVT,  'CVT',  'CVT');
};

subtest 'middle east zones' => sub {
	is(IRST, 'IRST', 'IRST');
	is(IRDT, 'IRDT', 'IRDT');
	is(GST,  'GST',  'GST');
	is(AFT,  'AFT',  'AFT');
	is(IST,  'IST',  'IST');
	is(PKT,  'PKT',  'PKT');
	is(NPT,  'NPT',  'NPT');
};

subtest 'asia pacific zones' => sub {
	is(JST,  'JST',  'JST');
	is(KST,  'KST',  'KST');
	is(SGT,  'SGT',  'SGT');
	is(HKT,  'HKT',  'HKT');
	is(AEST, 'AEST', 'AEST');
	is(NZST, 'NZST', 'NZST');
	is(MYT,  'MYT',  'MYT');
	is(PHT,  'PHT',  'PHT');
	is(WITA, 'WITA', 'WITA');
	is(WIT,  'WIT',  'WIT');
};

subtest 'russia zones' => sub {
	is(SAMT, 'SAMT', 'SAMT');
	is(YEKT, 'YEKT', 'YEKT');
	is(OMST, 'OMST', 'OMST');
	is(IRKT, 'IRKT', 'IRKT');
	is(VLAT, 'VLAT', 'VLAT');
	is(PETT, 'PETT', 'PETT');
};

subtest 'australia zones' => sub {
	is(AWST, 'AWST', 'AWST');
	is(ACST, 'ACST', 'ACST');
	is(ACDT, 'ACDT', 'ACDT');
	is(LHST, 'LHST', 'LHST');
};

subtest 'pacific zones' => sub {
	is(FJT,  'FJT',  'FJT');
	is(TOT,  'TOT',  'TOT');
	is(SST,  'SST',  'SST');
	is(CHST, 'CHST', 'CHST');
	is(LINT, 'LINT', 'LINT');
	is(CKT,  'CKT',  'CKT');
};

subtest 'atlantic indian zones' => sub {
	is(IOT, 'IOT', 'IOT');
	is(MVT, 'MVT', 'MVT');
	is(TFT, 'TFT', 'TFT');
};

subtest 'meta accessor' => sub {
	my $meta = Zone();
	ok($meta->count >= 100, 'at least 100 timezone abbreviations');
	ok($meta->valid('UTC'), 'UTC is valid');
	ok($meta->valid('JST'), 'JST is valid');
	ok(!$meta->valid('XYZ'), 'XYZ is not valid');
	is($meta->name('UTC'), 'UTC', 'name of UTC is UTC');
};

done_testing;
