#!/usr/bin/env perl

use strict;
use warnings;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

use Bench;

use XML::Records;

my $p = XML::Records->new(shift(@ARGV)) or die "$!";

$p->set_records('page');

while(defined(my $page = $p->get_record)) {
	my $title = $page->{title};
	my $text = $page->{revision}->{text}->[0];

	Bench::Article($title, $text);	
}

