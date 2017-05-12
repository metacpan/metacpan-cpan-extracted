#!/usr/bin/env perl

use strict;
use warnings;

use Bench;

use MediaWiki::DumpFile::Pages;

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $file = shift(@ARGV) or die "must specify file";

my $dump = MediaWiki::DumpFile::Pages->new(input => $file, fast_mode => 1);

while(defined(my $page = $dump->next)) {
	Bench::Article($page->title, $page->revision->text);
}