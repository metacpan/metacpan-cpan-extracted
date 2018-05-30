use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
