use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1
);

my @words = $wn->Word('00448232-n');
is_deeply(\@words, [qw/大相撲 角力 角技 相撲/]);

@words = $wn->Word('00448232-n', 'jpn');
is_deeply(\@words, [qw/大相撲 角力 角技 相撲/]);

@words = $wn->Word('00448232-n', 'eng');
is_deeply(\@words, [qw/sumo/]);

warning_is { @words = $wn->Word('3939-miku', 'negi') }
    'Word: there are no words for 3939-miku in negi', 'word of unknown synset';

is(scalar @words, 0);

done_testing;
