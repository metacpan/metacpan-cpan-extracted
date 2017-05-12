#!/usr/bin/perl -w
use Test::More qw(no_plan);

SKIP: {
	eval 'use Log::Funlog::Lang 0.3';
	skip 'No Log::Funlog::Lang available, or version too old' if ($@);
	ok ( eval 'use Log::Funlog 0.3; *Log=Log::Funlog->new(verbose => "1/1", fun => 50)', 'Use of fun' );
}
