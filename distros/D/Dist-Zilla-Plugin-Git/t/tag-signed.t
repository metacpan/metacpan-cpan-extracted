use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use File::Copy qw{ cp };
use File::Path 2.07 qw{ make_path }; # 2.07 required for make_path
use File::pushd qw(pushd);
use Path::Tiny 0.012 qw(path); # cwd
use File::Which qw{ which };
use Test::More;

use lib 't';
use Util qw(clean_environment init_repo);

which('gpg')
    ? plan tests => 8
    : plan skip_all => q{gpg couldn't be located in $PATH; required for GPG-signed tags};

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

cp 'corpus/dzp-git.pub', "$homedir/pubring.gpg";
cp 'corpus/dzp-git.sec', "$homedir/secring.gpg";

# build fake repository
my $zilla = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/tag-signed')->absolute,
});

{
  my $dir = pushd(path($zilla->tempdir)->child('source'));
  my $git = init_repo('.');

  $git->config( 'user.signingkey' => '7D85ED44');
  $git->add( qw{ dist.ini Changes } );
  $git->commit( { message => 'initial commit' } );

  # do the release
  $zilla->release;

  # check if tag has been correctly created
  my @tags = $git->tag;
  is( scalar(@tags), 1, 'one tag created' );
  is( $tags[0], 'v1.23', 'new tag created after new version' );
  is( $tags[0], $zilla->plugin_named('Git::Tag')->tag(), 'new tag matches the tag the plugin claims is the tag.');

  # Check that it is a signed tag
  my $tag = join "\n", $git->show({pretty => 'short'}, 'v1.23');
  $tag = substr($tag, 0, index($tag, "\ncommit "));
  like( $tag, qr/^tag v1.23/m, 'Is it a real tag?' );
  like( $tag, qr/^Tagger: dzp-git test <dzp-git\@test>/m, 'Is it a real tag?' );
  like( $tag, qr/PGP SIGNATURE/m, 'Is it GPG-signed?' );
  like( $tag, qr/^v1.23:\n\n - foo\n - bar\n - baz\n/m,
        'Includes commit message?');

  # attempting to release again should fail
  eval { $zilla->release };

  like($@, qr/tag v1\.23 already exists/, 'prohibit duplicate tag');
}
