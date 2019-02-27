use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Job/Async.pm',
    'lib/Job/Async.pod',
    'lib/Job/Async/Client.pm',
    'lib/Job/Async/Client.pod',
    'lib/Job/Async/Client/Memory.pm',
    'lib/Job/Async/Client/Memory.pod',
    'lib/Job/Async/Job.pm',
    'lib/Job/Async/Test/Compliance.pm',
    'lib/Job/Async/Test/Compliance.pod',
    'lib/Job/Async/Utils.pm',
    'lib/Job/Async/Worker.pm',
    'lib/Job/Async/Worker.pod',
    'lib/Job/Async/Worker/Memory.pm',
    'lib/Job/Async/Worker/Memory.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/api.t',
    't/compliance.t',
    't/uuid.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
