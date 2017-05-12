use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::pushd qw(pushd);
use Path::Tiny 0.012 qw( path ); # cwd
use Test::More   tests => 8;

use lib 't';
use Util qw(clean_environment init_repo);

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/tag')->absolute,
});

{
  my $dir = pushd(path($zilla->tempdir)->child('source'));
  my $git = init_repo(qw{ .  dist.ini Changes } );

  # do the release
  $zilla->release;

  # check if tag has been correctly created
  my @tags = $git->tag;
  is( scalar(@tags), 1, 'one tag created' );
  is( $tags[0], 'v1.23', 'new tag created after new version' );
  is( $tags[0], $zilla->plugin_named('Git::Tag')->tag(), 'new tag matches the tag the plugin claims is the tag.');

  # Check that it is not a signed tag
  my $tag = join "\n", $git->show({pretty => 'short'}, 'v1.23');
  $tag = substr($tag, 0, index($tag, "\ncommit "));
  like( $tag, qr/^tag v1.23/m, 'Is it a real tag?' );
  like( $tag, qr/^Tagger: dzp-git test <dzp-git\@test>/m, 'Is it a real tag?' );
  unlike( $tag, qr/PGP SIGNATURE/m, 'Is it not GPG-signed?' );
  like( $tag, qr/^v1.23:\n\n - foo\n - bar\n - baz\n\z/m,
        'Includes commit message?');

  # attempting to release again should fail
  eval { $zilla->release };

  like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');
}
