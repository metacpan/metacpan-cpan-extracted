use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Spelling];
    plan(skip_all => "Test::Spelling required for testing spelling") if $@;
}

my @stopwords = split /\n/, <<'EOF';
Tokuhiro
Matsuno
IP
ip
yaml
EOF

add_stopwords(@stopwords);
all_pod_files_spelling_ok;

