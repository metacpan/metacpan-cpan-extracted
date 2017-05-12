use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/idl2moose',
    'lib/MarpaX/Languages/IDL/AST.pm',
    'lib/MarpaX/Languages/IDL/AST/Data/Scan/Impl/Perl5.pm',
    'lib/MarpaX/Languages/IDL/AST/Data/Scan/Impl/Perl5/_BaseTypes.pm',
    'lib/MarpaX/Languages/IDL/AST/Data/Scan/Impl/Perl5/_Perl5Types.pm',
    'lib/MarpaX/Languages/IDL/AST/Data/Scan/Impl/_Default.pm',
    'lib/MarpaX/Languages/IDL/AST/Data/Scan/Role/Consumer.pm',
    'lib/MarpaX/Languages/IDL/AST/MooseX/_BaseTypes.pm',
    'lib/MarpaX/Languages/IDL/AST/Util.pm',
    'lib/MarpaX/Languages/IDL/AST/Value.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/domLevel3.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
