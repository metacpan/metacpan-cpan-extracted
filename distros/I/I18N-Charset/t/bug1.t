
use ExtUtils::testlib;
use Test::More;
unless (eval "require Encode")
  {
  plan skip_all => 'Encode is not installed';
  } # unless
plan tests => 3;
use_ok('I18N::Charset', 'enco_charset_name');
# There once was a bug in Charset.pm Where add_enco_alias() silently
# failed if it was called before enco_charset_name() was ever called.
ok(I18N::Charset::add_enco_alias('gb2312' => 'euc-cn'));
is(enco_charset_name("gb2312"),
   'euc-cn',
   'test literal -- big5');

__END__

