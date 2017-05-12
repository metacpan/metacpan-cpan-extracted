use strict;
use Test::More tests => 7;

BEGIN {
    use_ok 'Lingua::JA::Summarize::Extract';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Parser::Ngram';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Parser::NgramSimple';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Parser::Trim';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Sentence::Base';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Sentence::Tiny';
    use_ok 'Lingua::JA::Summarize::Extract::Plugin::Scoring::Base';
}
