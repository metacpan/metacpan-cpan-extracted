use strict;
use warnings;

use Test::More;
use Dist::Zilla::Plugin::DBIO::CodebergMeta;
use Dist::Zilla::Tester;
use File::Temp ();
use Path::Tiny;
use IPC::Cmd qw(can_run);

# Pins how DBIO::CodebergMeta turns a git remote URL into repository metadata.
# _parse_remote_url and _build_resources are pure (no zilla/git), so they are
# exercised here as class methods. The URL parser is generic; the codeberg.org
# restriction lives in _slug/metadata, which skip (add nothing) when the remote
# points elsewhere.

my $C = 'Dist::Zilla::Plugin::DBIO::CodebergMeta';

# --- URL parsing: all the remote forms map to the same host/slug ---
my @urls = (
  'git@codeberg.org:getty/DBIO.git',
  'https://codeberg.org/getty/DBIO.git',
  'https://codeberg.org/getty/DBIO',
  'ssh://git@codeberg.org/getty/DBIO.git',
  'git@codeberg.org:getty/DBIO',
);
for my $url (@urls) {
  is_deeply $C->_parse_remote_url($url),
    { host => 'codeberg.org', slug => 'getty/DBIO' },
    "parsed: $url";
}

# parser reports whatever host it sees; a non-codeberg host is later skipped
is_deeply $C->_parse_remote_url('git@github.com:p5-dbio/dbio-dzil.git'),
  { host => 'github.com', slug => 'p5-dbio/dbio-dzil' },
  'non-codeberg remote still parses (host enforcement happens in _slug)';

is $C->_parse_remote_url('not a url'), undef, 'garbage remote -> undef';

# --- resource assembly ---
my %base = (host => 'codeberg.org', slug => 'getty/DBIO', dist_name => 'DBIO');

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'repo');
  is $res->{repository}{web},  'https://codeberg.org/getty/DBIO',        'repository.web';
  is $res->{repository}{url},  'https://codeberg.org/getty/DBIO.git',    'repository.url';
  is $res->{repository}{type}, 'git',                                    'repository.type';
  is $res->{bugtracker}{web},  'https://codeberg.org/getty/DBIO/issues', 'bugtracker.web';
  is $res->{homepage},         'https://codeberg.org/getty/DBIO',        'homepage = repo';
}

{
  my $res = $C->_build_resources(%base, issues => 0, homepage => 'repo');
  ok ! exists $res->{bugtracker}, 'issues = 0 -> no bugtracker';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'metacpan');
  is $res->{homepage}, 'https://metacpan.org/release/DBIO', 'homepage = metacpan';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'none');
  ok ! exists $res->{homepage}, 'homepage = none -> no homepage';
}

# --- the plugin in a dist: git is asked at the dist root, a skip is logged ---
SKIP: {
  skip 'git binary not available', 11 unless can_run('git');

  # A dist in a git repository whose origin is $remote, built through the
  # Dist::Zilla tester; returns the tzil and the plugin.
  my $dist = sub {
    my ($remote) = @_;
    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    my $root = path($tempdir, 'dist');
    $root->child('lib', 'DBIO')->mkpath;
    $root->child('dist.ini')->spew(join "\n",
      'name = DBIO-Test', 'author = Test <test@test.de>', 'license = Perl_5',
      'copyright_holder = Test', 'version = 0.001', '', '[DBIO::CodebergMeta]', '');
    $root->child('lib', 'DBIO', 'Test.pm')->spew(
      "package DBIO::Test;\n# ABSTRACT: t\nour \$VERSION = '0.001';\n1;\n");
    for my $args (
      [qw(init -q)],
      [qw(remote add origin), $remote],
    ) {
      system('git', '-C', "$root", @$args) == 0 or die "git @$args failed: $?";
    }
    my $tzil = Dist::Zilla::Tester->from_config(
      { dist_root => "$root" },
      { tempdir_root => $tempdir },
    );
    my ($plugin) = grep { ref $_ eq $C } @{ $tzil->plugins };
    return ($tzil, $plugin);
  };

  {
    my ($tzil, $plugin) = $dist->('git@codeberg.org:getty/DBIO.git');
    # The working directory is not the dist: only -C on the dist root finds the remote.
    my $elsewhere = Path::Tiny->tempdir;
    my $res = do {
      require Cwd;
      my $cwd = Cwd::getcwd();
      chdir "$elsewhere" or die "chdir: $!";
      my $r = $plugin->metadata;
      chdir $cwd;
      $r;
    };
    is $res->{resources}{repository}{web}, 'https://codeberg.org/getty/DBIO',
      'remote read from the dist root, wherever the process runs';
    ok !( grep { /skipping/ } @{ $tzil->log_messages } ), 'no skip message when resources are found';
  }

  {
    my ($tzil, $plugin) = $dist->('git@github.com:p5-dbio/dbio-dzil.git');
    is_deeply $plugin->metadata, {}, 'remote on another host: no resources';
    my @skip = grep { /skipping/ } @{ $tzil->log_messages };
    is scalar(@skip), 1, 'the skip is logged where a user sees it';
    like $skip[0], qr/github\.com/, 'the skip names the remote host found';
    like $skip[0], qr/codeberg\.org/, 'the skip names the host expected';
  }

  {
    my ($tzil, $plugin) = $dist->('codeberg:getty/DBIO.git');
    is_deeply $plugin->metadata, {}, 'remote alias that is no URL: no resources';
    my @skip = grep { /skipping/ } @{ $tzil->log_messages };
    is scalar(@skip), 1, 'the skip is logged';
    like $skip[0], qr/codeberg:getty\/DBIO\.git/, 'the skip names the remote URL it could not use';
  }

  {
    my ($tzil, $plugin) = $dist->('https://user:secret@github.com/p5-dbio/dbio-dzil.git');
    $plugin->metadata;
    my ($skip) = grep { /skipping/ } @{ $tzil->log_messages };
    unlike $skip, qr/secret/, 'credentials in the remote URL stay out of the log';
  }
}

done_testing;
