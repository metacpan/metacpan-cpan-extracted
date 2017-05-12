#!/usr/bin/env perl

use strict;
use warnings;

use XML::TreePuller;

use Bench;

binmode(STDOUT, ':utf8');

my $xml = XML::TreePuller->new(location => shift(@ARGV));

$xml->config('/mediawiki/page', 'subtree');

while(defined(my $e = $xml->next)) {
	Bench::Article($e->get_elements('title')->text, $e->get_elements('revision/text')->text);
}