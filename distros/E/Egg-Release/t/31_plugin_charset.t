use Test::More;
use lib qw( ../lib ./lib );
use Egg::Helper;

eval{ require Jcode };
if ($@) { plan skip_all=> "Jcode is not installed." } else {

plan tests=> 21;

my $s= 'ＭＶＣフレームワーク';

my $e= Egg::Helper->run( Vtest=> {
  vtest_name    => 'euc_jp',
  vtest_plugins => [qw/ Charset::EUC_JP /],
  } );

is $e->config->{content_language}, 'ja',
   q{$e->config->{content_language}, 'ja'};
is $e->config->{content_type}, 'text/html',
   q{$e->config->{content_type}, 'text/html'};
is $e->config->{charset_out}, 'euc-jp',
   q{$e->config->{charset_out}, 'euc-jp'};

can_ok $e, '_output';
can_ok $e, '_convert_output_body';
  my $str= $s;
  ok $e->_convert_output_body(\$str), q{$e->_convert_output_body(\$str)};
  is Jcode::getcode($str), 'euc', q{Jcode::getcode($str), 'euc'};

$e= Egg::Helper->run( Vtest=> {
  vtest_name=> 'sjis',
  vtest_plugins=> [qw/ Charset::Shift_JIS /],
  } );

is $e->config->{content_language}, 'ja',
   q{$e->config->{content_language}, 'ja'};
is $e->config->{content_type}, 'text/html',
   q{$e->config->{content_type}, 'text/html'};
is $e->config->{charset_out}, 'Shift_JIS',
   q{$e->config->{charset_out}, 'Shift_JIS'};

can_ok $e, '_output';
can_ok $e, '_convert_output_body';
  $str= $s;
  ok $e->_convert_output_body(\$str), q{$e->_convert_output_body(\$str)};
  is Jcode::getcode($str), 'sjis', q{Jcode::getcode($str), 'sjis'};

$e= Egg::Helper->run( Vtest=> {
  vtest_name=> 'utf8',
  vtest_plugins=> [qw/ Charset::UTF8 /],
  } );

is $e->config->{content_language}, 'ja',
   q{$e->config->{content_language}, 'ja'};
is $e->config->{content_type}, 'text/html',
   q{$e->config->{content_type}, 'text/html'};
is $e->config->{charset_out}, 'utf-8',
   q{$e->config->{charset_out}, 'utf-8'};

can_ok $e, '_output';
can_ok $e, '_convert_output_body';
  $str= $s;
  ok $e->_convert_output_body(\$str), q{$e->_convert_output_body(\$str)};
  is Jcode::getcode($str), 'utf8', q{Jcode::getcode($str), 'utf8'};

}
