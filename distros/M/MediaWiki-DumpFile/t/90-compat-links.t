#!perl 

use Test::Simple tests =>4;
use strict;
use warnings;
use MediaWiki::DumpFile::Compat;

use Data::Dumper;

my $file = 't/compat.links_test.sql';

my $links = Parse::MediaWikiDump->links($file);

my $sum;
my $last_link;

while(my $link = $links->next) {
	$sum += $link->from;
	$last_link = $link;
}

ok($sum == 92288);
ok($last_link->from == 3955);
ok($last_link->to eq '...Baby_One_More_Time_(single)');
ok($last_link->namespace == 0);

