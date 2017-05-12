
use strict;
use warnings;

use Test::More;

# FILENAME: 01-basic.t
# CREATED: 03/23/14 19:41:51 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic interface test

use Test::DZil qw(simple_ini Builder);
use Path::Tiny qw( path );
use Test::Differences qw( eq_or_diff );

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => simple_ini(
        [ 'Prereqs', { 'Foo' => 1 } ],                                                                               #
        [ 'Prereqs::Soften', { 'module' => 'Foo', 'to_relationship' => 'none', copy_to => 'develop.requires' } ],    #
        ['GatherDir'],                                                                                               #
      ),
      path( 'source', 'lib', 'E.pm' ) => <<'EO_EPM',
use strict;
use warnings;

package E;

# ABSTRACT: Fake dist stub

use Moose;
with 'Dist::Zilla::Role::Plugin';

1;

EO_EPM

    }
  }
);

$tzil->chrome->logger->set_debug(1);

$tzil->build;

eq_or_diff(
  $tzil->prereqs->as_string_hash,
  {
    develop => { requires => { 'Foo' => '1' } },
  }
);

done_testing;

