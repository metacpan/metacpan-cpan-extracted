
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Game/WordBrain.pm',
    'lib/Game/WordBrain/Letter.pm',
    'lib/Game/WordBrain/Prefix.pm',
    'lib/Game/WordBrain/Solution.pm',
    'lib/Game/WordBrain/Speller.pm',
    'lib/Game/WordBrain/Word.pm',
    'lib/Game/WordBrain/WordList.pm',
    'lib/Game/WordBrain/WordToFind.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/author-test-version.t',
    't/game/wordbrain/01-new.t',
    't/game/wordbrain/02-get_letter_at_position.t',
    't/game/wordbrain/03-find_near_letters.t',
    't/game/wordbrain/04-find_near_words.t',
    't/game/wordbrain/05-construct_game_without_word.t',
    't/game/wordbrain/06-solve.t',
    't/game/wordbrain/letter/01-new.t',
    't/game/wordbrain/letter/02-overload.t',
    't/game/wordbrain/prefix/01-new.t',
    't/game/wordbrain/prefix/02-is_start_of_word.t',
    't/game/wordbrain/solution/01-new.t',
    't/game/wordbrain/speller/01-new.t',
    't/game/wordbrain/speller/02-is_valid_word.t',
    't/game/wordbrain/word/01-new.t',
    't/game/wordbrain/word/02-word.t',
    't/game/wordbrain/word/03-overload.t',
    't/game/wordbrain/wordtofind/01-new.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pod-linkcheck.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
