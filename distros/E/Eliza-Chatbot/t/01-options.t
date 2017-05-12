#!perl -T

use strict;
use warnings;
use Test::More;
use feature 'say';

BEGIN {
	use_ok( 'Eliza::Chatbot::Option' ) || print "Bail out!\n";
}

subtest 'attributes exist' => sub {
	test_da_attributes({
		att => 'name',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'script_file',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'debug',
		value => '1'
	});
	test_da_attributes({
		att => 'debug_text',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'transform_text',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'prompts_on',
		value => '1'
	});
	test_da_attributes({
		att => 'memory_on',
		value => '1'
	});
	test_da_attributes({
		att => 'botprompt',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'userprompt',
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'key',
		data => 1,
        value => 'Lnation'
	});
	test_da_attributes({
		att => 'decomp',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'reasmb',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'reasmb_for_memory',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'pre',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'post',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'synon',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'initial',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'final',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'quit',
        data => 1,
		value => 'Lnation'
	});
	test_da_attributes({
		att => 'max_memory_size',
		value => '10'
	});
	test_da_attributes({
		att => 'likelihood_of_using_memory',
		value => '1'
	});
	test_da_attributes({
		att => 'memory',
		value => 'Lnation'
	});
};

done_testing();

sub test_da_attributes {
    my $args = shift;
	my $fields = Eliza::Chatbot::Option->new();
	my $att = $args->{att};
	
	# set the attribute
	# check its value
    if ($args->{data}){
        ok($fields->data->$att($args->{value}));
        is($fields->data->$att, $args->{value}, "$att set with correct value ");
    }
	else { 
        ok($fields->$att($args->{value}));
        is($fields->$att, $args->{value}, "$att set with correct value");
    }
}
