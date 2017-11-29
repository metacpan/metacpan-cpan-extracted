use strict;
use warnings;

use Dist::Zilla::Tester;
use Test::More 0.88;
use Test::Fatal;

my $root = 'corpus/DZ_CheckChangesHasContent';

## Tests start here

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => $root },
  );
  ok( $tzil, "created test dist with no Changes file");

  $tzil->chrome->logger->set_debug(1);

  like(
    exception { $tzil->release },
    qr/No Changes file found|failed to find Changes in the distribution/i,
    "saw missing Changes file warning",
  );
  ok(
    ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease did not happen",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => $root },
    {
      add_files => {
        'source/Changes' => <<'END',
Changes

{{$NEXT}}

END
      },
    },
  );
  ok( $tzil, "created test dist with stub Changes file");

  $tzil->chrome->logger->set_debug(1);

  like(
    exception { $tzil->release },
    qr/Changes has no content for 1\.23/i,
    "saw empty Changes warning",
  );
  ok(
    ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease did not happen",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => $root },
    {
      add_files => {
        'source/Changes' => <<'END',
Changes

{{$NEXT}}

1.22    2010-05-12 00:33:53 EST5EDT

  - not really released

END
      },
    },
  );
  ok( $tzil, "created test dist with no new Changes");

  $tzil->chrome->logger->set_debug(1);

  like(
    exception { $tzil->release },
    qr/Changes has no content for 1\.23/i,
    "saw empty Changes warning",
  );
  ok(
    ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease did not happen",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

{
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => $root },
    {
      add_files => {
        'source/Changes' => <<'END',
Changes

{{$NEXT}}

  - this is a change note, I promise

1.22    2010-05-12 00:33:53 EST5EDT

  - not really released

END
      },
    },
  );

  ok( $tzil, "created test dist with a new Changes entry");

  $tzil->chrome->logger->set_debug(1);

  is(
    exception { $tzil->release },
    undef,
    'release proceeds normally',
  );

  ok(
    grep({ /Changes OK/i } @{ $tzil->log_messages }),
    "Saw Changes OK message",
  );
  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease happened",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

foreach my $version ( '1.23', '1.23-TRIAL' ){
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => $root },
    {
      add_files => {
        'source/Changes' => <<"END",
Changes

$version

  - this is a change note, I promise

1.22    2010-05-12 00:33:53 EST5EDT

  - not really released

END
      },
    },
  );
  ok( $tzil, "created test dist with a '\$version\\n' line");

  $tzil->chrome->logger->set_debug(1);

  is(
    exception { $tzil->release },
    undef,
    'release proceeds normally',
  );

  ok(
    grep({ /Changes OK/i } @{ $tzil->log_messages }),
    "Saw Changes OK message",
  );
  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease happened",
  );

  diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;
}

done_testing;
