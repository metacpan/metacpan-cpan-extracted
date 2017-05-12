use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Exception;

my $wn = Lingua::JA::WordNet->new;
isa_ok($wn, 'Lingua::JA::WordNet');
can_ok('Lingua::JA::WordNet', qw/Word Synset SynPos Pos Rel Def Ex AllSynsets WordID Synonym/);

throws_ok { Lingua::JA::WordNet->new('./hoge/hage/hige.db'); } qr/WordNet data file is not found/;
throws_ok { Lingua::JA::WordNet->new('./share/');            } qr/WordNet data file is not found/;
throws_ok { Lingua::JA::WordNet->new(data => './hage.db');   } qr/WordNet data file is not found/;
throws_ok { Lingua::JA::WordNet->new(sqlite_unicode => 1);   } qr/Unknown option: 'sqlite_unicode'/;


my %config = (
    enable_utf8 => 1,
    verbose     => 1,
);

lives_ok { Lingua::JA::WordNet->new(%config); } qr/valid config/;

lives_ok { $wn = Lingua::JA::WordNet->new(data => './wordnet/test.db'); } qr/valid config/;

my @words = $wn->Word('00000001-n', 'jpn');
is($words[0], 'ミク');

done_testing;
