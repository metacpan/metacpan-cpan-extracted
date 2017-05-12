use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MetaPOD.pm',
    'lib/MetaPOD/Assembler.pm',
    'lib/MetaPOD/Exception.pm',
    'lib/MetaPOD/Exception/Decode/Data.pm',
    'lib/MetaPOD/Extractor.pm',
    'lib/MetaPOD/Result.pm',
    'lib/MetaPOD/Role/Format.pm',
    't/00-compile/lib_MetaPOD_Assembler_pm.t',
    't/00-compile/lib_MetaPOD_Exception_Decode_Data_pm.t',
    't/00-compile/lib_MetaPOD_Exception_pm.t',
    't/00-compile/lib_MetaPOD_Extractor_pm.t',
    't/00-compile/lib_MetaPOD_Result_pm.t',
    't/00-compile/lib_MetaPOD_Role_Format_pm.t',
    't/00-compile/lib_MetaPOD_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-extractor/01-basic.t',
    't/02-role-formatter/01-supported.t',
    't/03-result/01-basic.t',
    't/04-assembler/01-basic.t',
    't/self-extract.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
