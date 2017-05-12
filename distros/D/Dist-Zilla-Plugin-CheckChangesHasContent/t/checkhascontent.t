#!perl

use strict;
use warnings;

use Capture::Tiny qw/capture/;
use Dist::Zilla::Tester;
use Test::More 0.88;
use Try::Tiny;

my $root = 'corpus/DZ_CheckChangesHasContent';

## Tests start here

{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => $root },
    );
    ok( $tzil, "created test dist with no Changes file");

    capture { $tzil->release };
  } catch {
    my $err = $_;
    like(
      $err,
      qr/No Changes file found|failed to find Changes in the distribution/i,
      "saw missing Changes file warning",
    );
    ok(
      ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
      "FakeRelease did not happen",
    );
  }
}

{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
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

    capture { $tzil->release };
  } catch {
    my $err = $_;
    like(
      $err,
      qr/Changes has no content for 1\.23/i,
      "saw empty Changes warning",
    );
    ok(
      ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
      "FakeRelease did not happen",
    );
  }
}

{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
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

    capture { $tzil->release };
  } catch {
    my $err = $_;
    like(
      $err,
      qr/Changes has no content for 1\.23/i,
      "saw empty Changes warning",
    );
    ok(
      ! grep({ /fake release happen/i } @{ $tzil->log_messages }),
      "FakeRelease did not happen",
    );
  }
}


{
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
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

    capture { $tzil->release };
  } catch {
    fail ("Caught an error") and diag $_;
  };

  ok(
    grep({ /Changes OK/i } @{ $tzil->log_messages }),
    "Saw Changes OK message",
  );
  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease happened",
  );
}

foreach my $version ( '1.23', '1.23-TRIAL' ){
  my $tzil;
  try {
    $tzil = Dist::Zilla::Tester->from_config(
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

    capture { $tzil->release };
  } catch {
    fail ("Caught an error") and diag $_;
  };

  ok(
    grep({ /Changes OK/i } @{ $tzil->log_messages }),
    "Saw Changes OK message",
  );
  ok(
    grep({ /fake release happen/i } @{ $tzil->log_messages }),
    "FakeRelease happened",
  );
}

done_testing;
