use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MarpaX/ESLIF.pm',
    'lib/MarpaX/ESLIF/BNF.pod',
    'lib/MarpaX/ESLIF/Base.pm',
    'lib/MarpaX/ESLIF/Bindings.pod',
    'lib/MarpaX/ESLIF/Event/Type.pm',
    'lib/MarpaX/ESLIF/Grammar.pm',
    'lib/MarpaX/ESLIF/Grammar/Properties.pm',
    'lib/MarpaX/ESLIF/Grammar/Rule/Properties.pm',
    'lib/MarpaX/ESLIF/Grammar/Symbol/Properties.pm',
    'lib/MarpaX/ESLIF/Introduction.pod',
    'lib/MarpaX/ESLIF/JSON.pm',
    'lib/MarpaX/ESLIF/JSON/Decoder.pm',
    'lib/MarpaX/ESLIF/JSON/Decoder/RecognizerInterface.pm',
    'lib/MarpaX/ESLIF/JSON/Encoder.pm',
    'lib/MarpaX/ESLIF/Logger/Interface.pod',
    'lib/MarpaX/ESLIF/Logger/Level.pm',
    'lib/MarpaX/ESLIF/Recognizer.pm',
    'lib/MarpaX/ESLIF/Recognizer/Interface.pod',
    'lib/MarpaX/ESLIF/RegexCallout.pm',
    'lib/MarpaX/ESLIF/Rule/PropertyBitSet.pm',
    'lib/MarpaX/ESLIF/String.pm',
    'lib/MarpaX/ESLIF/Symbol.pm',
    'lib/MarpaX/ESLIF/Symbol/EventBitSet.pm',
    'lib/MarpaX/ESLIF/Symbol/PropertyBitSet.pm',
    'lib/MarpaX/ESLIF/Symbol/Type.pm',
    'lib/MarpaX/ESLIF/Tutorial/Calculator.pod',
    'lib/MarpaX/ESLIF/Value.pm',
    'lib/MarpaX/ESLIF/Value/Interface.pod',
    'lib/MarpaX/ESLIF/Value/Type.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/advent.t',
    't/allluacallbacks.t',
    't/import_export.t',
    't/json.t',
    't/jsonWithSharedStream.t',
    't/parameterizedRules.t',
    't/resolver.t',
    't/symbol.t',
    't/test.t',
    't/thread.t'
);

notabs_ok($_) foreach @files;
done_testing;
