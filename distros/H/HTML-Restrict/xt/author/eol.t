use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/Restrict.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attribute_constraints.t',
    't/comments.t',
    't/control-characters.t',
    't/create-newlines.t',
    't/declaration.t',
    't/empty-element-tags.t',
    't/filter_text.t',
    't/js.t',
    't/lowercase.t',
    't/malformed-html.t',
    't/memory-leak.t',
    't/perlcriticrc',
    't/pod.t',
    't/replace_img.t',
    't/scheme.t',
    't/stack.t',
    't/style.t',
    't/xss.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
