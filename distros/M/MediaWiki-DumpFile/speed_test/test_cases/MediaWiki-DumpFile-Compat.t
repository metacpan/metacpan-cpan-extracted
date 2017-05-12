#!/usr/bin/env perl
use strict;
use warnings;

use Bench;

use MediaWiki::DumpFile::Compat; 

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');


my $file = shift(@ARGV) or die "must specify file";
my $fh;

open($fh, $file) or die "could not open $file: $!";

my $articles = Parse::MediaWikiDump::Pages->new($fh);

my $i;

while(defined(my $one = $articles->next)) {
	Bench::Article($one->title, ${$one->text});
	
#	if (++$i > 1000) { exit 1};
}
