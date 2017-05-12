use strict;
use warnings;

use Test::More;

# FILENAME: as_cmd.t
# CREATED: 08/03/14 15:25:06 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Make sure as_cmd works.

use Dist::Zilla::Util::CurrentCmd qw( as_cmd is_install is_build current_cmd );

subtest with_cmd => sub {
  as_cmd(
    'foo' => sub {
      is( current_cmd(), 'foo', 'Arbitrary command names pass through' );
    },
  );

  as_cmd(
    'install' => sub {
      is( current_cmd(), 'install', 'install pass through' );
      ok( is_install, 'is_install is true' );
    },
  );

  as_cmd(
    'build' => sub {
      is( current_cmd(), 'build', 'build pass through' );
      ok( is_build, 'is_build is true' );
    },
  );
};

subtest without_cmd => sub {
  isnt( current_cmd(), 'foo',     'foo doesnt turn up without a cmd running' );
  isnt( current_cmd(), 'install', 'install doesnt pass through without a cmd running' );
  isnt( current_cmd(), 'build',   'build doesnt pass through without a cmd running' );
  ok( !is_install(), 'is_install is false' );
  ok( !is_build(),   'is_build is false' );
};
done_testing;

