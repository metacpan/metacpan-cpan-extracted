use Test::More;
use strict;
use warnings;
use Hazy;
our $hazy = Hazy->new();

subtest 'basic' => sub {
	run_test({
		css => '
		.class { 
			color: $one;
		} 
		.second {
			background: @two;	
		}',
		args => {
			'$one' => '#fff',
			'@two' => '#ccc',
		},
		expected => '
		.class { 
			color: #fff;
		} 
		.second {
			background: #ccc;	
		}',
	});
	run_test({
		css => '
		.class { 
			margin: %one;
		} 
		.second {
			background: &two;	
		}',
		args => {
			'%one' => '0 0 0 0',
			'&two' => '#ccc',
		},
		expected => '
		.class { 
			margin: 0 0 0 0;
		} 
		.second {
			background: #ccc;	
		}',
	});
	run_test({
		css => '
		.class { 
			margin: ~one;
		} 
		.second {
			background: !two;	
		}',
		args => {
			'~one' => '0 0 0 0',
			'!two' => '#ccc',
		},
		expected => '
		.class { 
			margin: 0 0 0 0;
		} 
		.second {
			background: #ccc;	
		}',
	});
};

sub run_test {
	is($hazy->make_replacements($_[0]->{args}, $_[0]->{css}), $_[0]->{expected}, "css - $_[0]->{expected}");	
}

done_testing();
