use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;

# Pins DBIO::RequireCoreVersion: a driver is released only when its runtime
# prereq on DBIO asks for at least the version of the dist being released.
# The pin is kept by hand in the cpanfile; this check stops a release whose pin
# is missing or lags behind. It changes no prereq.

my $class = 'Dist::Zilla::Plugin::DBIO::RequireCoreVersion';
use_ok $class or BAIL_OUT("$class does not load");

# A dist at version 0.900005 whose cpanfile is $cpanfile, with only the
# prereq source and this plugin: the check is exercised on its own.
sub plugin_for {
  my ($cpanfile) = @_;
  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
    { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => {
        'source/dist.ini' => join("\n",
          'name = DBIO-Test',
          'author = Test <test@example.com>',
          'license = Perl_5',
          'copyright_holder = DBIO Contributors',
          'version = 0.900005',
          '',
          '[GatherDir]',
          '[Prereqs::FromCPANfile]',
          '[DBIO::RequireCoreVersion]',
          '',
        ),
        'source/lib/DBIO/Test.pm' =>
          "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.900005';\n1;\n",
        'source/cpanfile' => $cpanfile,
      } },
  );
  # A release checks a built dist: the prereq sources have registered by then.
  $tzil->build;
  my ($plugin) = grep { ref $_ eq $class } @{ $tzil->plugins };
  return ($plugin, $tzil);
}

# --- pin equal to the dist version: the release may go on ---
{
  my ($plugin) = plugin_for("requires 'perl', '5.020';\nrequires 'DBIO', '0.900005';\n");
  ok $plugin, 'plugin present';
  ok eval { $plugin->before_release('x.tar.gz'); 1 }, 'pin equal to the dist version passes'
    or diag $@;
}

# --- pin above the dist version passes too ---
{
  my ($plugin) = plugin_for("requires 'DBIO', '0.900006';\n");
  ok eval { $plugin->before_release('x.tar.gz'); 1 }, 'pin above the dist version passes'
    or diag $@;
}

# --- pin below the dist version: the release stops ---
{
  my ($plugin) = plugin_for("requires 'DBIO', '0.900004';\n");
  ok !eval { $plugin->before_release('x.tar.gz'); 1 }, 'pin below the dist version stops the release';
  like $@, qr/0\.900004/, 'message names the pinned version';
  like $@, qr/0\.900005/, 'message names the dist version';
  like $@, qr/requires 'DBIO', '0\.900005';/, 'message names the cpanfile line to write';
}

# --- no runtime prereq on DBIO (the bundle, DBIO-Deprecated): nothing to check ---
{
  my ($plugin) = plugin_for("requires 'perl', '5.020';\n");
  ok eval { $plugin->before_release('x.tar.gz'); 1 }, 'a dist without a DBIO prereq releases'
    or diag $@;
}

# --- an unversioned pin lags behind, too ---
{
  my ($plugin) = plugin_for("requires 'DBIO';\n");
  ok !eval { $plugin->before_release('x.tar.gz'); 1 }, 'prereq without a version stops the release';
}

# --- the plugin changes no prereq ---
{
  my ($plugin, $tzil) = plugin_for("requires 'DBIO', '0.900004';\n");
  eval { $plugin->before_release('x.tar.gz') };
  is $tzil->prereqs->requirements_for('runtime', 'requires')->as_string_hash->{DBIO},
    '0.900004', 'the DBIO prereq is left as the cpanfile has it';
}

done_testing;
