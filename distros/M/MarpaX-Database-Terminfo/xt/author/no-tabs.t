use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MarpaX/Database/Terminfo.pm',
    'lib/MarpaX/Database/Terminfo/Constants.pm',
    'lib/MarpaX/Database/Terminfo/Grammar.pm',
    'lib/MarpaX/Database/Terminfo/Grammar/Actions.pm',
    'lib/MarpaX/Database/Terminfo/Grammar/CharacterClasses.pm',
    'lib/MarpaX/Database/Terminfo/Grammar/Regexp.pm',
    'lib/MarpaX/Database/Terminfo/Interface.pm',
    'lib/MarpaX/Database/Terminfo/String.pm',
    'lib/MarpaX/Database/Terminfo/String/Grammar.pm',
    'lib/MarpaX/Database/Terminfo/String/Grammar/Actions.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/putp.t',
    't/test1.t',
    't/test2.t',
    't/tgetent.t',
    't/tgetflag.t',
    't/tgetnum.t',
    't/tgetstr.t',
    't/tgoto.t',
    't/tigetflag.t',
    't/tigetnum.t',
    't/tigetstr.t',
    't/tparm.t',
    't/tparm_using_txt_stubs.t',
    't/tputs_delay_NO_PC.t',
    't/tputs_delay_PC.t',
    't/tvgetflag.t',
    't/tvgetnum.t',
    't/tvgetstr.t'
);

notabs_ok($_) foreach @files;
done_testing;
