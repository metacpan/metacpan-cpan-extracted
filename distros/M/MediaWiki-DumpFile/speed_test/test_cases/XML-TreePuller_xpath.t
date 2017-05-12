#!/usr/bin/env perl

use strict;
use warnings;

use XML::TreePuller;

use Bench;

binmode(STDOUT, ':utf8');

my $xml = XML::TreePuller->new(location => shift(@ARGV));

$xml->config('/mediawiki/page', 'subtree');

while(defined(my $e = $xml->next)) {
	my $t = $e->xpath('/page');
	
	Bench::Article($e->xpath('/page/title')->text, $e->xpath('/page/revision/text')->text);
}