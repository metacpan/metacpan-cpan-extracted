#!/usr/bin/env perl
use Dancer;
if ($ENV{DWIMMER_TEST}) {
	set log          => 'warning';
	set startup_info => 0;
}
if ($ENV{DWIMMER_PORT}) {
	set port         => $ENV{DWIMMER_PORT};
}
use Dwimmer;
dance;
