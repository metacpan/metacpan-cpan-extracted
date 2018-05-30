use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Mail/LMLM.pm',
    'lib/Mail/LMLM/Object.pm',
    'lib/Mail/LMLM/Render.pm',
    'lib/Mail/LMLM/Render/HTML.pm',
    'lib/Mail/LMLM/Types/Base.pm',
    'lib/Mail/LMLM/Types/Egroups.pm',
    'lib/Mail/LMLM/Types/Ezmlm.pm',
    'lib/Mail/LMLM/Types/GoogleGroups.pm',
    'lib/Mail/LMLM/Types/Listar.pm',
    'lib/Mail/LMLM/Types/Listserv.pm',
    'lib/Mail/LMLM/Types/Mailman.pm',
    'lib/Mail/LMLM/Types/Majordomo.pm',
    't/00-compile.t',
    't/use.t'
);

notabs_ok($_) foreach @files;
done_testing;
