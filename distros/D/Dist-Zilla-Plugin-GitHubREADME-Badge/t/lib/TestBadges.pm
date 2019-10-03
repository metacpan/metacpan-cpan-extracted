use strict;
use warnings;

package # no_index
  TestBadges;

use Test::More;
use Test::DZil;
use Path::Tiny qw( path tempdir );

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (@Test::More::EXPORT, qw(
  badge_patterns
  build_dist
  skip_without_encoding
));

sub badge_patterns {
  my ($user, $repo) = @_;
  my $ur = qr{\Q$user/$repo\E};
  return {
    travis       => qr{//travis-ci.org/$ur\.},
    appveyor     => qr{//ci\.appveyor\.com/api/projects/status/github/$ur\.},
    coveralls    => qr{//coveralls.io/repos/$ur/badge\.},
    gitter       => qr{//gitter\.im/$ur\b},
    cpants       => qr{//cpants.cpanauthors.org/dist/\Q$repo\E\.},
    issues       => qr{//img.shields.io/github/issues/$ur\.},
    github_tag   => qr{//img.shields.io/github/tag/$ur\.},
    license      => qr{//img.shields.io/cpan/l/$repo\.},
    version      => qr{//img.shields.io/cpan/v/$repo\.},
    gitlab_ci    => qr{//github.com/$ur/badges/master/build.svg},
    gitlab_cover => qr{//github.com/$ur/badges/master/coverage.svg},
    docker_automated=> qr{//img.shields.io/docker/automated/\L$ur\E\.},
    docker_build    => qr{//img.shields.io/docker/build/\L$ur\E\.},
    'github_actions/test' => qr{//github.com/$ur/workflows/test/badge.svg},
  };
}

sub skip_without_encoding {
  plan skip_all => 'Dist::Zilla 5 required for Encoding tests'
    if Dist::Zilla->VERSION < 5;
}

sub build_dist {
  my $config = shift || {};
  my $test   = {
    content => 'ReadMe, please',
    name    => 'README.mkdn',
    user    => 'Test-Author',
    repo    => 'Test-Badges',
    %{ shift() || {} },
  };

  my $plugin_name = 'GitHubREADME::Badge';
  my $dir = tempdir();

  my @plugins = (
    # Bare minimum instead of @Basic.
    qw(
      GatherDir
      License
      FakeRelease
    ),
    # Fill in resources so we can discover repo info.
    [
      MetaResources => {
        'repository.url' => "http://github.com/$test->{user}/$test->{repo}",
      }
    ],
    @{ $test->{plugins} || [] },
    [$plugin_name => $config],
  );

  # Use spew_raw instead of add_files so we can use non-utf-8 bytes.
  $dir->child($test->{name})->spew_raw($test->{content} . "\n");

  my $tzil = Builder->from_config(
    {
      dist_root => $dir,
    },
    {
      add_files => {
        'source/dist.ini' => simple_ini({ name => $test->{repo} }, @plugins),
        'source/lib/Foo.pm' => "package Foo;\n\$VERSION = 1;\n",
      }
    }
  );

  $tzil->build;

  # Get the readme in dzil's source dir.
  my ($readme) = map { path($_) }
    grep { $_->basename eq $test->{name} }
      $tzil->root->children;

  # Return several values and shortcuts to simplify testing.
  return {
    zilla  => $tzil,
    readme => $readme,
    plugin => $tzil->plugin_named($plugin_name),
    user   => $test->{user},
    repo   => $test->{repo},
  };
}

1;
