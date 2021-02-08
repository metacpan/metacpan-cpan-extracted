# umap.t - tests for Unicode::Map functionality of I18N::Charset

use I18N::Charset;
use Test::More;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use strict;

#================================================
# TESTS FOR umap routines
#================================================

my @aa;
#---- selection of examples which should all result in undef -----------
ok(!defined umap_charset_name(), 'no argument');
ok(!defined umap_charset_name(undef), 'undef argument');
ok(!defined umap_charset_name(""), 'empty argument');
ok(!defined umap_charset_name("junk"), 'junk argument');
ok(!defined umap_charset_name(999999), '999999 argument');
ok(!defined umap_charset_name(\@aa), 'arrayref argument');
$oICE->start;
ok(!defined(I18N::Charset::add_umap_alias("alias1" => "junk")), '+alias1');
$oICE->stop;
ok(!defined umap_charset_name("alias1"), '=alias1');

SKIP:
  {
  skip 'Unicode::Map is not installed', 8 unless eval "require Unicode::Map";

  #---- some successful examples -----------------------------------------
  ok(umap_charset_name("apple symbol") eq "APPLE-SYMBOL", 'dummy mib');
  ok(umap_charset_name("Adobe Ding Bats") eq "ADOBE-DINGBATS", 'dummy mib');
  ok(umap_charset_name("cs IBM-037") eq "CP037", 'same as iana');
  ok(umap_charset_name("CP037") eq "CP037", 'identical');

  #---- some aliasing examples -------------------------------------------
  ok(I18N::Charset::add_umap_alias("alias2" => "IBM775") eq "CP775", '+alias2');
  ok(umap_charset_name("alias2") eq "CP775", '=alias2');

  ok(I18N::Charset::add_umap_alias("alias3" => "alias2") eq "CP775", '+alias3');
  ok(umap_charset_name("alias3") eq "CP775", '=alias3');
  } # end of SKIP block

done_testing();

__END__

