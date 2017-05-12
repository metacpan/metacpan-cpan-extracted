use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

my $test_document = <<'EOF';
use strict;
use warnings;

package DZ2;

# ABSTRACT: this is a sample package for testing Dist::Zilla;

sub main {
  return 1;
}

1;

__END__

=head1 NAME

DZ2

=cut
EOF

{
  my $tzil = Builder->from_config(
    { dist_root => 'invalid' },
    {
      add_files => {
        path('source/lib/DZ2.pm') => $test_document,
        path('source/dist.ini')   => simple_ini(
          'GatherDir',    #
          [
            'MetaProvides::Package' => {
              inherit_version => 0,           #
              inherit_missing => 1,           #
              finder          => 'MiSsInG',
            }
          ]

        ),
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);

  my $plugin;

  is(
    exception {
      $plugin = $tzil->plugin_named('MetaProvides::Package');
    },
    undef,
    'Found MetaProvides::Package'
  );
  my $ex;
  isnt(
    $ex = exception {
      $plugin->metadata
    },
    undef,
    'Missing finders die'
  );
}
{
  my $tzil = Builder->from_config(
    { dist_root => 'invalid' },
    {
      add_files => {
        path('source/lib/DZ2.pm') => $test_document,
        path('source/dist.ini')   => simple_ini(
          'GatherDir',    #
          [
            'MetaProvides::Package' => {
              inherit_version => 0,             #
              inherit_missing => 1,             #
              finder          => 'GatherDir',
            }
          ]

        ),
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);

  my $plugin;

  is(
    exception {
      $plugin = $tzil->plugin_named('MetaProvides::Package');
    },
    undef,
    'Found MetaProvides::Package'
  );
  my $ex;
  isnt(
    $ex = exception {
      $plugin->metadata
    },
    undef,
    'Non-finders passed as finders die'
  );
}
{
  {
    package Dist::Zilla::Plugin::FakeFileFinder::File;
    use Moose;

    sub name {
      return "bad";
    }

    package Dist::Zilla::Plugin::FakeFileFinder;
    use Moose;
    with 'Dist::Zilla::Role::FileFinder';

    sub find_files {
      return [ bless {}, __PACKAGE__ . "::File" ];
    }
  }
  my $tzil = Builder->from_config(
    { dist_root => 'invalid' },
    {
      add_files => {
        path('source/lib/DZ2.pm') => $test_document,
        path('source/dist.ini')   => simple_ini(
          'GatherDir',    #
          'FakeFileFinder',
          [
            'MetaProvides::Package' => {
              inherit_version => 0,                  #
              inherit_missing => 1,                  #
              finder          => 'FakeFileFinder',
            }
          ],
        ),
      },
    },
  );

  $tzil->chrome->logger->set_debug(1);

  my $plugin;

  is(
    exception {
      $plugin = $tzil->plugin_named('MetaProvides::Package');
    },
    undef,
    'Found MetaProvides::Package'
  );
  my $ex;
  isnt(
    $ex = exception {
      $plugin->metadata
    },
    undef,
    'finders returning non-files die'
  );
}

done_testing;
