use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MarpaX/ESLIF.pm',
    'lib/MarpaX/ESLIF/BNF.pod',
    'lib/MarpaX/ESLIF/Event/Type.pm',
    'lib/MarpaX/ESLIF/Grammar.pm',
    'lib/MarpaX/ESLIF/Grammar/Properties.pm',
    'lib/MarpaX/ESLIF/Grammar/Rule/Properties.pm',
    'lib/MarpaX/ESLIF/Grammar/Symbol/Properties.pm',
    'lib/MarpaX/ESLIF/Introduction.pod',
    'lib/MarpaX/ESLIF/Logger/Interface.pod',
    'lib/MarpaX/ESLIF/Logger/Level.pm',
    'lib/MarpaX/ESLIF/Recognizer.pod',
    'lib/MarpaX/ESLIF/Recognizer/Interface.pod',
    'lib/MarpaX/ESLIF/Rule/PropertyBitSet.pm',
    'lib/MarpaX/ESLIF/Symbol/PropertyBitSet.pm',
    'lib/MarpaX/ESLIF/Symbol/Type.pm',
    'lib/MarpaX/ESLIF/Tutorial/Calculator.pod',
    'lib/MarpaX/ESLIF/Value.pod',
    'lib/MarpaX/ESLIF/Value/Interface.pod',
    'lib/MarpaX/ESLIF/Value/Type.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/advent.t',
    't/test.t',
    't/thread.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
