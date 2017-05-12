use strict;
use warnings;
use Test::More;
use HTTP::Entity::Parser::JSON;
use Hash::MultiValue;
use utf8;

my $parser = HTTP::Entity::Parser::JSON->new();
$parser->add('{');
$parser->add('"hoge":["fuga","hige"],');
$parser->add('"\u306b\u307b\u3093\u3054":"\u65e5\u672c\u8a9e",');
$parser->add('"moge":"muga"');
$parser->add('}');

my ($params, $uploads) = $parser->finalize();
is_deeply(Hash::MultiValue->new(@$params)->as_hashref_multi,
  +{
    'hoge'     => [ 'fuga', 'hige' ],
    'moge'     => ['muga'],
    Encode::encode_utf8('にほんご') => [Encode::encode_utf8('日本語')],
  });
is_deeply $uploads, [];

done_testing;

