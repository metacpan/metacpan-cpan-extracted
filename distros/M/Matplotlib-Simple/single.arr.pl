#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':all';
use Matplotlib::Simple;

hist({
	data          => [0..9],
	'output.file' => '/tmp/hist.arr.svg',
});

