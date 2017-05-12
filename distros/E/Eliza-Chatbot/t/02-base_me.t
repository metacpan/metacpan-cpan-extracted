#!perl -T

use strict;
use warnings;
use Test::More;
use feature 'say';

BEGIN {
	use_ok( 'Eliza::Chatbot' ) || print "Bail out!\n";
}

subtest 'attributes exist' => sub {
	update_options({
		options => {
			name => 'Lnation'
		},
		att => 'name',
		value => 'Lnation'
	});
	update_options({
		options => {
			script_file => 'somefile.txt'
		},
		att => 'script_file',
		value => 'somefile.txt'
	});
	update_options({
		options => {
			debug => 1
		},
		att => 'debug',
		value => 1
	});
	update_options({
		options => {
			prompts_on => 1
		},
		att => 'prompts_on',
		value => 1
	});
	update_options({
		options => {
			memory_on => 1
		},
		att => 'memory_on',
		value => '1'
	});
};

done_testing();

sub update_options {
    my $args = shift;
	my $fields = Eliza::Chatbot->new($args->{options});
	my $att = $args->{att};
	# check its value
	is($fields->$att, $args->{value}, "$att set with correct value");
}
