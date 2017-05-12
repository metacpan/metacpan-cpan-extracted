use strict;
use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => "Spelling tests only for authors"
        unless -d 'inc/.author';

    eval 'use Test::Spelling';
    plan skip_all => 'Test::Spelling required for this test' if $@;
}

add_stopwords(qw/Thirlwall uncatch/);
all_pod_files_spelling_ok();
