use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/File/Rotate/Simple.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001-_rotated_name.t',
    't/100-default.t',
    't/100-legacy.t',
    't/101-CVE-2026-17435.t',
    't/200-exports.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
