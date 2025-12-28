#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;
use File::Temp;

my $fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.py', UNLINK => 0);
plt({
	cbpad       => 0.01,          # default 0.05 is too big
	data        => [              # imshow gets a 2D array
		[' ', ' ', ' ', ' ', 'G'], # bottom
		['S', 'I', 'T', 'E', 'H'], # top
	],
	execute     => 0,
	fh          => $fh,
	'plot.type' => 'imshow',
	stringmap   => {
		'H' => 'Alpha helix',
		'B' => 'Residue in isolated β-bridge',
		'E' => 'Extended strand, participates in β ladder',
		'G' => '3-helix (3/10 helix)',
		'I' => '5 helix (pi helix)',
		'T' => 'hydrogen bonded turn',
		'S' => 'bend',
		' ' => 'Loops and irregular elements'
	},
	'output.file' => '/tmp/dssp.single.svg',
	scalex        => 2.4,
	set_ylim      => '0, 1',
	title         => 'Dictionary of Secondary Structure in Proteins (DSSP)',
	xlabel        => 'xlabel',
	ylabel        => 'ylabel'
});
plt({
	cbpad       => 0.01,          # default 0.05 is too big
	plots       => [
		{ # 1st plot
			data 	=> [
				[' ', ' ', ' ', ' ', 'G'], # bottom
				['S', 'I', 'T', 'E', 'H'], # top
			],
			'plot.type' => 'imshow',
			set_xticklabels=> '[]', # remove x-axis labels
			set_ylim    => '0, 1',
			stringmap   => {
				'H' => 'Alpha helix',
				'B' => 'Residue in isolated β-bridge',
				'E' => 'Extended strand, participates in β ladder',
				'G' => '3-helix (3/10 helix)',
				'I' => '5 helix (pi helix)',
				'T' => 'hydrogen bonded turn',
				'S' => 'bend',
				' ' => 'Loops and irregular elements'
			},
			title         => 'top plot',
			ylabel        => 'ylabel'
		},
		{ # 2nd plot
			data 	=> [
				[' ', ' ', ' ', ' ', 'G'], # bottom
				['S', 'I', 'T', 'E', 'H'], # top
			],
			'plot.type' => 'imshow',
			set_ylim    => '0, 1',
			stringmap   => {
				'H' => 'Alpha helix',
				'B' => 'Residue in isolated β-bridge',
				'E' => 'Extended strand, participates in β ladder',
				'G' => '3-helix (3/10 helix)',
				'I' => '5 helix (pi helix)',
				'T' => 'hydrogen bonded turn',
				'S' => 'bend',
				' ' => 'Loops and irregular elements'
			},
			title         => 'bottom plot',
			xlabel        => 'xlabel',
			ylabel        => 'ylabel'
		}
	],
	execute           => 1,
	fh                => $fh,
	nrows             => 2,
	'output.file'     => '/tmp/dssp.multiple.svg',
	scalex            => 2.4,
	'shared.colorbar' => [0,1], # plots 0 and 1 share a colorbar
	suptitle          => 'Dictionary of Secondary Structure in Proteins (DSSP)',
});
