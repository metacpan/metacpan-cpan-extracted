
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;
use Test::Spelling;
add_stopwords(<DATA>);
set_spell_cmd("aspell -l en list");
all_pod_files_spelling_ok('lib');
__DATA__
Tatsuhiko
Miyagawa
Kazuho
Matsuno
Oku
Tokuhiro
