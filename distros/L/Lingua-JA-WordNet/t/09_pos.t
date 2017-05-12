use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

is($wn->Pos('00000001-n'), 'n');
is($wn->Pos('00000002-v'), 'v');
is($wn->Pos('00000003-a'), 'a');
is($wn->Pos('00000004-r'), 'r');

my $pos = 'n';


warning_is { $pos = $wn->Pos('00000005-z') }
    "Pos: '00000005-z' is wrong synset format",
    'strange synset format';

is($pos, undef);


warning_is { $pos = $wn->Pos('000000001-n') }
    "Pos: '000000001-n' is wrong synset format",
    'strange synset format';

is($pos, undef);


warning_is { $pos = $wn->Pos('miku') }
    "Pos: 'miku' is wrong synset format",
    'strange synset format';

is($pos, undef);


done_testing;
