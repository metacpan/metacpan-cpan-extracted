use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::pushd qw(pushd);
use Path::Tiny qw();
use Test::More   tests => 5;

use lib 't';
use Util qw(clean_environment init_repo);

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => Path::Tiny::path('corpus/commit-build-custom')->absolute,
});

# build fake repository
{
  my $dir = pushd(Path::Tiny::path($zilla->tempdir)->child('source'));

  my $git = init_repo( qw{ .  dist.ini Changes } );
  $git->branch(-m => 'dev');

  $zilla->build;
  ok( eval { $git->rev_parse('-q', '--verify', 'refs/heads/build-dev') }, 'source repo has the "build-dev" branch') or diag explain $@, $git->branch;
  is( scalar $git->log('build-dev'), 1, 'one commit on the build-dev branch')
      or diag $git->branch;

  $zilla->release;
  ok( eval { $git->rev_parse('-q', '--verify', 'refs/heads/release') }, 'source repo has the "release" branch') or diag explain $@, $git->branch;
  my @logs = $git->log('release');
  is( scalar(@logs), 1, 'one commit on the release branch') or diag $git->branch;
  like( $logs[0]->message, qr/^Release of 1\.23\b/, 'correct release commit log message generated');
}
