# $Id: mime.t,v 1.5 2005-09-01 03:09:45 Daddy Exp $
# mime.t - tests for "preferred MIME name" functionality of I18N::Charset

use Test::More tests => 14;

BEGIN { use_ok('I18N::Charset') };

#================================================
# TESTS FOR mime routines
#================================================

my @aa;
#---- selection of examples which should all result in undef -----------
ok(!defined mime_charset_name(), 'no argument');
ok(!defined mime_charset_name(undef), 'undef argument');
ok(!defined mime_charset_name(""), 'empty argument');
ok(!defined mime_charset_name("junk"), 'junk argument');
ok(!defined mime_charset_name(999999), '999999 argument');
ok(!defined mime_charset_name(\@aa), 'arrayref argument');

ok(!defined mime_charset_name("irv"), 'charset has no mime name');

#---- some successful examples -----------------------------------------
ok(mime_charset_name("us") eq "US-ASCII", 'us');
ok(mime_charset_name("ANSI_X3.4-1968") eq "US-ASCII", 'Alias is preferred, try Name');
ok(mime_charset_name("c s ascii") eq "US-ASCII", 'Alias is preferred, try another Alias');
ok(mime_charset_name("US-ASCII") eq "US-ASCII", 'Alias is preferred, try preferred Alias');
ok(mime_charset_name("ms_kanji_") eq "Shift_JIS", 'Name is preferred, try Alias');
ok(mime_charset_name("Big5") eq "Big5", 'Name is preferred, try Name');

exit 0;

__END__


