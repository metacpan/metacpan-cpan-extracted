use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Graph/Easy/As_svg.pm',
    't/00-compile.t',
    't/group.t',
    't/output.t',
    't/pod.t',
    't/pod_cov.t',
    't/svg.t',
    't/svg/svg.txt',
    't/text.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
