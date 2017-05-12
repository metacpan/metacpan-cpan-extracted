use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/ELF/Extract/Sections.pm',
    'lib/ELF/Extract/Sections/Meta/Scanner.pm',
    'lib/ELF/Extract/Sections/Meta/Types.pm',
    'lib/ELF/Extract/Sections/Scanner/Objdump.pm',
    'lib/ELF/Extract/Sections/Section.pm',
    't/00-compile/lib_ELF_Extract_Sections_Meta_Scanner_pm.t',
    't/00-compile/lib_ELF_Extract_Sections_Meta_Types_pm.t',
    't/00-compile/lib_ELF_Extract_Sections_Scanner_Objdump_pm.t',
    't/00-compile/lib_ELF_Extract_Sections_Section_pm.t',
    't/00-compile/lib_ELF_Extract_Sections_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00-version-check.t',
    't/01-elf-libs.t',
    't/test_files/gen_expected.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
