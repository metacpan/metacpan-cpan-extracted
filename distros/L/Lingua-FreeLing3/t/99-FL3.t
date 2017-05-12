#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::More tests => 57;

use FL3 'es';
ok 1 => 'Loaded ok';

my $text = <<EOT;
Los partidos políticos expresan el pluralismo político, concurren a la
formación y manifestación de la voluntad popular y son instrumento
fundamental para la participación política. Su creación y el ejercicio
de su actividad son libres dentro del respeto a la Constitución y a la
Ley. Su estructura interna y funcionamiento deberán ser democráticos.
EOT

isa_ok splitter()  => 'Lingua::FreeLing3::Splitter';
isa_ok tokenizer() => 'Lingua::FreeLing3::Tokenizer';

# faster... just one init of morph for 'pt'
isa_ok morph(RetokContractions => 0) => 'Lingua::FreeLing3::MorphAnalyzer';
isa_ok hmm()       => 'Lingua::FreeLing3::HMMTagger';
isa_ok relax()     => 'Lingua::FreeLing3::RelaxTagger';
isa_ok chart()     => 'Lingua::FreeLing3::ChartParser';
isa_ok txala()     => 'Lingua::FreeLing3::DepTxala';
isa_ok nec()       => 'Lingua::FreeLing3::NEC';

ok ((splitter('en') eq splitter('en')) => "cache works");

my $words = tokenizer->tokenize($text);
ok $words => 'Tokenizer did something';
isa_ok $words, 'ARRAY' => 'Tokenizer result';
isa_ok $words->[0], 'Lingua::FreeLing3::Word' => 'Tokenizers result first element';

my $sentences = splitter->split($words);
ok $sentences => 'Splitter returns something';
isa_ok $sentences, 'ARRAY' => 'Spliter result';
isa_ok $sentences->[0], 'Lingua::FreeLing3::Sentence'
  => 'Spliters result first element';

$sentences = morph()->analyze($sentences);
ok $sentences => 'MorphAnalyzer returns something';
isa_ok $sentences, 'ARRAY' => 'MorphAnalyzer result';
isa_ok $sentences->[0], 'Lingua::FreeLing3::Sentence'
  => 'MorphAnalyzer result first element';

$sentences = relax->analyze($sentences);
ok $sentences => 'RelaxTagger returns something';
isa_ok $sentences, 'ARRAY' => 'RelaxTagger result';
isa_ok $sentences->[0], 'Lingua::FreeLing3::Sentence'
  => 'RelaxTagger result first element';

ok !$sentences->[0]->is_parsed, 'Sentence is not yet parsed';
$sentences = chart->parse($sentences);
ok $sentences => 'ChartParser returns something';
isa_ok $sentences, 'ARRAY' => 'ChartParser result';
isa_ok $sentences->[0], 'Lingua::FreeLing3::Sentence'
  => 'ChartParser result first element';
ok $sentences->[0]->is_parsed, 'Sentence is parsed';
isa_ok $sentences->[0]->parse_tree => 'Lingua::FreeLing3::ParseTree';

ok !$sentences->[0]->is_dep_parsed, 'Sentence is not dep parsed yet';
$sentences = txala->parse($sentences);
ok $sentences => 'Txala returns something';
isa_ok $sentences, 'ARRAY' => 'Txala result';
isa_ok $sentences->[0], 'Lingua::FreeLing3::Sentence'
  => 'Txala result first element';
ok $sentences->[0]->is_dep_parsed, 'Sentence is dep parsed';
isa_ok $sentences->[0]->dep_tree => 'Lingua::FreeLing3::DepTree';

# release some memory;
release_language('es');
undef $sentences;
undef $words;

my $more_text = <<EOT;
О ранних годах жизни Амундсена известно немногое. Детство его прошло в
лесах, окружавших родительскую усадьбу, в компании братьев и соседских
детей (доходившей до 40 человек), в которой Руаль был самым
младшим. Братья Амундсен охотно участвовали в драках; Руаля в то время
описывали как «высокомерного мальчика», которого легко было
разозлить. Одним из его товарищей по играм был будущий исследователь
Антарктики Карстен Борхгревинк.
EOT

my $more_words = tokenizer('ru')->tokenize($more_text);
ok $more_words => 'Tokenizer(ru) did something';
isa_ok $more_words, 'ARRAY' => 'Tokenizer(ru) result';
isa_ok $more_words->[0], 'Lingua::FreeLing3::Word' => 'Tokenizer(ru) result first element';

my $more_sentences = splitter('ru')->split($more_words);
ok $more_sentences => 'Splitter(ru) returns something';
isa_ok $more_sentences, 'ARRAY' => 'Spliter(ru) result';
isa_ok $more_sentences->[0], 'Lingua::FreeLing3::Sentence' => 'Spliter(ru) result first element';

$more_sentences = morph('ru')->analyze($more_sentences);
ok $more_sentences => 'Morph(ru) returns something';
isa_ok $more_sentences, 'ARRAY' => 'Morph(ru) result';
isa_ok $more_sentences->[0], 'Lingua::FreeLing3::Sentence' => 'Morph(ru) result first element';

$more_sentences = hmm('ru')->tag($more_sentences);
ok $more_sentences => 'HMM(ru) returns something';
isa_ok $more_sentences, 'ARRAY' => 'HMM(ru) result';
isa_ok $more_sentences->[0], 'Lingua::FreeLing3::Sentence' => 'HMM(ru) result first element';

my $ww = word("cavalo");
ok $ww => "We have a word";
isa_ok $ww => 'Lingua::FreeLing3::Word';
is $ww->form, "cavalo";

my ($w1, $w2) = word("olá", "mundo");
ok $w1;
ok $w2;
isa_ok $w1 => "Lingua::FreeLing3::Word";
isa_ok $w2 => "Lingua::FreeLing3::Word";
is $w1->form, "olá";
is $w2->form, "mundo";

my $s = sentence($ww,$w1,$w2);
ok $s;
isa_ok $s => "Lingua::FreeLing3::Sentence";
