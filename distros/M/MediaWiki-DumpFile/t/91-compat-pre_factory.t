use Test::Simple tests => 3;
use strict;
use MediaWiki::DumpFile::Compat;


ok(defined(Parse::MediaWikiDump::Pages->new('t/compat.pages_test.xml')));
ok(defined(Parse::MediaWikiDump::Revisions->new('t/compat.revisions_test.xml')));
ok(defined(Parse::MediaWikiDump::Links->new('t/compat.links_test.sql')));