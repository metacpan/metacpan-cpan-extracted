#!/usr/bin/env perl

use strict;
use warnings;

use XML::TreePuller;

use Bench;

binmode(STDOUT, ':utf8');

my $xml = XML::TreePuller->new(location => shift(@ARGV));

$xml->config('/mediawiki/page/title', 'subtree');
$xml->config('/mediawiki/page/revision/text', 'subtree');

my $title;

while(my ($path, $e) = $xml->next) {
	if ($path eq '/mediawiki/page/title') {
		$title = $e->text;
	} elsif ($path eq '/mediawiki/page/revision/text') {
		Bench::Article($title, $e->text);
	}
}