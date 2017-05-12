use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Gentoo/MetaEbuild/Spec/Base.pm',
    't/00-compile/lib_Gentoo_MetaEbuild_Spec_Base_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_load.t',
    't/02_fake_versions.t',
    't/03_fake_versions_missing.t',
    't/04_fake_versions_object.t',
    't/fake_spec/v0.1.0.json',
    't/fake_spec/v0.1.1.json'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
