#!/usr/bin/env perl

use strict;
use warnings;

use Bench;

use MediaWiki::DumpFile::FastPages;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $file = shift(@ARGV) or die "must specify file";

my $dump = MediaWiki::DumpFile::FastPages->new($file);

while(my ($title, $text) = $dump->next) {
	Bench::Article($title, $text);
}