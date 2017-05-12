
use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception );
use Dist::Zilla::Util::EmulatePhase qw( -all );

# ABSTRACT: Make sure things explode

{
  package #
    Fake;
  sub plugins { [] }
}
ok( exception { get_plugins() },  'get_plugins croaks' );
ok( exception { get_metadata() }, 'get_metadata croaks' );
ok( exception { get_prereqs() },  'get_prereqs croaks' );
ok( !exception { get_plugins({ zilla => bless({}, 'main') }) }, "non-dzil get_plugins doesnt croaks" );
is( exception { get_plugins({ zilla => bless({}, 'Fake') }) }, undef, "non-dzil get_plugins doesnt croaks" );

done_testing;

