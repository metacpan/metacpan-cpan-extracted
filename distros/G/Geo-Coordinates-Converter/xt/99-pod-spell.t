use strict;
use Test::More;

BEGIN {
    eval "use Test::Spelling";
    plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
}

add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');

__DATA__
Kazuhiro
Osawa
shibuya
lat
lng
geo
formatter
orthogonalization
