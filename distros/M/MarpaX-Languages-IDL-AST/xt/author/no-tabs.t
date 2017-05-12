use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
