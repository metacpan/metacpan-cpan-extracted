use strict;
use warnings;

package # no_index
  TestInfo;

use Test::More;
use Test::DZil;
use Path::Tiny qw( path tempdir );

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = (@Test::More::EXPORT, qw(
  build_dist
  skip_without_encoding
));

sub skip_without_encoding {
  plan skip_all => 'Dist::Zilla 5 required for Encoding tests'
    if Dist::Zilla->VERSION < 5;
}

sub build_dist {
  my $config = shift || {};
  my $test   = {
    content => "ReadMe, please\n\n# AUTHOR\n\nRenee Baecker",
    name    => 'README.mkdn',
    user    => 'Test-Author',
    repo    => 'Test-DevInfo',
    %{ shift() || {} },
  };

  my $plugin_name = 'ReadmeAddDevInfo';
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
  $dir->child('CONTRIBUTING.md')->spew_raw("\n");

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

  # Get the contributing file in dzil's source dir.
  my ($contribution_file) = map { path($_) }
    grep { $_->basename eq 'CONTRIBUTING.md' }
      $tzil->root->children;

  # Return several values and shortcuts to simplify testing.
  return {
    zilla             => $tzil,
    readme            => $readme,
    contribution_file => $contribution_file,
    plugin            => $tzil->plugin_named($plugin_name),
    user              => $test->{user},
    repo              => $test->{repo},
  };
}

1;

