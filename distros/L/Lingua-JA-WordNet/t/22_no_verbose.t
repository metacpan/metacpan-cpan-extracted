use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(verbose => 0);
warning_is { $wn->Word('hogehoge', 'jpn') } '';
warning_is { $wn->Synset('fugafuga', 'jpn') } '';
warning_is { $wn->SynPos('karikari', 'n', 'jpn') } '';
warning_is { $wn->Rel('mofumofu', 'hype') } '';
warning_is { $wn->Def('peropero', 'jpn') } '';
warning_is { $wn->Ex('mochimochi', 'jpn') } '';
warning_is { $wn->Pos('fuwafuwa') } '';
warning_is { $wn->WordID('mikumiku') } '';
warning_is { $wn->Synonym('rukaruka') } '';

$wn = Lingua::JA::WordNet->new; # default value of verbose option is 0
warning_is { $wn->Word('hogehoge', 'jpn') } '';
warning_is { $wn->Synset('fugafuga', 'jpn') } '';
warning_is { $wn->SynPos('karikari', 'n', 'jpn') } '';
warning_is { $wn->Rel('mofumofu', 'hype') } '';
warning_is { $wn->Def('peropero', 'jpn') } '';
warning_is { $wn->Ex('mochimochi', 'jpn') } '';
warning_is { $wn->Pos('fuwafuwa') } '';
warning_is { $wn->WordID('mikumiku') } '';
warning_is { $wn->Synonym('rukaruka') } '';

done_testing;
