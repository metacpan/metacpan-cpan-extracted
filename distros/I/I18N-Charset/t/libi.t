# libi.t - tests for "preferred LIBI name" functionality of I18N::Charset

# $Id: libi.t,v 1.14 2008-07-12 03:27:12 Martin Exp $

use blib;
use Test::More;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use strict;

BEGIN { use_ok('I18N::Charset') };

#================================================
# TESTS FOR libi routines
#================================================

my @aa;
#---- selection of examples which should all result in undef -----------
ok(!defined libi_charset_name(), 'no argument');
ok(!defined libi_charset_name(undef), 'undef argument');
ok(!defined libi_charset_name(""), 'empty argument');
ok(!defined libi_charset_name("junk"), 'junk argument');
ok(!defined libi_charset_name(999999), '999999 argument');
ok(!defined libi_charset_name(\@aa), 'arrayref argument');
$oICE->start;
ok(!defined I18N::Charset::add_libi_alias("my-junk" => 'junk argument'));
$oICE->stop;

SKIP:
  {
  if (! eval "require App::Info::Lib::Iconv")
    {
    diag 'App::Info::Lib::Iconv is not installed';
    skip 'App::Info::Lib::Iconv is not installed', 16;
    } # if
  my $oAILI = new App::Info::Lib::Iconv;
 SKIP:
    {
    if (! ref $oAILI)
      {
      diag('can not determine iconv version (not installed?)');
      skip('can not determine iconv version (not installed?)', 16);
      } # if
 SKIP:
      {
      if (! $oAILI->installed)
        {
        diag('iconv is not installed');
        skip('iconv is not installed', 16);
        } # if
      my $iLibiVersion = $oAILI->version || 0.0;
      diag "libiconv version is $iLibiVersion\n";
 SKIP:
        {
        # Convert "n.m" into an actual floating point number so we can compare it:
        my $fLibiVersion = do { my @r = ($iLibiVersion =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
        if ($fLibiVersion < 1.008)
          {
          diag 'iconv version is too old(?)';
          skip 'iconv version is too old(?)', 16;
          } # if

        #---- some successful examples -----------------------------------------
        is(libi_charset_name("x-x-sjis"), libi_charset_name("MS_KANJI"), 'x-x-sjis');
        is(libi_charset_name("x-x-sjis"), "MS_KANJI", 'normal literal -- x-x-sjis');
        is(libi_charset_name("G.B.K."), "CP936", 'normal -- G.B.K.');
        is(libi_charset_name("CP936"), "CP936", 'identity -- CP936');
        is(libi_charset_name("Johab"), "CP1361", 'normal -- Johab');
        is(libi_charset_name("johab"), libi_charset_name("cp 1361"), 'equivalent -- johab');

        #---- some aliasing examples -----------------------------------------
        ok(I18N::Charset::add_libi_alias('my-chinese1' => 'CN-GB'));
        is(libi_charset_name("my-chinese1"), 'CN-GB', 'alias literal -- my-chinese1');
        is(libi_charset_name("my-chinese1"), libi_charset_name('EUC-CN'), 'alias equal -- my-chinese1');
        ok(I18N::Charset::add_libi_alias('my-chinese2' => 'EUC-CN'));
        is(libi_charset_name("my-chinese2"), 'CN-GB', 'alias literal -- my-chinese2');
        is(libi_charset_name("my-chinese2"), libi_charset_name('G.B.2312'), 'alias equal -- my-chinese2');
        ok(I18N::Charset::add_libi_alias('my-japanese' => 'x-x-sjis'));
        is(libi_charset_name("my-japanese"), 'MS_KANJI', 'alias literal -- my-japanese');
        is(libi_charset_name("my-japanese"), libi_charset_name('Shift_JIS'), 'alias equal -- my-japanese');
        pass; # I miscounted but I don't feel like going back and
              # changing all the 16 to 15 8-)
        } # end of SKIP block
      } # end of SKIP block
    } # end of SKIP block
  } # end of SKIP block
pass;

done_testing();

__END__

