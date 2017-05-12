use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/BNF.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Impl/Segment.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Impl/_top.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/MarpaTrace.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Role/_common.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Role/_generic.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Setup.pm',
    'lib/MarpaX/Role/Parameterized/ResourceIdentifier/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
