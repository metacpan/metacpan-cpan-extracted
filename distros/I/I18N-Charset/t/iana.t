# $Revision: 1.11 $
# iana.t - tests for Locale::Country

use ExtUtils::testlib;
use Test::More tests => 27;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use strict;

BEGIN { use_ok('I18N::Charset') };

#================================================
# TESTS FOR iana routines
#================================================

my @aa;
#---- selection of examples which should all result in undef -----------
ok(!defined iana_charset_name(), 'no arg');
ok(!defined iana_charset_name(undef), 'undef argument');
ok(!defined iana_charset_name(""), 'empty argument');
ok(!defined iana_charset_name("junk"), 'junk argument');
ok(!defined iana_charset_name("None"), 'None argument');
ok(!defined iana_charset_name(\@aa), 'arrayref argument');     # illegal argument

 #---- some successful examples -----------------------------------------
ok(iana_charset_name("Windows-1-2-5-1") eq "windows-1251", 'windows-1-2-5-1');
ok(iana_charset_name("windows-1252") eq "windows-1252", 'windows-1252 eq');
ok(iana_charset_name("win-latin-1") eq "windows-1252", 'win-latin-1');
ok(iana_charset_name("windows-1252") ne "windows-1253", 'windows-1252 ne');
ok(iana_charset_name("windows-1253") eq "windows-1253", 'windows-1253');
ok(iana_charset_name("Shift_JIS") eq "Shift_JIS", 'Shift_JIS');
ok(iana_charset_name("sjis") eq "Shift_JIS", 'sjis');
ok(iana_charset_name("x-sjis") eq "Shift_JIS", 'x-sjis');
ok(iana_charset_name("x-x-sjis") eq "Shift_JIS", 'x-x-sjis');
ok(iana_charset_name("Unicode-2-0-utf-8") eq "UTF-8", 'Unicode-2-0-utf-8');
ok(iana_charset_name("ISO-8859-16") eq "ISO-8859-16", 'ISO-8859-16');
ok(iana_charset_name("latin 10") eq "ISO-8859-16", 'latin 10');

 #---- some aliasing examples -----------------------------------------
$oICE->start;
ok(!defined(I18N::Charset::add_iana_alias("alias1" => "junk")), 'add alias1');
ok(!defined iana_charset_name("alias1"), 'alias1');
ok(!defined iana_charset_name("junk"), 'junk');
$oICE->stop;
ok(I18N::Charset::add_iana_alias("alias2" => "Shift_JIS") eq "Shift_JIS", 'add alias2');
ok(iana_charset_name("alias2") eq "Shift_JIS", 'alias2');

ok(I18N::Charset::add_iana_alias("alias3" => "sjis") eq "Shift_JIS", '');
ok(iana_charset_name("alias3") eq "Shift_JIS", '');
ok(iana_charset_name("sjis") eq "Shift_JIS", '');

# Tests for coverage:
my @asAll = I18N::Charset::all_iana_charset_names();
my $iAll = scalar(@asAll);
diag("There are $iAll IANA charset names registered");

exit 0;

__END__

