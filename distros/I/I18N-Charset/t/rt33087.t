
use blib;
use Test::More;
unless (eval "require Unicode::Map8")
  {
  plan skip_all => 'Unicode::Map8 is not installed';
  } # unless
plan tests => 3;
use_ok('I18N::Charset', qw( iana_charset_name map8_charset_name ));

is(iana_charset_name("koi8-r"), 'KOI8-R', 'iana literal koi8-r');
is(map8_charset_name("Koi 8 R"), 'koi8-r', 'map8 literal koi8-r');

done_testing();

__END__

