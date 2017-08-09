use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/m4pp',
    'lib/MarpaX/Languages/M4.pm',
    'lib/MarpaX/Languages/M4/Impl/Default.pm',
    'lib/MarpaX/Languages/M4/Impl/Default/BaseConversion.pm',
    'lib/MarpaX/Languages/M4/Impl/Default/Eval.pm',
    'lib/MarpaX/Languages/M4/Impl/Input.pm',
    'lib/MarpaX/Languages/M4/Impl/Macro.pm',
    'lib/MarpaX/Languages/M4/Impl/Macros.pm',
    'lib/MarpaX/Languages/M4/Impl/Parser.pm',
    'lib/MarpaX/Languages/M4/Impl/Parser/Actions.pm',
    'lib/MarpaX/Languages/M4/Impl/Regexp.pm',
    'lib/MarpaX/Languages/M4/Impl/Value.pm',
    'lib/MarpaX/Languages/M4/Role/Builtin.pm',
    'lib/MarpaX/Languages/M4/Role/Impl.pm',
    'lib/MarpaX/Languages/M4/Role/Input.pm',
    'lib/MarpaX/Languages/M4/Role/Logger.pm',
    'lib/MarpaX/Languages/M4/Role/Macro.pm',
    'lib/MarpaX/Languages/M4/Role/Macros.pm',
    'lib/MarpaX/Languages/M4/Role/Parser.pm',
    'lib/MarpaX/Languages/M4/Role/Regexp.pm',
    'lib/MarpaX/Languages/M4/Role/Value.pm',
    'lib/MarpaX/Languages/M4/Type/Impl.pm',
    'lib/MarpaX/Languages/M4/Type/Input.pm',
    'lib/MarpaX/Languages/M4/Type/Logger.pm',
    'lib/MarpaX/Languages/M4/Type/Macro.pm',
    'lib/MarpaX/Languages/M4/Type/Regexp.pm',
    'lib/MarpaX/Languages/M4/Type/Token.pm',
    'lib/MarpaX/Languages/M4/Type/Value.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/m4.t'
);

notabs_ok($_) foreach @files;
done_testing;
