#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open ':encoding(UTF-8)', ':std';
use Test::More tests => 6;

BEGIN {
    use_ok('Lingua::LO::NLP::Data');
    use_ok('Lingua::LO::NLP::Syllabify');
    use_ok('Lingua::LO::NLP::Analyze');
    use_ok('Lingua::LO::NLP::Romanize');
    use_ok('Lingua::LO::NLP::Romanize::PCGN');
    use_ok('Lingua::LO::NLP');
}



