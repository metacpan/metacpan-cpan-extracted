use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;
use Test::Deep;

use if !$ENV{AUTHOR_TESTING}, 'Test::RequiresInternet' => ('cpanmetadb.plackperl.org' => 80);

{
  package SimpleOptionalFeatures;
  use Moose;
  with 'Dist::Zilla::Role::MetaProvider';
  sub metadata {
    return +{
      optional_features => {
        'Silly_Walks' => {
          description => 'all things silly walk here',
          prereqs => {
            runtime => {
              requires => {
                'Silly::Walks' => '0',
              },
            },
          },
        },
      },
    };
  }
}

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        [ GatherDir => ],
        [ Prereqs => { 'strict' => 0 } ],
        [ '=SimpleOptionalFeatures' ],
        [ CheckPrereqsIndexed => ],
        [ FakeRelease => ],
      ),
    },
  },
);

$tzil->chrome->logger->set_debug(1);

like(
  exception { $tzil->release },
  qr/aborting release due to apparently unindexed prereqs/,
  'release was aborted',
);

cmp_deeply(
  $tzil->log_messages,
  superbagof(
  "[CheckPrereqsIndexed] the following prereqs could not be found on CPAN: Silly::Walks",
  ),
  'found dependency on an optional feature that will not be satisfied by the current release',
);

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

done_testing;
