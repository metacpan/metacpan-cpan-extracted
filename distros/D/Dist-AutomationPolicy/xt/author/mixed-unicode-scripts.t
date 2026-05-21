use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/Dist/AutomationPolicy.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-common.t',
    't/02-synopsis.t'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
