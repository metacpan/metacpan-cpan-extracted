use strict;
use warnings;
use Test::More;
use HTTP::Entity::Parser::JSON;
use Hash::MultiValue;
use utf8;

my $parser = HTTP::Entity::Parser::JSON->new();
$parser->add('{');
$parser->add('"hoge":["fuga","hige","\u306b\u307b\u3093\u3054"],');
$parser->add('"moji":{"kanji":{"ji":"\u5b57"}},');
$parser->add('"\u306b\u307b\u3093\u3054":"\u65e5\u672c\u8a9e",');
$parser->add('"shallow":[{"deeper": "sunk"}],');
$parser->add('"moge":"muga"');
$parser->add('}');

my ($params, $uploads) = $parser->finalize();
is_deeply(Hash::MultiValue->new(@$params)->as_hashref_mixed,
  +{
    'hoge'     => [ 'fuga', 'hige', Encode::encode_utf8('にほんご') ],
    'moge'     => 'muga',
    'moji'     => { 'kanji' => { 'ji' => Encode::encode_utf8('字') } },
    'shallow'  => [ { 'deeper' => 'sunk' } ],
    Encode::encode_utf8('にほんご') => Encode::encode_utf8('日本語'),
  });
is_deeply $uploads, [];

done_testing;

