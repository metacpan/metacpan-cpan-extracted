#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok 'Log::Progress::Parser' or BAIL_OUT;

my @tests= (
	[ 'simple progress',
		 "fsjfkjsdhfksjdf\n"
		."progress: 0\n"
		."lfgenrnb,merbg\n"
		."progress: 0.1\n"
		."rmntbemrbtmrenbt\n",
		undef,
		{ message => '', progress => 0.1 },
	],
	[ 'substep progress',
		 "progress: foo (.5) Step 1\n"
		."progress: bar (.5) Step 2\n"
		."progress: foo 0/10\n"
		."progress: bar 1/10 - Status message\n"
		."progress: bar 5/10", # Final line doesn't count because no newline
		undef,
		{ progress => .05, step => {
			foo => {
				idx => 0,
				title => "Step 1",
				contribution => .5,
				progress => 0, current => 0, total => 10,
				message => '',
			},
			bar => {
				idx => 1,
				title => "Step 2",
				contribution => .5,
				progress => .1, current => 1, total => 10,
				message => 'Status message',
			},
		}}
	],
	[ 'growing scalar',
		undef,
		# Now, extend the previous input and parse more of it.
		" - New Status Message\n",
		{ progress => .25, step => {
			foo => {
				idx => 0,
				title => "Step 1",
				contribution => .5,
				progress => 0, current => 0, total => 10,
				message => '',
			},
			bar => {
				idx => 1,
				title => "Step 2",
				contribution => .5,
				progress => .5, current => 5, total => 10,
				message => 'New Status Message',
			},
		}},
	],
);
my $parser;
for (@tests) {
	my ($name, $input, $append, $state)= @$_;
	if ($append) {
		$parser->input($parser->input . $append);
	} else {
		$parser= Log::Progress::Parser->new(input => $input);
	}
	$parser->parse;
	is_deeply( $parser->state, $state, $name )
		or diag explain $parser->state;
	# check that we didn't clobber $_
	is( $_->[3], $state, '$_ intact' );
}

subtest sticky_message => sub {
	my $parser= Log::Progress::Parser->new(input => "progress: 1/5\n");
	$parser->parse;
	is( $parser->state->{message}, '', 'no sticky; start blank' );
	
	$parser->input($parser->input . "progress: 2/5 - Foo\n");
	$parser->parse;
	is( $parser->state->{message}, 'Foo', 'find message' );
	
	$parser->input($parser->input . "progress: 3/5\n");
	$parser->parse;
	is( $parser->state->{message}, '', 'absent message clears it' );
	
	#---------------------
	
	$parser= Log::Progress::Parser->new(sticky_message => 1, input => "progress: 1/5\n");
	$parser->parse;
	is( $parser->state->{message}, '', 'sticky; start blank' );
	
	$parser->input($parser->input . "progress: 2/5 - Foo\n");
	$parser->parse;
	is( $parser->state->{message}, 'Foo', 'find message' );
	
	$parser->input($parser->input . "progress: 3/5\n");
	$parser->parse;
	is( $parser->state->{message}, 'Foo', 'absent message doesnt clear it' );
	
	#--------------------
	
	$parser= Log::Progress::Parser->new(sticky_message => 1, input => "progress: 1/5\n");
	$parser->parse;
	is( $parser->state->{message}, '', 'start blank' );
	
	$parser->input($parser->input . "progress: 2/5 - Foo\n");
	$parser->parse;
	is( $parser->state->{message}, 'Foo', 'find message' );
	
	$parser->input($parser->input . "progress: 3/5 - \n");
	$parser->parse;
	is( $parser->state->{message}, '', 'allow logger to forcibly clear message' );
};

done_testing;
