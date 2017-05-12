use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

my @exs = $wn->Ex('00810729-v');
is($exs[0], '彼女は悪事を見つけられずにすませます！');
is($exs[1], '私は、これらの責任下から逃れることができなかった');
is(scalar @exs, 2);

@exs = $wn->Ex('00810729-v', 'jpn');
is($exs[0], '彼女は悪事を見つけられずにすませます！');
is($exs[1], '私は、これらの責任下から逃れることができなかった');
is(scalar @exs, 2);

@exs = $wn->Ex('00810729-v', 'eng');
is($exs[0], 'She gets away with murder!');
is($exs[1],  "I couldn't get out from under these responsibilities");
is(scalar @exs, 2);

warning_is { @exs = $wn->Ex('12345678-v', 'eng') }
    'Ex: there are no example sentences for 12345678-v in eng',
    'example sentences of unknown synset';

is(scalar @exs, 0);

done_testing;
