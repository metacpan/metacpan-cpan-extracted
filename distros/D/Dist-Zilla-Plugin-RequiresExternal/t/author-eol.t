
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/RequiresExternal.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/fatal.t',
    't/release-changes_has_content.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-localbrew-perl-5.10.1-TEST.t',
    't/release-localbrew-perl-5.12.5-TEST.t',
    't/release-localbrew-perl-5.14.4-TEST.t',
    't/release-localbrew-perl-5.16.3-TEST.t',
    't/release-localbrew-perl-5.18.4-TEST.t',
    't/release-localbrew-perl-5.20.3-TEST.t',
    't/release-localbrew-perl-5.22.1-TEST.t',
    't/release-localbrew-perl-latest-TEST.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-pod-linkcheck.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-system-localbrew.t',
    't/release-unused-vars.t',
    't/test.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
