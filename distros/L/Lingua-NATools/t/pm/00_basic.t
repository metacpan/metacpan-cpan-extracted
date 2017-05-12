# -*- cperl -*-

use Test::More;

my @modules = qw'
                    Lingua::NATools
                    Lingua::NATools::CGI
                    Lingua::NATools::Config
                    Lingua::NATools::Dict
                    Lingua::NATools::Corpus
                    Lingua::NATools::Client
                    Lingua::NATools::NATDict
                    Lingua::NATools::PCorpus
                    Lingua::NATools::Lexicon
                    Lingua::NATools::ConfigData
                ';

plan tests => scalar(@modules);

for my $module (@modules) {
    use_ok $module;
}
