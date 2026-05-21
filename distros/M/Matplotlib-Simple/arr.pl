#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;

plt({
	data => [0..7],
	'plot.type' => 'violin',
	'output.file' => '/tmp/single.arr.violin.svg'
});
=my @arr = (
	{
		'plot.type' => 'plot',
		data        => {
			[0..3],
			[0..3]
		}
	}
);
plt({
	arr           => \@arr,
	'output.file' => '/tmp/opt.arr.svg'
});
