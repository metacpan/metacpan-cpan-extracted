#!perl -w

use strict;
use warnings;

use Test::Exception tests => 1;
use MediaWiki::DumpFile::Compat;

my $file = 't/compat.revisions_test.xml';

throws_ok { test() } qr/^only one revision per page is allowed$/, 'one revision per article ok';

sub test {	
	my $pages = Parse::MediaWikiDump->pages($file);
	
	while(defined($pages->next)) { };
};



