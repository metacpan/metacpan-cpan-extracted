use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/FromANSI/Tiny.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/ansi_parser.t',
    't/class_prefix.t',
    't/css.t',
    't/encoding.t',
    't/exports.t',
    't/html.t',
    't/html_encode.t',
    't/inline_style.t',
    't/no_plain_tags.t',
    't/tag.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
