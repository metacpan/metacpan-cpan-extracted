use strict;
use warnings;
use Test::More;
use Test::DZil;
use Path::Tiny qw( path );
use YAML;

my @packages = ('libzmq-dev');
{
  my $tzil = create_tzil( { apt_package => \@packages, } );
  $tzil->build();

  my $travis_yml = YAML::Load( path( $tzil->tempdir, 'source', '.travis.yml' )->slurp_raw );
  is_deeply( $travis_yml->{addons}, { apt_packages => \@packages }, 'addons.apt_packages configured with package' );
}
push @packages, 'libzmq1';
{
  my $tzil = create_tzil( { apt_package => \@packages, } );
  $tzil->build();

  my $travis_yml = YAML::Load( path( $tzil->tempdir, 'source', '.travis.yml' )->slurp_raw );
  is_deeply( $travis_yml->{addons}, { apt_packages => \@packages }, 'addons.apt_packages configured with both packages' );
}

sub create_tzil {
  my ($travis_ci_config) = @_;
  return Builder->from_config( { dist_root => 't/corpus' },
    { add_files => { path( 'source', 'dist.ini' ) => simple_ini( [ TravisCI => $travis_ci_config ] ) } } );
}

done_testing;
