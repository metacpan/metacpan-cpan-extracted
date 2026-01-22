#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;
use File::Temp;

my @t;
for (my $t = 0.01; $t <= 10; $t += 0.01) {
	push @t, $t;
}
my $fh = File::Temp->new(DIR => '/tmp', UNLINK => 0, SUFFIX => '.py');
plt({
	execute       => 0,
	fh            => $fh,
	data          => [
		[ # plot 0
			[@t],              # x coordinates
			[map {sin($_)} @t] # y coordinates
		],
		[ # plot 1
			[@t],
			[map {exp($_)} @t]
		]
	],
	'output.file' => '/tmp/twinx.arr.svg',
	'plot.type'   => 'plot',
	'set.options' => [
		'color = "blue"', # plot 0
		'color = "red"'   # plot 1
	],
	tick_params => 'axis = "y", labelcolor = "blue"',
	ylabel      => '"sin", color="blue"', # applies to base ax object
	'twinx.args'  => {
		1 => { # automatically knows that plot 1 is twinned on x
			tick_params => 'axis = "y", labelcolor = "red"',
			ylabel      => '"exp", color="red"',
		}
	},
});
plt({
	show          => 'True',
	execute       => 1,
	fh            => $fh,
	data          => {
		'sin' => [ # plot 0
			[@t],              # x coordinates
			[map {sin($_)} @t] # y coordinates
		],
		'exp' => [ # plot 1
			[@t],
			[map {exp($_)} @t]
		]
	},
	'output.file' => '/tmp/twinx.hash.svg',
	'plot.type'   => 'plot',
	'set.options' => {
		'sin' => 'color = "blue"',
		'exp' => 'color = "red"'
	},
	tick_params => 'axis = "y", labelcolor = "blue"',
	ylabel      => '"sin", color="blue"', # applies to base ax object
	'twinx.args'  => {
		'exp' => { # automatically knows that plot is twinx
			tick_params => 'axis = "y", labelcolor = "red"',
			ylabel      => '"exp", color="red"',
		}
	},
});
