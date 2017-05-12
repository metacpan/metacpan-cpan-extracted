use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;
use Test::Deep;

use if !$ENV{AUTHOR_TESTING}, 'Test::RequiresInternet' => ('cpanmetadb.plackperl.org' => 80);

my $dist_version = '0.005';

{
  package SimpleProvides;
  use Moose;
  with 'Dist::Zilla::Role::MetaProvider';
  sub metadata {
    return +{
      provides => {
        'Foo::Bar' => {
          file => 'lib/Foo/Bar.pm',
          version => $dist_version,
        },
        'Foo::Bar::Baz' => {
          file => 'lib/Foo/Bar/Baz.pm',
          version => $dist_version,
        },
      },
    };
  }
}

foreach my $dep_pkg (qw(Foo::Bar Foo::Bar::Baz)) {

  foreach my $prereqs (
    [ runtime => $dist_version ],         # release not ok
    [ develop => $dist_version + 0.001 ], # release not ok
    [ develop => $dist_version ],         # release ok
    [ develop => $dist_version - 0.001 ], # release ok
  )
  {
    my ($phase, $dep_version) = @$prereqs;
    note ''; note "$phase prereq: $dep_pkg => $dep_version";

    my $tzil = Builder->from_config(
      { dist_root => 'does-not-exist' },
      {
        add_files => {
          'source/dist.ini' => simple_ini(
            { # merge into root section
              name => 'Foo-Bar',
              version => $dist_version,
            },
            [ GatherDir => ],
            [ Prereqs => { 'strict' => 0 } ],
            [ Prereqs => ucfirst($phase) . 'Requires' => { $dep_pkg => $dep_version } ],
            [ CheckPrereqsIndexed => ],
            $dep_pkg eq 'Foo::Bar' ? () : [ '=SimpleProvides' ],
            [ FakeRelease => ],
          ),
          'source/lib/Foo/Bar.pm' => "package Foo::Bar;\n1;\n",
          'source/lib/Foo/Bar Baz.pm' => "package Foo::Bar::Baz;\n1;\n",
        },
      },
    );

    $tzil->chrome->logger->set_debug(1);

    if ($phase eq 'develop' and $dep_version <= $dist_version) {
      is(
        exception { $tzil->release },
        undef,
        'build proceeds normally',
      );

      cmp_deeply(
        $tzil->log_messages,
        superbagof(
          "[CheckPrereqsIndexed] skipping develop prereq on ourself ($dep_pkg => $dep_version)",
        ),
        'skipped self dependency',
      );
    }
    else {
      like(
        exception { $tzil->release },
        qr/aborting release due to apparently unindexed prereqs/,
        'release was aborted',
      );

      cmp_deeply(
        $tzil->log_messages,
        superbagof(
        "[CheckPrereqsIndexed] the following prereqs could not be found on CPAN: $dep_pkg",
        ),
        "found $phase dependency on self that will not be satisfied by the current release",
      );
    }

    diag 'got log messages: ', explain $tzil->log_messages
      if not Test::Builder->new->is_passing;
  }
}

done_testing;
