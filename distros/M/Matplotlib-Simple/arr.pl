#!/usr/bin/env perl

use 5.042;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use Matplotlib::Simple;
#use File::Temp;

my @plots = ({
	data => {
		'sin' => [map {sin($_ * 3.14159265/180)} 0..360],
		'cos' => [map {cos($_ * 3.14159265/180)} 0..360]
	},
	'plot.type' => 'hist2d',
	cbpad       => 0.001,
	title       => 'pad = 0.001'
});
for (my $pad = 0.01; $pad <= 0.06; $pad += 0.03) {
	push @plots, {
		data => {
			'sin' => [map {sin($_ * 3.14159265/180)} 0..360],
			'cos' => [map {cos($_ * 3.14159265/180)} 0..360]
		},
		'plot.type' => 'hist2d',
		cbdrawedges => 1,
		cbpad       => $pad,
		title       => "pad = $pad"
	};
}
plt({
	'output.file' => '/tmp/hist2d.pads.svg',
	plots         => \@plots,
	ncols         => 1,
	nrows         => 3,
	sharey        => 1,
	scale         => 2
});
#my $fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.py', UNLINK => 0);
=plt({
	cbpad       => 0.01,          # default 0.05 is too big
	data        => {
		'sin' => [map {sin($_ * 3.141592653/180)} 0..360],
		'cos' => [map {cos($_ * 3.141592653/180)} 0..360]
	},
	'plot.type'   => 'hexbin',
	'output.file' => '/tmp/hexbin.svg',
	set_ylim      => '0, 1',
});

