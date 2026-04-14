use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Bool;

subtest 'yes/no' => sub {
	is(Yes, 'yes', 'Yes');
	is(No,  'no',  'No');
	my $meta = YesNo();
	is($meta->count, 2, '2 yes/no values');
	ok($meta->valid('yes'), 'yes is valid');
	ok($meta->valid('no'),  'no is valid');
};

subtest 'on/off' => sub {
	is(On,  'on',  'On');
	is(Off, 'off', 'Off');
	my $meta = OnOff();
	is($meta->count, 2, '2 on/off values');
};

subtest 'true/false' => sub {
	is(True,  1,  'True');
	is(False, 0, 'False');
	my $meta = TrueFalse();
	is($meta->count, 2, '2 true/false values');
	ok($meta->valid(1),  '1 is valid');
	ok($meta->valid(0), '0 is valid');
};

done_testing;
