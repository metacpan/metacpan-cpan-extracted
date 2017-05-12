# -*- cperl -*-
use Test::More;

use warnings;
use strict;

my @modules;

BEGIN {
    @modules = qw(Lingua::FreeLing3
                  Lingua::FreeLing3::NEC
                  Lingua::FreeLing3::Word
                  Lingua::FreeLing3::Splitter
                  Lingua::FreeLing3::Sentence
                  Lingua::FreeLing3::Document
                  Lingua::FreeLing3::DepTxala
                  Lingua::FreeLing3::Paragraph
                  Lingua::FreeLing3::HMMTagger
                  Lingua::FreeLing3::Tokenizer
                  Lingua::FreeLing3::ParseTree
                  Lingua::FreeLing3::DepTree
                  Lingua::FreeLing3::ChartParser
                  Lingua::FreeLing3::RelaxTagger
                  Lingua::FreeLing3::MorphAnalyzer
                  Lingua::FreeLing3::Word::Analysis);

    plan tests => 1 + scalar(@modules)*2;

    use_ok 'Lingua::FreeLing3::Bindings';
    use_ok "$_" for @modules;


}

ok("${_}::VERSION" => "version defined for $_") for @modules;

