use utf8;
use strict;
use warnings;
use Test::More;

eval 'use Test::Spelling';
plan skip_all => 'Test::Spelling not installed; skipping' if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
casefold
casefolding
CPAN
hashrefs
IETF
Shutterstock
stemmer
TODO
