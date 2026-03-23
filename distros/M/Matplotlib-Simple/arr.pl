#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;

plt({
	ncols         => 3,
	nrows         => 2,
	'output.file' => '/tmp/logscale.svg',
	plots       => [
		{
			data        => {
				A => [
					[1..9],
					[1..9]
				]
			},
			logscale      => ['x', 'y'],
			'plot.type'   => 'plot',
			'show.legend' => 0,
			title         => 'plot'
		},
		{
			data        => {
				A => [1..9],
			},
			logscale      => ['x', 'y'],
			'plot.type'   => 'boxplot',
#			'show.legend' => 0,
			title         => 'boxplot'
		},
		{
			data        => {
				A => [1..9],
				B => [2..13,4,5,6,6,7,7]
			},
			logscale      => ['x', 'y'],
			'plot.type'   => 'hist',
#			'show.legend' => 0,
			title         => 'hist'
		},
		{
			data        => {
				A => [1..9],
				B => [2..13,4,5,6,6,7,7]
			},
			logscale      => ['y'],
			'plot.type'   => 'violin',
#			'show.legend' => 0,
			title         => 'violin'
		},
		{
			data        => {
				A => 59,
				B => 4
			},
			logscale      => 1,
			'plot.type'   => 'bar',
#			'show.legend' => 0,
			title         => 'bar'
		},
	],
	suptitle => 'Logscale uses'
});
