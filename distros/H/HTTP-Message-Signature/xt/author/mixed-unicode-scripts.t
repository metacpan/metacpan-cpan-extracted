use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

my @files = (
    'lib/HTTP/Message/Signature.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-base.t',
    't/01-structured-split.t',
    't/02-test-data.t',
    't/web_bot_auth_architecture_v2.json'
);

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
