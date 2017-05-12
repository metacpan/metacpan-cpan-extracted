use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

my @defs = $wn->Def('00448232-n');
is($defs[0], '日本版のレスリング');
is($defs[1], 'あなたが小さな輪から押し出された、あるいはもしあなたの体の一部（あなたの足を除いた）が地面についた場合、あなたの負けである');
is(scalar @defs, 2);

@defs = $wn->Def('00448232-n', 'jpn');
is($defs[0], '日本版のレスリング');
is($defs[1], 'あなたが小さな輪から押し出された、あるいはもしあなたの体の一部（あなたの足を除いた）が地面についた場合、あなたの負けである');
is(scalar @defs, 2);

@defs = $wn->Def('00448232-n', 'eng');
is($defs[0], 'a Japanese form of wrestling');
is($defs[1], 'you lose if you are forced out of a small ring or if any part of your body (other than your feet) touches the ground');
is(scalar @defs, 2);

warning_is { @defs = $wn->Def('12345678-v', 'eng') }
    'Def: there are no definition sentences for 12345678-v in eng',
    'definition sentences of unknown synset';

is(scalar @defs, 0);

done_testing;
