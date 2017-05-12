# enco.t - tests for "preferred ENCO name" functionality of I18N::Charset

# $Id: enco.t,v 1.5 2005-11-12 14:45:08 Daddy Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use strict;

BEGIN { &use_ok('I18N::Charset') };

#================================================
# TESTS FOR enco routines
#================================================

my @aa;
#---- selection of examples which should all result in undef -----------
ok(!defined enco_charset_name(), 'no argument');
ok(!defined enco_charset_name(undef), 'undef argument');
ok(!defined enco_charset_name(""), 'empty argument');
ok(!defined enco_charset_name("junk"), 'junk argument');
ok(!defined enco_charset_name(999999), '999999 argument');
ok(!defined enco_charset_name(\@aa), 'arrayref argument');
$oICE->start;
ok(!defined I18N::Charset::add_enco_alias(undef => 'junk argument'));
ok(!defined I18N::Charset::add_enco_alias('' => 'junk argument'));
ok(!defined I18N::Charset::add_enco_alias("my-junk" => 'junk argument'));
$oICE->stop;

SKIP:
  {
  skip 'Encode is not installed', 18 unless eval "require Encode";

  #---- some successful examples -----------------------------------------
  is(enco_charset_name("x-x-sjis"), enco_charset_name("Shift JIS"), 'x-x-sjis');
  is(enco_charset_name("x-ASCII"), "ascii", 'normal literal -- ASCII');
  is(enco_charset_name("S-JIS"), "shiftjis", 'normal -- G.B.K.');
  is(enco_charset_name("cp1251"), "cp1251", 'identity -- cp1251');
  is(enco_charset_name("IBM1047"), "cp1047", 'builtin alias -- cp1047');
  is(enco_charset_name("cp037"), "cp37", 'builtin alias -- cp37');
  is(enco_charset_name("ebcdic-cp-us"), "cp37", 'builtin alias -- cp37');
  is(enco_charset_name("windows-31-j"), "cp932", 'builtin alias -- cp932');
  is(enco_charset_name("cs GB-2312"), "gb2312-raw", 'builtin alias -- gb2312-raw');

  #---- some aliasing examples -----------------------------------------
  ok(I18N::Charset::add_enco_alias('my-japanese1' => 'jis0201-raw'));
  is(enco_charset_name("my-japanese1"),
     'jis0201-raw',
     'alias literal -- my-japanese1');
  is(enco_charset_name("my-japanese1"),
     enco_charset_name('jis-x-0201'),
     'alias equal -- my-japanese1');
  ok(I18N::Charset::add_enco_alias('my-japanese2' => 'jis0208-raw'));
  is(enco_charset_name("my-japanese2"),
     enco_charset_name('cs ISO-87 JIS_X0208'), 'alias equal -- my-japanese2');
  ok(I18N::Charset::add_enco_alias('my-japanese3' => 'sjis'), 'set alias my-japanese3');
  is(enco_charset_name("my-japanese3"), 'shiftjis', 'alias literal -- my-japanese3');
  is(enco_charset_name("my-japanese3"),
     enco_charset_name('MS_KANJI'), 'alias equal -- my-japanese3');
  ok(I18N::Charset::add_enco_alias('my-japanese4' => 'my-japanese1'), 'alias-to-alias');
  is(enco_charset_name("my-japanese4"),
     enco_charset_name('my-japanese1'), 'alias equal -- my-japanese4');
  is(enco_charset_name("my-japanese4"),
     'jis0201-raw', 'alias equal -- my-japanese4');
  } # end of SKIP block

exit 0;

__END__

