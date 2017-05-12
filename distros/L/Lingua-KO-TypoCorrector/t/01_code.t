use strict;
use warnings;
use utf8;
use Test::More;
use Lingua::KO::TypoCorrector;

is(to_hangul('dkssudgktpdy'), '안녕하세요');
is(to_hangul('qksrkqtmqslek'), '반갑습니다');

done_testing();