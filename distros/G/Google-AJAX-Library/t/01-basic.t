use strict;
use warnings;

use Test::More;
use Google::AJAX::Library;

plan qw/no_plan/;

my $library;
ok($library = Google::AJAX::Library->new(qw/name jquery/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js");
is(''.$library->html, '<script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js" type="text/javascript"></script>');

ok($library = Google::AJAX::Library->mootools);
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1/mootools-yui-compressed.js");

ok($library = Google::AJAX::Library->mootools(uncompressed => 1));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1/mootools.js");

ok($library = Google::AJAX::Library->mootools('1.2', uncompressed => 1));
is($library->version, '1.2');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1.2/mootools.js");

ok($library = Google::AJAX::Library->mootools({ version => '1.2', uncompressed => 1 }));
is($library->version, '1.2');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1.2/mootools.js");

ok($library = Google::AJAX::Library->mootools('1.2'));
is($library->version, '1.2');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1.2/mootools-yui-compressed.js");

ok($library = Google::AJAX::Library->mootools(version => '1.2'));
is($library->version, '1.2');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1.2/mootools-yui-compressed.js");

ok($library = Google::AJAX::Library->mootools({ version => '1.2' }));
is($library->version, '1.2');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1.2/mootools-yui-compressed.js");
