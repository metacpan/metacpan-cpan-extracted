
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
    'lib/HTML/Scrubber.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/01_use.t',
    't/02_basic.t',
    't/03_more.t',
    't/04_style_script.t',
    't/05_pi_comment.t',
    't/06_scrub_file.t',
    't/07_booleans.t',
    't/08_cb_attrs.t',
    't/09_memory_cycle.t',
    't/09_no_scrub_warnings.t',
    't/jvn53973084.t',
    't/rt19063_xhtml.t',
    't/rt25477_self_closing.t',
    't/rt72659_utf8.t',
    't/rt79044_multiple.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
