use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/JSON/Meth.pm',
    't/00-compile.t',
    't/01-meth.t',
    't/02-overloads.t',
    't/03-objects.t',
    't/04-json-var-export.t',
    't/05-undef.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
