
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTTP/Headers/Fancy.pm', 't/00-check-deps.t',
    't/00-compile.t',            't/author-critic.t',
    't/author-eol.t',            't/author-no-tabs.t',
    't/build.t',                 't/build_field_hash.t',
    't/build_field_list.t',      't/decode.t',
    't/decode_hash.t',           't/decode_key.t',
    't/encode.t',                't/encode_hash.t',
    't/encode_key.t',            't/etags.t',
    't/new.t',                   't/pretty.t',
    't/release-cpan-changes.t',  't/release-fixme.t',
    't/release-kwalitee.t',      't/release-pod-coverage.t',
    't/release-pod-syntax.t',    't/split.t',
    't/split_field_hash.t',      't/split_field_list.t'
);

notabs_ok($_) foreach @files;
done_testing;
