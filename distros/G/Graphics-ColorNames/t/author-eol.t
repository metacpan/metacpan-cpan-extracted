
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Graphics/ColorNames.pm',
    'lib/Graphics/ColorNames/X.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-exports.t',
    't/02-X.t',
    't/03-oo.t',
    't/04-precedence.t',
    't/05-tied.t',
    't/07-file.t',
    't/08-filehandle.t',
    't/09-colorlibrary.t',
    't/10-sub.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/lib/Graphics/ColorNames/Test.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
