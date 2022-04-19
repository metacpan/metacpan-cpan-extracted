use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::DZil;
use Test::Deep;
use Path::Tiny 0.062;

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path(qw(source dist.ini)) => simple_ini(
        [ GatherDir => ],
        [ 'ModuleBuildTiny::Fallback' ],
      ),
      path(qw(source share foo)) => 'this is some sharedir content',
    },
  },
);

$tzil->chrome->logger->set_debug(1);
is(
  exception { $tzil->build },
  undef,
  'build proceeds normally',
);

cmp_deeply(
  $tzil->log_messages,
  superbagof(
    re(qr{\Q[ModuleBuildTiny::Fallback] share/ files present: did you forget to include [ShareDir]?\E}),
  ),
  'warning is presented if [ShareDir] might have been forgotten',
);

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

done_testing;
